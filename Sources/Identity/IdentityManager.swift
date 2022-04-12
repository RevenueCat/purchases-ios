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

protocol CurrentUserProvider {

    var currentAppUserID: String { get }
    var currentUserIsAnonymous: Bool { get }

}

class IdentityManager: CurrentUserProvider {

    private let deviceCache: DeviceCache
    private let backend: Backend
    private let customerInfoManager: CustomerInfoManager

    internal static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#

    init(
        deviceCache: DeviceCache,
        backend: Backend,
        customerInfoManager: CustomerInfoManager,
        appUserID: String?
    ) {
        self.deviceCache = deviceCache
        self.backend = backend
        self.customerInfoManager = customerInfoManager

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

        let anonymousFoundRange = currentAppUserID.range(of: IdentityManager.anonymousRegex,
                                                         options: .regularExpression)
        let currentAppUserIDLooksAnonymous = anonymousFoundRange != nil
        let isLegacyAnonymousAppUserID = currentAppUserID == deviceCache.cachedLegacyAppUserID

        return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID
    }

    func logIn(appUserID: String, completion: @escaping Backend.LogInResponseHandler) {
        let newAppUserID = appUserID.trimmingWhitespacesAndNewLines
        guard !newAppUserID.isEmpty else {
            Logger.error(Strings.identity.logging_in_with_empty_appuserid)
            completion(.failure(.missingAppUserID()))
            return
        }

        guard newAppUserID != currentAppUserID else {
            Logger.warn(Strings.identity.logging_in_with_same_appuserid)
            customerInfoManager.customerInfo(appUserID: currentAppUserID) { result in
                completion(
                    result.map { (info: $0, created: false) }
                )
            }
            return
        }

        backend.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { result in
            if case let .success((customerInfo, _)) = result {
                self.deviceCache.clearCaches(oldAppUserID: self.currentAppUserID, andSaveWithNewUserID: newAppUserID)
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: newAppUserID)
            }

            completion(result)
        }
    }

    func logOut(completion: (Error?) -> Void) {
        Logger.info(Strings.identity.log_out_called_for_user)

        if currentUserIsAnonymous {
            completion(ErrorUtils.logOutAnonymousUserError())
            return
        }

        self.resetUserIDCache()
        Logger.info(Strings.identity.log_out_success)
        completion(nil)
    }

    static func generateRandomID() -> String {
        "$RCAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
}

private extension IdentityManager {

    func resetUserIDCache() {
        deviceCache.clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: Self.generateRandomID())
        deviceCache.clearLatestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
        backend.clearHTTPClientCaches()
    }

}
