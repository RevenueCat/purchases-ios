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

protocol CurrentUserProvider: Sendable {

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
    private let attributeSyncing: AttributeSyncing

    private static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#

    init(
        deviceCache: DeviceCache,
        backend: Backend,
        customerInfoManager: CustomerInfoManager,
        attributeSyncing: AttributeSyncing,
        appUserID: String?
    ) {
        self.deviceCache = deviceCache
        self.backend = backend
        self.customerInfoManager = customerInfoManager
        self.attributeSyncing = attributeSyncing

        if appUserID?.isEmpty == true {
            Logger.warn(Strings.identity.logging_in_with_empty_appuserid)
        }

        let appUserID = appUserID?.notEmptyOrWhitespaces
            ?? deviceCache.cachedAppUserID
            ?? deviceCache.cachedLegacyAppUserID
            ?? Self.generateRandomID()

        Logger.user(Strings.identity.identifying_app_user_id)

        deviceCache.cache(appUserID: appUserID)
        deviceCache.cleanupSubscriberAttributes()
    }

    var currentAppUserID: String {
        guard let appUserID = deviceCache.cachedAppUserID else {
            fatalError(Strings.identity.null_currentappuserid.description)
        }

        return appUserID
    }

    var currentUserIsAnonymous: Bool {
        let userID = self.currentAppUserID

        lazy var currentAppUserIDLooksAnonymous = Self.userIsAnonymous(userID)
        lazy var isLegacyAnonymousAppUserID = userID == self.deviceCache.cachedLegacyAppUserID

        return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID
    }

    func logIn(appUserID: String, completion: @escaping IdentityAPI.LogInResponseHandler) {
        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            self.performLogIn(appUserID: appUserID, completion: completion)
        }
    }

    func logOut(completion: @escaping (PurchasesError?) -> Void) {
        self.attributeSyncing.syncSubscriberAttributes(currentAppUserID: self.currentAppUserID) {
            self.performLogOut(completion: completion)
        }
    }

    static func generateRandomID() -> String {
        "$RCAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }

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
                self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newAppUserID)
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: newAppUserID)
                self.copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: oldAppUserID,
                                                                       newAppUserID: newAppUserID)
            }

            completion(result)
        }
    }

    func performLogOut(completion: (PurchasesError?) -> Void) {
        Logger.info(Strings.identity.log_out_called_for_user)

        if self.currentUserIsAnonymous {
            completion(ErrorUtils.logOutAnonymousUserError())
            return
        }

        self.resetUserIDCache()
        Logger.info(Strings.identity.log_out_success)
        completion(nil)
    }
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IdentityManager: @unchecked Sendable {}

// MARK: - Private

private extension IdentityManager {

    func resetUserIDCache() {
        deviceCache.clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: Self.generateRandomID())
        deviceCache.clearLatestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
        backend.clearHTTPClientCaches()
    }

    func copySubscriberAttributesToNewUserIfOldIsAnonymous(oldAppUserID: String, newAppUserID: String) {
        guard Self.userIsAnonymous(oldAppUserID) else {
            return
        }
        self.deviceCache.copySubscriberAttributes(oldAppUserID: oldAppUserID, newAppUserID: newAppUserID)
    }

}
