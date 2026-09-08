//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutManager.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation

/// Starts a checkout the customer completes without leaving the app: it runs what StoreKit requires around an
/// external purchase and exchanges the result for a checkout session with the payment provider.
final class HostedCheckoutManager {

    private let externalPurchaseManager: ExternalPurchaseManager
    private let webBillingAPI: WebBillingAPI
    private let currentUserProvider: CurrentUserProvider

    init(externalPurchaseManager: ExternalPurchaseManager,
         webBillingAPI: WebBillingAPI,
         currentUserProvider: CurrentUserProvider) {
        self.externalPurchaseManager = externalPurchaseManager
        self.webBillingAPI = webBillingAPI
        self.currentUserProvider = currentUserProvider
    }

    /// Starts a checkout for `package`, in response to the customer deliberately asking to buy.
    ///
    /// Must not be called before then: this mints an external purchase token, and every token minted is one
    /// Apple expects a report for.
    ///
    /// - Parameter paywall: The paywall the customer is buying from, where they are buying from one.
    func startCheckout(package: Package,
                       paywall: PaywallEvent.Data?) async -> HostedCheckoutStartResult {
        Logger.debug(Strings.hostedCheckout.starting_checkout(package.identifier))

        let externalPurchaseTokenID: String

        switch await self.externalPurchaseManager.prepareExternalPurchase(flow: .inApp) {
        case let .registered(tokenID):
            externalPurchaseTokenID = tokenID
        case .unregistered:
            // A checkout with no token behind it is a purchase Apple is never told about, so this fails
            // rather than letting an unattributed one through.
            Logger.error(Strings.hostedCheckout.no_registered_token)
            return .failed
        case let .stopped(reason):
            return .init(stopReason: reason)
        }

        return await self.createSession(package: package,
                                        paywall: paywall,
                                        externalPurchaseTokenID: externalPurchaseTokenID)
    }

}

/// What the caller should do once ``HostedCheckoutManager`` has been asked to start a checkout.
@_spi(Internal) public enum HostedCheckoutStartResult {

    /// Present this checkout to the customer.
    case started(HostedCheckoutSession)

    /// The customer declined Apple's disclosure notice. There is nothing to present, and nothing went wrong.
    case declinedByCustomer

    /// This customer cannot pay outside the App Store, so the caller has to offer them something else.
    /// Unlike the other outcomes, this one does not change while the customer stays where they are.
    case externalPurchaseUnavailable

    /// The checkout could not be started. Why is logged where it happened, and a retry may well work.
    case failed

}

extension HostedCheckoutStartResult: Equatable, Sendable {}

// MARK: - Private

private extension HostedCheckoutManager {

    func createSession(package: Package,
                       paywall: PaywallEvent.Data?,
                       externalPurchaseTokenID: String) async -> HostedCheckoutStartResult {
        let result: Result<HostedCheckoutResponse, BackendError> = await Async.call { completion in
            self.webBillingAPI.postHostedCheckout(
                appUserID: self.currentUserProvider.currentAppUserID,
                packageID: package.identifier,
                presentedOfferingContext: package.presentedOfferingContext,
                paywall: paywall.flatMap { .init(paywallEventData: $0) },
                externalPurchaseTokenID: externalPurchaseTokenID,
                completion: completion
            )
        }

        switch result {
        case let .success(response):
            Logger.debug(Strings.hostedCheckout.session_created(response.operationSessionID))
            return .started(.init(response: response))
        case let .failure(error):
            Logger.error(Strings.hostedCheckout.error_creating_session(error))
            return .failed
        }
    }

}

private extension HostedCheckoutStartResult {

    init(stopReason: ExternalPurchasePreparationResult.StopReason) {
        switch stopReason {
        case .cannotMakeExternalPurchases:
            self = .externalPurchaseUnavailable
        case .customerCancelledNotice:
            self = .declinedByCustomer
        case .noticeFailed:
            self = .failed
        }
    }

}

private extension PostHostedCheckoutOperation.Paywall {

    /// `nil` where the paywall has no identifier, which the backend requires to attribute the checkout to it.
    init?(paywallEventData data: PaywallEvent.Data) {
        guard let paywallID = data.paywallIdentifier else {
            return nil
        }

        self.init(paywallID: paywallID,
                  sessionID: data.sessionIdentifier.uuidString,
                  workflowID: data.workflowId,
                  stepID: data.stepId)
    }

}
