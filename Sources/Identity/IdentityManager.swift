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

        lazy var currentAppUserIDLooksAnonymous = Self.userIsAnonymous(userID)
        lazy var isLegacyAnonymousAppUserID = userID == self.deviceCache.cachedLegacyAppUserID
        lazy var isAnonymousAMR = tokenManager.currentAMR == "anonymous"

        return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID || isAnonymousAMR
    }

    func logIn(appUserID: String, completion: @escaping IdentityAPI.LogInResponseHandler) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID && appUserID != Self.uiPreviewModeAppUserID else {
            completion(.failure(.unsupportedInUIPreviewMode()))
            return
        }

        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            self.performLogIn(appUserID: appUserID, completion: completion)
        }
    }

    func logIn(externalToken: ExternalToken, completion: @escaping IdentityAPI.LogInResponseHandler) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID else {
            completion(.failure(.unsupportedInUIPreviewMode()))
            return
        }

        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            self.performLogIn(token: externalToken, completion: completion)
        }
    }

    func logOut(completion: @escaping (PurchasesError?) -> Void) {
        guard self.currentAppUserID != Self.uiPreviewModeAppUserID else {
            completion(ErrorUtils.unsupportedInUIPreviewModeError())
            return
        }

        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            if self.backend.token.enabled {
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

    func performLogIn(appUserID: String, completion: @escaping IdentityAPI.LogInResponseHandler) {
        let oldAppUserID = self.currentAppUserID
        let newAppUserID = appUserID.trimmingWhitespacesAndNewLines
        guard !newAppUserID.isEmpty else {
            Logger.error(Strings.identity.logging_in_with_empty_appuserid)
            completion(.failure(.missingAppUserID()))
            return
        }

        guard newAppUserID != oldAppUserID else {
            Logger.warn(Strings.identity.logging_in_with_same_appuserid)
            self.customerInfoManager.customerInfo(appUserID: oldAppUserID,
                                                  fetchPolicy: .cachedOrFetched) { @Sendable result in
                completion(
                    result.map { (info: $0, created: false) }
                )
            }
            return
        }

        self.backend.identity.logIn(currentAppUserID: oldAppUserID, newAppUserID: newAppUserID) { result in
            if case let .success((customerInfo, _)) = result {
                self.remoteConfigManager?.clearCache(forAppUserID: newAppUserID)
                self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newAppUserID)
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: newAppUserID)
                self.copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: oldAppUserID,
                                                                       newAppUserID: newAppUserID)
            }

            completion(result)
        }
    }

    func performLogIn(token: ExternalToken, completion: @escaping IdentityAPI.LogInResponseHandler) {
        let oldAppUserID = self.currentAppUserID

        self.backend.token.logIn(currentAppUserID: oldAppUserID, token: token) { result in
            switch result {
            case .success(let (_, newAppUserID)):
                self.remoteConfigManager?.clearCache(forAppUserID: newAppUserID)
                self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newAppUserID)
                self.copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: oldAppUserID,
                                                                       newAppUserID: newAppUserID)

                self.customerInfoManager.customerInfo(appUserID: newAppUserID,
                                                      fetchPolicy: .fetchCurrent,
                                                      completion: { result in

                    let mapped = result.map { (info: $0, created: false) }
                    completion(mapped)
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

        if self.backend.token.enabled {
            // immediately get tokens for the new user id
            self.performLogIn(token: .anonymous(appUserID: newUserID), completion: { result in
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
