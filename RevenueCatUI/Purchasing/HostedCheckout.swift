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

#if os(iOS) && canImport(WebKit)

/// Starts the checkout a purchase button configured for the in-app sheet asks for.
@available(iOS 15.0, *)
enum HostedCheckout {

    /// What the paywall does with the tap that asked for a checkout.
    enum Action: Equatable {

        /// Present this checkout to the customer.
        case present(HostedCheckoutSession)

        /// Tell the customer they already own what they tried to buy, which is why no checkout opens.
        case tellCustomerTheyAlreadyOwnIt

        /// Nothing to present, and nothing to offer instead.
        case nothing

        init(_ result: HostedCheckoutStartResult) {
            switch result {
            case let .started(session):
                self = .present(session)
            case .alreadyPurchased:
                self = .tellCustomerTheyAlreadyOwnIt
            case .declinedByCustomer, .paymentsNotAuthorized, .alreadyStarting, .failed:
                self = .nothing
            }
        }

    }

    /// Runs Apple's flow and creates the checkout session, once the app's purchase interceptor lets it.
    static func start(for package: Package,
                      purchaseHandler: PurchaseHandler,
                      purchaseInitiatedAction: PurchaseInitiatedAction?) async -> Action {
        guard await purchaseHandler.shouldProceed(withPurchaseOf: package,
                                                  interceptor: purchaseInitiatedAction) else {
            return .nothing
        }

        return Action(await purchaseHandler.startHostedCheckout(package: package))
    }

    /// How the customer left a checkout that did not end on its cancel page.
    enum Exit {

        /// The page sent them to the success URL.
        case successPage

        /// They closed the sheet before the page sent them anywhere.
        case closedSheet

    }

    /// How the paywall settles once the backend has said what became of a checkout.
    ///
    /// Only a purchase the backend confirms counts as one, and only a checkout dismissed without paying
    /// counts as a cancellation. Anything else is an error: either the success page told the customer the
    /// purchase went through, or a payment was under way when they closed the sheet.
    enum Settlement: Equatable {

        case purchased
        case tellCustomerTheyAlreadyOwnIt
        case failed(HostedCheckoutError)
        case cancelled

        init(_ result: HostedCheckoutPollResult) {
            switch result {
            case .succeeded:
                self = .purchased
            case .alreadyPurchased:
                self = .tellCustomerTheyAlreadyOwnIt
            case let .failed(code, _):
                self = .failed(.failed(code: code))
            case .undetermined:
                self = .failed(.unconfirmed)
            case .abandoned:
                self = .cancelled
            }
        }

    }

    /// Asks the backend what became of a checkout the customer left without going through its cancel page,
    /// then settles the paywall on the answer.
    ///
    /// A purchase is left for the caller to report with ``PurchaseHandler/handleHostedCheckoutPurchase()``
    /// once the customer has been told about it, since reporting it can close the paywall.
    ///
    /// - Parameter package: The package the checkout was started for, when it is still known.
    @MainActor
    static func settle(_ session: HostedCheckoutSession,
                       after exit: Exit,
                       package: Package?,
                       purchaseHandler: PurchaseHandler) async -> Settlement {
        return await purchaseHandler.whileConfirmingHostedCheckout {
            let operationSessionID = session.operationSessionID
            let result: HostedCheckoutPollResult

            switch exit {
            case .successPage:
                result = await purchaseHandler.pollHostedCheckout(operationSessionID: operationSessionID)
            case .closedSheet:
                result = await purchaseHandler.pollDismissedHostedCheckout(operationSessionID: operationSessionID)
            }

            let settlement = Settlement(result)

            switch settlement {
            case .purchased:
                break
            case let .failed(error):
                purchaseHandler.handleHostedCheckoutFailure(error, package: package)
            case .cancelled:
                await purchaseHandler.handleHostedCheckoutCancellation(package: package)
            case .tellCustomerTheyAlreadyOwnIt:
                // Neither a purchase nor a cancellation, just as when the checkout never opened for this reason:
                // the paywall only tells the customer.
                break
            }

            return settlement
        }
    }

}

/// Why a checkout the customer was told succeeded did not end in a purchase, mapped onto the same public
/// codes `purchases-js` reports for it, except for a failed charge.
///
/// `purchases-js` reports a failed charge as `PaymentPendingError`, but on Apple platforms that code means a
/// purchase awaiting approval, which apps commonly hold off on rather than treat as a failure.
enum HostedCheckoutError: Error, Equatable {

    /// The backend says the session failed. `code` is the backend's own, absent where it gave none.
    case failed(code: Int?)

    /// The backend never said the session had finished.
    case unconfirmed

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

#endif
