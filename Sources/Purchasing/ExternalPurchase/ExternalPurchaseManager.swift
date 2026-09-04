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

    /// Resolved on first use and reused afterwards, so a tap does not pay for the check.
    ///
    /// A storefront change within the same session is therefore not picked up, which is an accepted trade for
    /// keeping the check off the tap.
    private let cachedEligibility: Atomic<Bool?> = nil

    init(customLink: ExternalPurchaseCustomLinkType,
         externalPurchaseTokenAPI: ExternalPurchaseTokenAPI,
         currentUserProvider: CurrentUserProvider) {
        self.customLink = customLink
        self.externalPurchaseTokenAPI = externalPurchaseTokenAPI
        self.currentUserProvider = currentUserProvider
    }

    /// Whether the app can offer an external purchase to this customer.
    ///
    /// Safe to call before the customer intends to buy, and worth doing so: it mints nothing, so it creates no
    /// obligation to report anything to Apple, and resolving it while the paywall loads keeps it off the tap.
    @discardableResult
    func canMakeExternalPurchases() async -> Bool {
        if let cached = self.cachedEligibility.value {
            return cached
        }

        let canMakeExternalPurchases = await self.customLink.canMakeExternalPurchases()
        self.cachedEligibility.value = canMakeExternalPurchases
        Logger.debug(Strings.externalPurchase.eligibility_resolved(canMakeExternalPurchases))

        return canMakeExternalPurchases
    }

    /// Prepares an external purchase, in response to the customer deliberately asking for one.
    ///
    /// Must not be called before then: the notice may only be shown in response to a customer interaction, and
    /// every token minted here is one Apple expects a report for, whether or not a transaction follows.
    func prepareExternalPurchase(flow: ExternalPurchaseFlow) async -> ExternalPurchasePreparationResult {
        guard await self.canMakeExternalPurchases() else {
            Logger.warn(Strings.externalPurchase.cannot_make_external_purchases)
            return .stopped(.cannotMakeExternalPurchases)
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

    /// Do not route the customer to the checkout. Nothing was minted, so there is nothing to report.
    case stopped(StopReason)

    /// Route the customer to the checkout, handing this identifier to the checkout page.
    case registered(tokenID: String)

    /// Route the customer to the checkout with no identifier to hand over.
    ///
    /// The purchase cannot be tied back to a token, so it will not be reportable to Apple. That is deliberately
    /// not treated as a failure for the customer, who is still allowed to buy.
    case unreportable(UnreportableReason)

    enum StopReason: Equatable {

        /// The storefront is not eligible, or the device does not authorize payments. The two are not
        /// distinguishable, see ``ExternalPurchaseCustomLinkType/canMakeExternalPurchases()``.
        case cannotMakeExternalPurchases

        /// The customer declined at the disclosure notice.
        case customerCancelledNotice

        /// The notice could not be shown. Continuing without it would breach what StoreKit asks for, so this
        /// stops the purchase even though the customer did not decline.
        case noticeFailed

    }

    enum UnreportableReason: Equatable {

        /// StoreKit had no token of the requested type to give.
        case noTokenAvailable

        /// Requesting the token from StoreKit failed.
        case tokenRequestFailed

        /// The token exists but the backend did not accept it.
        case registrationFailed

    }

}

extension ExternalPurchasePreparationResult {

    /// Whether the customer should be routed to the checkout.
    var shouldProceed: Bool {
        switch self {
        case .stopped:
            return false
        case .registered, .unreportable:
            return true
        }
    }

    /// The identifier to hand to the checkout page, when there is one.
    var tokenID: String? {
        switch self {
        case let .registered(tokenID):
            return tokenID
        case .stopped, .unreportable:
            return nil
        }
    }

}

// MARK: - Private

private extension ExternalPurchaseManager {

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
            return .unreportable(.tokenRequestFailed)
        }

        guard let token else {
            Logger.warn(Strings.externalPurchase.no_token_available)
            return .unreportable(.noTokenAvailable)
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
            return .unreportable(.registrationFailed)
        }
    }

}
