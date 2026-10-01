//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckout.swift
//
//  Created by Antonio Pallares on 11/9/26.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS) && canImport(WebKit)

/// Starts the checkout a purchase button configured for the in-app sheet asks for.
@available(iOS 15.0, *)
enum HostedCheckout {

    /// What the paywall does with the tap that asked for a checkout.
    enum Action: Equatable {

        /// Present this checkout to the customer.
        case present(HostedCheckoutSession)

        /// Confirm this checkout, which the customer already paid for, without presenting anything.
        case confirm(HostedCheckoutSession)

        /// Tell the customer they already own what they tried to buy, which is why no checkout opens.
        case tellCustomerTheyAlreadyOwnIt

        /// Tell the customer the purchase is not available to them, which is why no checkout opens.
        case tellCustomerThePurchaseIsUnavailable

        /// Tell the customer the checkout could not be started.
        case failed(HostedCheckoutError)

        /// Nothing to present, and nothing to offer instead.
        case nothing

        init(_ result: HostedCheckoutStartResult) {
            switch result {
            case let .started(session), let .resumed(session):
                self = .present(session)
            case let .completed(session):
                self = .confirm(session)
            case .alreadyPurchased:
                self = .tellCustomerTheyAlreadyOwnIt
            case .notEligible:
                self = .tellCustomerThePurchaseIsUnavailable
            case .failed:
                self = .failed(.notStarted)
            case .declinedByCustomer, .paymentsNotAuthorized, .alreadyStarting:
                self = .nothing
            }
        }

    }

    /// Runs Apple's flow and creates the checkout session, once the app's purchase interceptor lets it.
    ///
    /// The backend is asked to carry on with the checkout the paywall kept, if any, rather than create a second
    /// one the customer could pay for as well.
    @MainActor
    static func start(for package: Package,
                      purchaseHandler: PurchaseHandler,
                      purchaseInitiatedAction: PurchaseInitiatedAction?) async -> Action {
        guard await purchaseHandler.shouldProceed(withPurchaseOf: package,
                                                  interceptor: purchaseInitiatedAction) else {
            return .nothing
        }

        let previousSession = purchaseHandler.keptHostedCheckout?.session
        let action = Action(await purchaseHandler.startHostedCheckout(package: package,
                                                                      previousSession: previousSession))

        if case .confirm = action {
            purchaseHandler.keptHostedCheckout = nil
        } else if case let .failed(error) = action {
            purchaseHandler.handleHostedCheckoutFailure(error, package: package)
        }

        return action
    }

    /// A checkout the customer was given on this paywall, kept until it settles or the paywall goes, so that
    /// tapping buy again carries on with it.
    @MainActor
    final class KeptCheckout {

        let session: HostedCheckoutSession

        /// The package the checkout was started for.
        let package: Package

        let viewModel: WebCheckoutViewModel

        init(session: HostedCheckoutSession, package: Package, viewModel: WebCheckoutViewModel) {
            self.session = session
            self.package = package
            self.viewModel = viewModel
        }

        /// Whether the page is still where the customer left it. One that failed to load, or reached a return URL,
        /// is loaded afresh instead.
        var canBePresentedAgain: Bool {
            switch self.viewModel.loadState {
            case .idle, .loading, .loaded, .navigating:
                return true
            case .failed, .finished:
                return false
            }
        }

    }

    /// Confirms the kept checkout should its page reach the success URL while the sheet is closed, which the
    /// provider does once a payment the customer made moments before closing it goes through.
    ///
    /// A page that returns any other way is left as it is: it is loaded afresh when the customer taps buy again.
    ///
    /// - Parameter onSuccess: Called with the checkout to confirm, once it is no longer kept.
    @MainActor
    static func confirmOnSuccessWhileHidden(_ checkout: KeptCheckout,
                                            purchaseHandler: PurchaseHandler,
                                            onSuccess: @escaping @MainActor (KeptCheckout) -> Void) {
        checkout.viewModel.onFinished = { [weak checkout, weak purchaseHandler] in
            guard let checkout,
                  let purchaseHandler,
                  purchaseHandler.keptHostedCheckout === checkout,
                  checkout.viewModel.returnStatus == .success else {
                return
            }

            purchaseHandler.keptHostedCheckout = nil
            onSuccess(checkout)
        }
    }

    /// The checkout to present for `session`: the kept one where it is the same session and its page is still
    /// usable, or a new one that replaces it.
    ///
    /// - Parameter package: The package the checkout was started for.
    @MainActor
    static func checkoutToPresent(_ session: HostedCheckoutSession,
                                  package: Package,
                                  purchaseHandler: PurchaseHandler) -> KeptCheckout {
        if let kept = purchaseHandler.keptHostedCheckout, kept.session == session, kept.canBePresentedAgain {
            return kept
        }

        let checkout = KeptCheckout(
            session: session,
            package: package,
            viewModel: WebCheckoutViewModel(
                checkoutURL: session.checkoutURL,
                successURL: session.successURL,
                dataStoreIdentifierStore: .init()
            )
        )
        purchaseHandler.keptHostedCheckout = checkout

        return checkout
    }

    /// How the paywall settles on the outcome the backend gives for a checkout that ended on its success page.
    ///
    /// Only a purchase the backend confirms counts as one. Anything else is an error, since the success page
    /// always tells the customer the purchase went through.
    enum Resolution: Equatable {

        case purchased(CustomerInfo)
        case tellCustomerTheyAlreadyOwnIt
        case failed(HostedCheckoutError)

        /// - Parameter customerInfo: The `CustomerInfo` showing the purchase, when the backend confirmed one and
        /// it could be fetched. Without it, the purchase cannot be reported, so as far as the app can tell it is
        /// still processing.
        init(_ result: HostedCheckoutPollResult, customerInfo: CustomerInfo?) {
            switch result {
            case .succeeded:
                self = customerInfo.map(Self.purchased) ?? .failed(.unconfirmed)
            case .alreadyPurchased:
                self = .tellCustomerTheyAlreadyOwnIt
            case let .failed(code, _):
                self = .failed(.failed(code: code))
            case .undetermined:
                self = .failed(.unconfirmed)
            }
        }

    }

    /// Asks the backend for the final outcome of a checkout that ended on its success page, then settles the
    /// paywall on it.
    ///
    /// A purchase the backend confirms but the paywall cannot report, for lack of the `CustomerInfo` showing it,
    /// settles as unconfirmed: as far as the app can tell, it is still processing.
    ///
    /// A purchase is left for the caller to report with
    /// ``PurchaseHandler/handleHostedCheckoutPurchase(customerInfo:)`` once the customer has been told about it,
    /// since reporting it can close the paywall.
    ///
    /// - Parameter package: The package the checkout was started for, when it is still known.
    @MainActor
    static func resolve(_ session: HostedCheckoutSession,
                        package: Package?,
                        purchaseHandler: PurchaseHandler) async -> Resolution {
        return await purchaseHandler.whileConfirmingHostedCheckout {
            let result = await purchaseHandler.pollHostedCheckout(session: session)
            let customerInfo = result == .succeeded ? await purchaseHandler.hostedCheckoutPurchaseCustomerInfo() : nil
            let resolution = Resolution(result, customerInfo: customerInfo)

            switch resolution {
            case .purchased:
                break
            case let .failed(error):
                purchaseHandler.handleHostedCheckoutFailure(error, package: package)
            case .tellCustomerTheyAlreadyOwnIt:
                // Neither a purchase nor a cancellation, just as when the checkout never opened for this reason:
                // the paywall only tells the customer.
                break
            }

            return resolution
        }
    }

}

/// Why a hosted checkout did not end in a purchase the paywall could report, mapped onto the same public codes
/// `purchases-js` reports for it, except for a failed charge.
///
/// `purchases-js` reports a failed charge as `PaymentPendingError`, but on Apple platforms that code means a
/// purchase awaiting approval, which apps commonly hold off on rather than treat as a failure.
enum HostedCheckoutError: Error, Equatable {

    /// The backend says the session failed. `code` is the backend's own, absent where it gave none.
    case failed(code: Int?)

    /// The backend never said the session had finished, or said the purchase went through but the `CustomerInfo`
    /// showing it could not be fetched.
    case unconfirmed

    /// The checkout could not be started, so the customer never reached the page.
    case notStarted

}

extension HostedCheckoutError: CustomNSError {

    static var errorDomain: String {
        return ErrorCode.errorDomain
    }

    var errorCode: Int {
        return self.publicCode.rawValue
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.errorDescription]
    }

    private var publicCode: ErrorCode {
        switch self {
        case .failed(code: Self.paymentChargeFailedCode):
            return .purchaseNotAllowedError
        case let .failed(code?) where Self.setupFailedCodes.contains(code):
            return .storeProblemError
        case .notStarted:
            return .storeProblemError
        case .failed, .unconfirmed:
            return .unknownError
        }
    }

    private var errorDescription: String {
        switch self {
        case .failed(code: Self.paymentChargeFailedCode):
            return "The payment failed."
        case let .failed(code?) where Self.setupFailedCodes.contains(code):
            return "The purchase could not be set up."
        case .notStarted:
            return "The purchase could not be set up."
        case .failed:
            return "The purchase failed."
        case .unconfirmed:
            return "The purchase could not be confirmed."
        }
    }

    /// Creating the setup intent, creating the payment method, and completing the setup intent.
    private static let setupFailedCodes: Set<Int> = [1, 2, 4]
    private static let paymentChargeFailedCode = 3

}

extension HostedCheckoutError {

    /// What the paywall tells the customer. A purchase the paywall could not confirm may still land, or have landed
    /// already, so it is not called a failure.
    func message(bundle: Bundle) -> Text {
        switch self {
        case .failed(code: Self.paymentChargeFailedCode):
            return Text("Payment failed.", bundle: bundle)
        case .failed, .notStarted:
            return Text("Something went wrong", bundle: bundle)
        case .unconfirmed:
            return Text("Your purchase is still processing.", bundle: bundle)
        }
    }

}

#endif
