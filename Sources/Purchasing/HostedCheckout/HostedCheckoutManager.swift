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
    ///
    /// - Parameter previousSession: A session given before that has not been settled, even if it was created for
    /// someone other than whoever is logged in now. The backend decides whether the customer carries on with it.
    /// `nil` when there is none: no session was given yet, or the last one was settled.
    func startCheckout(package: Package,
                       paywall: PaywallEvent.Data?,
                       previousSession: HostedCheckoutSession?) async -> HostedCheckoutStartResult {
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
                                        externalPurchaseTokenID: externalPurchaseTokenID,
                                        previousSession: previousSession)
    }

    /// Waits for a checkout session to reach an outcome the caller can settle on.
    ///
    /// The checkout page returning to its success URL does not mean the purchase has landed yet, so the
    /// backend is asked until it says one way or the other.
    ///
    /// - Parameter appUserID: The customer the session was created for. Whoever is logged in by now may not
    /// own the session.
    func pollCheckout(operationSessionID: String, appUserID: String) async -> HostedCheckoutPollResult {
        return await self.poller.poll(operationSessionID: operationSessionID, appUserID: appUserID)
    }

}

/// What the caller should do once ``HostedCheckoutManager`` has been asked to start a checkout.
@_spi(Internal) public enum HostedCheckoutStartResult {

    /// Present this checkout to the customer.
    case started(HostedCheckoutSession)

    /// Present this checkout to the customer, who can carry on where they left off with it.
    case resumed(HostedCheckoutSession)

    /// This checkout has already been paid for, so there is nothing to present. Confirm it the same way as a
    /// checkout that reached its success page.
    case completed(HostedCheckoutSessionID)

    /// The customer declined Apple's disclosure notice.
    case declinedByCustomer

    /// The device does not authorize payments.
    case paymentsNotAuthorized

    /// The customer is not eligible to buy outside the App Store.
    case notEligible

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
                       externalPurchaseTokenID: String?,
                       previousSession: HostedCheckoutSession?) async -> HostedCheckoutStartResult {
        let appUserID = self.currentUserProvider.currentAppUserID

        let result: Result<HostedCheckoutResponse, BackendError> = await Async.call { completion in
            self.webBillingAPI.postHostedCheckout(
                appUserID: appUserID,
                packageID: package.identifier,
                presentedOfferingContext: package.presentedOfferingContext,
                paywall: paywall.map { .init(paywallEventData: $0) },
                externalPurchaseTokenID: externalPurchaseTokenID,
                previousOperationSessionID: previousSession?.id.operationSessionID,
                completion: completion
            )
        }

        switch result {
        case let .success(response):
            return Self.startResult(for: response, appUserID: appUserID)
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

private extension HostedCheckoutManager {

    /// The session returned is the one the customer now has, created for the customer the request was made for.
    static func startResult(for response: HostedCheckoutResponse,
                            appUserID: String) -> HostedCheckoutStartResult {
        let operationSessionID = response.operationSessionID

        switch response.outcome {
        case let .created(page):
            Logger.debug(Strings.hostedCheckout.session_created(operationSessionID))
            return .started(.init(operationSessionID: operationSessionID, page: page, appUserID: appUserID))

        case let .resumed(page):
            Logger.debug(Strings.hostedCheckout.session_resumed(operationSessionID))
            return .resumed(.init(operationSessionID: operationSessionID, page: page, appUserID: appUserID))

        case .succeeded:
            Logger.debug(Strings.hostedCheckout.session_paid(operationSessionID))
            return .completed(.init(operationSessionID: operationSessionID, appUserID: appUserID))
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
        case .notEligible:
            self = .notEligible
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
