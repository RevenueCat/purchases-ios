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
    private let poller: HostedCheckoutPolling

    init(externalPurchaseManager: ExternalPurchaseManager,
         webBillingAPI: WebBillingAPI,
         currentUserProvider: CurrentUserProvider,
         poller: HostedCheckoutPolling) {
        self.externalPurchaseManager = externalPurchaseManager
        self.webBillingAPI = webBillingAPI
        self.currentUserProvider = currentUserProvider
        self.poller = poller
    }

    /// Starts a checkout for `package`, in response to the customer deliberately asking to buy.
    ///
    /// Must not be called before then: this may mint an external purchase token, and every token minted is
    /// one Apple expects a report for.
    func startCheckout(package: Package,
                       paywall: PaywallEvent.Data?) async -> HostedCheckoutStartResult {
        Logger.debug(Strings.hostedCheckout.starting_checkout(package.identifier))

        let externalPurchaseTokenID: String?

        switch await self.externalPurchaseManager.prepareExternalPurchase(flow: .inApp) {
        case let .registered(tokenID):
            externalPurchaseTokenID = tokenID
        case .notApplicable:
            externalPurchaseTokenID = nil
        case .unregistered:
            Logger.error(Strings.hostedCheckout.no_registered_token)
            return .failed
        case let .stopped(reason):
            return .init(stopReason: reason)
        }

        return await self.createSession(package: package,
                                        paywall: paywall,
                                        externalPurchaseTokenID: externalPurchaseTokenID)
    }

    /// Waits for a checkout session to reach an outcome the caller can settle on.
    ///
    /// The checkout page returning to its success URL does not mean the purchase has landed yet, so the
    /// backend is asked until it says one way or the other.
    ///
    /// The customer is read once, here: the session belongs to whoever was current when the poll began, and
    /// following a customer who changes mid-poll would only ask about a session they do not own.
    func pollCheckout(operationSessionID: String) async -> HostedCheckoutPollResult {
        return await self.poller.poll(operationSessionID: operationSessionID,
                                      appUserID: self.currentUserProvider.currentAppUserID)
    }

    /// Settles a checkout the customer dismissed before it sent them anywhere, where nothing says whether
    /// they paid. The customer is read once, as in ``pollCheckout(operationSessionID:)``.
    func pollDismissedCheckout(operationSessionID: String) async -> HostedCheckoutPollResult {
        return await self.poller.pollDismissed(operationSessionID: operationSessionID,
                                               appUserID: self.currentUserProvider.currentAppUserID)
    }

}

/// What the caller should do once ``HostedCheckoutManager`` has been asked to start a checkout.
@_spi(Internal) public enum HostedCheckoutStartResult {

    /// Present this checkout to the customer.
    case started(HostedCheckoutSession)

    /// The customer declined Apple's disclosure notice.
    case declinedByCustomer

    /// The device does not authorize payments.
    case paymentsNotAuthorized

    /// Another checkout was already being started, and that one carries the purchase.
    case alreadyStarting

    /// This customer already owns what they are trying to buy, so there is nothing to check out.
    case alreadyPurchased

    /// The checkout could not be started.
    case failed

}

extension HostedCheckoutStartResult: Equatable, Sendable {}

// MARK: - Private

private extension HostedCheckoutManager {

    func createSession(package: Package,
                       paywall: PaywallEvent.Data?,
                       externalPurchaseTokenID: String?) async -> HostedCheckoutStartResult {
        let result: Result<HostedCheckoutResponse, BackendError> = await Async.call { completion in
            self.webBillingAPI.postHostedCheckout(
                appUserID: self.currentUserProvider.currentAppUserID,
                packageID: package.identifier,
                presentedOfferingContext: package.presentedOfferingContext,
                paywall: paywall.map { .init(paywallEventData: $0) },
                externalPurchaseTokenID: externalPurchaseTokenID,
                completion: completion
            )
        }

        switch result {
        case let .success(response):
            Logger.debug(Strings.hostedCheckout.session_created(response.operationSessionID))
            return .started(.init(response: response))
        case let .failure(error):
            guard !error.isProductAlreadyPurchased else {
                Logger.warn(Strings.hostedCheckout.product_already_purchased(package.identifier))
                return .alreadyPurchased
            }

            Logger.error(Strings.hostedCheckout.error_creating_session(error))
            return .failed
        }
    }

}

private extension BackendError {

    var isProductAlreadyPurchased: Bool {
        guard case let .networkError(.errorResponse(response, _, _)) = self else { return false }

        return response.code == .productAlreadyPurchased
    }

}

private extension HostedCheckoutStartResult {

    init(stopReason: ExternalPurchasePreparationResult.StopReason) {
        switch stopReason {
        case .paymentsNotAuthorized:
            self = .paymentsNotAuthorized
        case .customerCancelledNotice:
            self = .declinedByCustomer
        case .noticeFailed:
            self = .failed
        case .alreadyPreparing:
            self = .alreadyStarting
        }
    }

}

private extension PostHostedCheckoutOperation.Paywall {

    init(paywallEventData data: PaywallEvent.Data) {
        self.init(paywallID: data.paywallIdentifier,
                  sessionID: data.sessionIdentifier.uuidString,
                  workflowID: data.workflowId,
                  stepID: data.stepId)
    }

}
