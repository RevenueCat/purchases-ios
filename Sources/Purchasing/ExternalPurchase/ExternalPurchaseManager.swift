//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseManager.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

/// Runs what StoreKit requires around an external purchase, so callers have a single entry point: it checks that
/// the customer can make one, shows the disclosure notice, requests the token and registers it with the backend.
final class ExternalPurchaseManager {

    private let customLink: ExternalPurchaseCustomLinkType
    private let externalPurchaseTokenAPI: ExternalPurchaseTokenAPI
    private let currentUserProvider: CurrentUserProvider
    private let configProvider: ExternalPurchasesConfigProviderType
    private let systemInfo: SystemInfo

    private let isPreparing: Atomic<Bool> = false

    init(customLink: ExternalPurchaseCustomLinkType,
         externalPurchaseTokenAPI: ExternalPurchaseTokenAPI,
         currentUserProvider: CurrentUserProvider,
         configProvider: ExternalPurchasesConfigProviderType,
         systemInfo: SystemInfo) {
        self.customLink = customLink
        self.externalPurchaseTokenAPI = externalPurchaseTokenAPI
        self.currentUserProvider = currentUserProvider
        self.configProvider = configProvider
        self.systemInfo = systemInfo
    }

    /// Whether the app can offer an external purchase to this customer.
    ///
    /// Safe to call before the customer intends to buy: it mints nothing, so it creates no obligation to report
    /// anything to Apple.
    func externalPurchaseAvailability() async -> ExternalPurchaseAvailability {
        guard self.takesPartInTheProgramme else {
            return .notEligible
        }

        let availability = await self.customLink.externalPurchaseAvailability()
        Logger.debug(Strings.externalPurchase.eligibility_resolved(availability))

        return availability
    }

    /// Prepares an external purchase, in response to the customer deliberately asking for one.
    ///
    /// Must not be called before then: the notice may only be shown in response to a customer interaction, and
    /// every token minted here is one Apple expects a report for, whether or not a transaction follows.
    ///
    /// Only one preparation runs at a time. Asking for another while one is under way stops the new one, so a
    /// customer tapping twice sees a single notice and mints a single token.
    func prepareExternalPurchase(flow: ExternalPurchaseFlow) async -> ExternalPurchasePreparationResult {
        guard self.takesPartInTheProgramme else {
            return .notApplicable
        }

        guard !self.isPreparing.getAndSet(true) else {
            Logger.warn(Strings.externalPurchase.already_preparing)
            return .stopped(.alreadyPreparing)
        }

        defer { self.isPreparing.value = false }

        switch await self.externalPurchaseAvailability() {
        case .available:
            break
        case .notEligible:
            guard await self.isInAStorefrontAllowedWithoutStoreEligibility() else {
                Logger.warn(Strings.externalPurchase.storefront_not_allowed(self.storefront))
                return .stopped(.notAllowedInStorefront)
            }

            Logger.debug(Strings.externalPurchase.custom_link_does_not_apply)
            return .notApplicable
        case .paymentsNotAuthorized:
            Logger.warn(Strings.externalPurchase.payments_not_authorized)
            return .stopped(.paymentsNotAuthorized)
        }

        switch await self.showNotice(type: flow.noticeType) {
        case .continued:
            break
        case .cancelled:
            Logger.debug(Strings.externalPurchase.notice_cancelled)
            return .stopped(.customerCancelledNotice)
        case .failed:
            return .stopped(.noticeFailed)
        }

        return await self.registerToken(of: flow.tokenType)
    }

}

/// What the caller should do once ``ExternalPurchaseManager`` has prepared an external purchase.
internal enum ExternalPurchasePreparationResult: Equatable {

    /// Do not route the customer to the checkout.
    case stopped(StopReason)

    /// Route the customer to the checkout, handing this identifier to the checkout page.
    case registered(tokenID: String)

    /// Route the customer to the checkout with no identifier to hand over.
    ///
    /// Registration did not complete, so the checkout has nothing to tie the purchase back to. That is
    /// deliberately not treated as a failure for the customer, who is still allowed to buy.
    case unregistered(FailureReason)

    /// Route the customer to the checkout with no identifier to hand over, as the app would outside Apple's
    /// programme: it does not apply here, see ``ExternalPurchaseAvailability/notEligible``, and the customer
    /// is in a storefront where the purchase may go ahead anyway.
    ///
    /// Nothing was shown and nothing was minted.
    case notApplicable

    enum StopReason: Equatable {

        /// Apple's flow does not apply here, and this storefront is not one of those where the purchase may
        /// go ahead without it, so the customer is offered nothing.
        case notAllowedInStorefront

        /// The device does not authorize payments, see ``ExternalPurchaseAvailability/paymentsNotAuthorized``.
        ///
        /// Apple asks that such a device be offered no purchase at all, so the caller is expected to route the
        /// customer nowhere.
        case paymentsNotAuthorized

        /// The customer declined at the disclosure notice.
        case customerCancelledNotice

        /// The notice could not be shown. Continuing without it would breach what StoreKit asks for, so this
        /// stops the purchase even though the customer did not decline.
        case noticeFailed

        /// Another preparation was already under way, and that one carries the purchase.
        case alreadyPreparing

    }

    enum FailureReason: Equatable {

        /// Requesting the token from StoreKit failed.
        case tokenRequestFailed

        /// The backend did not accept the registration.
        case registrationFailed

    }

}

// MARK: - Private

private extension ExternalPurchaseManager {

    /// Whether the app takes part in Apple's external purchase custom link programme at all, which is a
    /// precondition for everything here.
    var takesPartInTheProgramme: Bool {
        return self.systemInfo.dangerousSettings.useExternalPurchaseCustomLinks
    }

    var storefront: String? {
        return self.systemInfo.storefront?.countryCode.uppercased()
    }

    /// Whether the customer may be taken to an external purchase without Apple's flow around it.
    ///
    /// Asked on every purchase rather than cached, since the customer can change storefront while the app runs.
    func isInAStorefrontAllowedWithoutStoreEligibility() async -> Bool {
        guard let storefront = self.storefront else { return false }

        return await self.configProvider.storefrontsAllowedWithoutStoreEligibility().contains(storefront)
    }

    enum NoticeOutcome {
        case continued
        case cancelled
        case failed
    }

    func showNotice(type: ExternalPurchaseNoticeType) async -> NoticeOutcome {
        do {
            switch try await self.customLink.showNotice(type: type) {
            case .continued:
                return .continued
            case .cancelled:
                return .cancelled
            }
        } catch {
            Logger.error(Strings.externalPurchase.error_showing_notice(error))
            return .failed
        }
    }

    func registerToken(of tokenType: ExternalPurchaseTokenType) async -> ExternalPurchasePreparationResult {
        let token: String?
        do {
            token = try await self.customLink.token(for: tokenType)
        } catch {
            Logger.error(Strings.externalPurchase.error_requesting_token(error))
            return .unregistered(.tokenRequestFailed)
        }

        if token == nil {
            Logger.debug(Strings.externalPurchase.no_token_available)
        }

        let result: Result<ExternalPurchaseTokenResponse, BackendError> = await Async.call { completion in
            self.externalPurchaseTokenAPI.postExternalPurchaseToken(
                appUserID: self.currentUserProvider.currentAppUserID,
                purchaseType: tokenType,
                token: token,
                completion: completion
            )
        }

        switch result {
        case let .success(response):
            Logger.debug(Strings.externalPurchase.token_registered(response.id))
            return .registered(tokenID: response.id)
        case let .failure(error):
            Logger.error(Strings.externalPurchase.error_registering_token(error))
            return .unregistered(.registrationFailed)
        }
    }

}
