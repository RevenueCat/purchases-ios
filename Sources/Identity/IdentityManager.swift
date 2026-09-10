//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentityManager.swift
//
//  Created by Joshua Liebowitz on 8/9/21.

import Foundation

protocol CurrentUserProvider: AnyObject, Sendable {

    var currentAppUserID: String { get }
    var currentUserIsAnonymous: Bool { get }

}

protocol AttributeSyncing: Sendable {

    func syncSubscriberAttributes(currentAppUserID: String, completion: @escaping @Sendable () -> Void)

    /// Stores `attributes` as unsynced for `appUserID` and returns everything still pending sync for that
    /// user, so that they stay queued if the backend doesn't apply them.
    func storeAndGetUnsyncedAttributes(_ attributes: [String: String],
                                       appUserID: String) -> SubscriberAttribute.Dictionary

    /// Refreshes the automatically collected attributes and returns everything still pending sync
    /// for `appUserID`.
    func refreshATTStatusAndGetUnsyncedAttributes(appUserID: String) -> SubscriberAttribute.Dictionary

    /// Syncs the attributes buffered for every user except `appUserIDs`.
    func syncAttributesForUsersOtherThan(_ appUserIDs: Set<String>, currentAppUserID: String)

    /// Updates the local buffer with the outcome of `attributes` that were sent inline with a log in request.
    ///
    /// - Parameter errorResponse: the bucket's entry in `attributes_error_response`, or `nil` if the
    /// backend stored the whole bucket.
    func handleAttributesSentOnLogIn(_ attributes: SubscriberAttribute.Dictionary,
                                     appUserID: String,
                                     errorResponse: ErrorResponse?)
}

class IdentityManager: CurrentUserProvider {

    private let deviceCache: DeviceCache
    private let backend: Backend
    private let customerInfoManager: CustomerInfoManager
    private let tokenManager: TokenManager
    private let attributeSyncing: AttributeSyncing
    // Weak because RemoteConfigManager keeps IdentityManager as its CurrentUserProvider.
    weak var remoteConfigManager: RemoteConfigManagerType?

    private static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#

    init(
        deviceCache: DeviceCache,
        systemInfo: SystemInfo,
        backend: Backend,
        customerInfoManager: CustomerInfoManager,
        tokenManager: TokenManager,
        attributeSyncing: AttributeSyncing,
        appUserID: String?
    ) {
        self.deviceCache = deviceCache
        self.backend = backend
        self.customerInfoManager = customerInfoManager
        self.tokenManager = tokenManager
        self.attributeSyncing = attributeSyncing

        let finalAppUserID: String
        if systemInfo.dangerousSettings.uiPreviewMode {
            Logger.debug(Strings.identity.logging_in_with_preview_mode_appuserid)
            finalAppUserID = Self.uiPreviewModeAppUserID
        } else {
            if appUserID?.isEmpty == true {
                Logger.warn(Strings.identity.logging_in_with_empty_appuserid)
            }
            finalAppUserID = appUserID?.notEmptyOrWhitespaces
            ?? deviceCache.cachedAppUserID
            ?? deviceCache.cachedLegacyAppUserID
            ?? Self.generateRandomID()
        }

        Logger.user(Strings.identity.identifying_app_user_id)

        deviceCache.cache(appUserID: finalAppUserID)
        deviceCache.cleanupSubscriberAttributes()
        self.invalidateCachesIfNeeded(appUserID: finalAppUserID)
    }

    var currentAppUserID: String {
        guard let appUserID = self.deviceCache.cachedAppUserID else {
            fatalError(Strings.identity.null_currentappuserid.description)
        }

        return appUserID
    }

    var currentUserIsAnonymous: Bool {
        let userID = self.currentAppUserID

        if Self.userIsAnonymous(userID) {
            return true
        }

        if self.deviceCache.cachedLegacyAppUserID == userID {
            return true
        }

        if let info = try? self.customerInfoManager.cachedCustomerInfo(appUserID: userID),
           info.allIdentitiesAreAnonymous {
            return true
        }

        if tokenManager.isCurrentIdentityAnonymous {
            return true
        }

        return false
    }

    var needsIAMLogin: Bool {
        guard tokenManager.enabled else { return false }
        guard currentUserIsAnonymous else { return false }
        if tokenManager.hasCurrentAccessToken { return false }
        return true
    }

    func logIn(appUserID: String,
               attributes: [String: String],
               completion: @escaping IdentityAPI.LogInResponseHandler) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID && appUserID != Self.uiPreviewModeAppUserID else {
            completion(.failure(.unsupportedInUIPreviewMode()))
            return
        }

        self.performLogIn(appUserID: appUserID, attributes: attributes, completion: completion)
    }

    func logIn(identity: Identity, completion: @escaping IdentityAPI.LogInResponseHandler) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID else {
            completion(.failure(.unsupportedInUIPreviewMode()))
            return
        }

        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            self.performLogIn(identity: identity, completion: completion)
        }
    }

    func logOut(completion: @escaping (PurchasesError?) -> Void) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID else {
            completion(ErrorUtils.unsupportedInUIPreviewModeError())
            return
        }

        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            if self.tokenManager.enabled {
                self.performTokenRevocation(for: self.currentAppUserID, completion: completion)
            } else {
                self.performLogOut(completion: completion)
            }
        }
    }

    func switchUser(to newAppUserID: String) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID &&
              newAppUserID != Self.uiPreviewModeAppUserID else {
            Logger.error(Strings.identity.operation_not_supported_in_preview_mode)
            return
        }
        Logger.debug(Strings.identity.switching_user(newUserID: newAppUserID))
        self.resetCacheAndSave(newUserID: newAppUserID)
    }

    static func generateRandomID() -> String {
        "$RCAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }

    static let uiPreviewModeAppUserID: String = "$RC_PREVIEW_MODE_USER"
}

extension IdentityManager {

    static func userIsAnonymous(_ appUserId: String) -> Bool {
        let anonymousFoundRange = appUserId.range(of: IdentityManager.anonymousRegex,
                                                  options: .regularExpression)
        return anonymousFoundRange != nil
    }

}

private extension IdentityManager {

    func performLogIn(appUserID: String,
                      attributes: [String: String],
                      completion: @escaping IdentityAPI.LogInResponseHandler) {
        let oldAppUserID = self.currentAppUserID
        let newAppUserID = appUserID.trimmingWhitespacesAndNewLines
        guard !newAppUserID.isEmpty else {
            Logger.error(Strings.identity.logging_in_with_empty_appuserid)
            completion(.failure(.missingAppUserID()))
            return
        }

        // Buffering these locally so that, if anything fails, they're queued for the next sync.
        let newUserAttributes = self.attributeSyncing.storeAndGetUnsyncedAttributes(attributes,
                                                                                    appUserID: newAppUserID)

        guard newAppUserID != oldAppUserID else {
            Logger.warn(Strings.identity.logging_in_with_same_appuserid)

            // There's no identify request to carry the attributes, so they go through a regular sync.
            self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: oldAppUserID) {
                self.customerInfoManager.customerInfo(appUserID: oldAppUserID,
                                                      fetchPolicy: .cachedOrFetched) { @Sendable result in
                    completion(
                        result.map { (info: $0, created: false, attributesErrorResponse: nil) }
                    )
                }
            }
            return
        }

        let previousUnsyncedAttributes = self.attributeSyncing
            .refreshATTStatusAndGetUnsyncedAttributes(appUserID: oldAppUserID)

        self.backend.identity.logIn(currentAppUserID: oldAppUserID,
                                    newAppUserID: newAppUserID,
                                    attributes: newUserAttributes,
                                    previousUnsyncedAttributes: previousUnsyncedAttributes) { result in
            if case let .success((customerInfo, _, attributesErrorResponse)) = result {
                self.attributeSyncing.handleAttributesSentOnLogIn(
                    previousUnsyncedAttributes,
                    appUserID: oldAppUserID,
                    errorResponse: attributesErrorResponse?.previousUnsyncedAttributes
                )
                self.attributeSyncing.handleAttributesSentOnLogIn(
                    newUserAttributes,
                    appUserID: newAppUserID,
                    errorResponse: attributesErrorResponse?.attributes
                )

                self.remoteConfigManager?.clearCache(forAppUserID: newAppUserID)
                self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newAppUserID)
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: newAppUserID)
                self.copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: oldAppUserID,
                                                                       newAppUserID: newAppUserID)
            }

            completion(result)
        }

        // The request above only carries these two users. Whatever is buffered for users the app logged in
        // as earlier still needs a regular sync, which goes last so it queues behind the log in: both share
        // the same serial operation queue.
        self.attributeSyncing.syncAttributesForUsersOtherThan(
            [oldAppUserID, newAppUserID],
            currentAppUserID: oldAppUserID
        )
    }

    func performLogIn(identity: Identity, completion: @escaping IdentityAPI.LogInResponseHandler) {
        let oldAppUserID = self.currentAppUserID

        self.backend.token.logIn(currentAppUserID: oldAppUserID, identity: identity) { result in
            switch result {
            case .success(let (_, newAppUserID)):
                self.remoteConfigManager?.clearCache(forAppUserID: newAppUserID)
                self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newAppUserID)
                self.copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: oldAppUserID,
                                                                       newAppUserID: newAppUserID)

                self.customerInfoManager.customerInfo(appUserID: newAppUserID,
                                                      fetchPolicy: .cachedOrFetched,
                                                      completion: { result in

                    completion(result.map { (info: $0, created: false, attributesErrorResponse: nil) })
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func performTokenRevocation(for appUserID: String, completion: @escaping (PurchasesError?) -> Void) {
        self.backend.token.revokeTokens(for: appUserID) { error in
            if let purchasesError = error?.asPurchasesError {
                completion(purchasesError)
            } else {
                self.performLogOut(completion: completion)
            }
        }
    }

    func performLogOut(completion: @escaping (PurchasesError?) -> Void) {
        Logger.info(Strings.identity.log_out_called_for_user)

        if self.currentUserIsAnonymous {
            completion(ErrorUtils.logOutAnonymousUserError())
            return
        }

        let newUserID = Self.generateRandomID()
        self.resetCacheAndSave(newUserID: newUserID)
        Logger.info(Strings.identity.log_out_success)

        if self.tokenManager.enabled {
            // immediately get tokens for the new user id
            self.performLogIn(identity: .anonymous, completion: { result in
                completion(result.error?.asPurchasesError)
            })
        } else {
            completion(nil)
        }
    }
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IdentityManager: @unchecked Sendable {}

// MARK: - Private

private extension IdentityManager {

    func resetCacheAndSave(newUserID: String) {
        let oldAppUserID = self.currentAppUserID
        self.remoteConfigManager?.clearCache(forAppUserID: newUserID)
        self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newUserID)
        self.deviceCache.clearLatestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
        self.backend.clearHTTPClientCaches()
    }

    func copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: String, newAppUserID: String) {
        guard Self.userIsAnonymous(oldAppUserID) else {
            return
        }
        self.deviceCache.copySubscriberAttributes(oldAppUserID: oldAppUserID, newAppUserID: newAppUserID)
    }

    func invalidateCachesIfNeeded(appUserID: String) {
        if self.shouldInvalidateCaches(for: appUserID) {
            Logger.info(Strings.identity.invalidating_http_cache)
            self.backend.clearHTTPClientCaches()
        }
    }

    private func shouldInvalidateCaches(for appUserID: String) -> Bool {
        guard self.backend.signatureVerificationEnabled,
              let info = try? self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID) else {
            return false
        }

        return info.entitlements.verification == .notRequested
    }

}
