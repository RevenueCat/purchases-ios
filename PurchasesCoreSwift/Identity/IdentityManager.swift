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

// TODO (post-migration): Change back to internal, including all public properties.
@objc(RCIdentityManager) public class IdentityManager: NSObject {

    static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#

    @objc public var maybeCurrentAppUserID: String? {
        return deviceCache.cachedAppUserID
    }

    @objc public var currentUserIsAnonymous: Bool {
        guard let cachedAppUserID = maybeCurrentAppUserID else {
            return false
        }

        let anonymousFoundRange = maybeCurrentAppUserID?.range(of: IdentityManager.anonymousRegex,
                                                          options: .regularExpression)
        let currentAppUserIDLooksAnonymous = anonymousFoundRange != nil
        let isLegacyAnonymousAppUserID = cachedAppUserID == deviceCache.cachedLegacyAppUserID

        return currentAppUserIDLooksAnonymous || isLegacyAnonymousAppUserID
    }

    private let deviceCache: DeviceCache
    private let backend: Backend
    private let purchaserInfoManager: PurchaserInfoManager

    @objc public init(deviceCache: DeviceCache, backend: Backend, purchaserInfoManager: PurchaserInfoManager) {
        self.deviceCache = deviceCache
        self.backend = backend
        self.purchaserInfoManager = purchaserInfoManager
    }

    @objc public func configure(appUserID maybeAppUserID: String?) {
        let appUserID = maybeAppUserID
            ?? deviceCache.cachedAppUserID
            ?? deviceCache.cachedLegacyAppUserID
            ?? generateRandomID()
        Logger.user(String(format: Strings.identity.identifying_app_user_id, appUserID))

        deviceCache.cache(appUserID: appUserID)
        deviceCache.cleanupSubscriberAttributes()
    }

    @objc public func logIn(appUserID: String, completion: @escaping (PurchaserInfo?, Bool, Error?) -> Void) {
        let newAppUserID = appUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let currentAppUserID = maybeCurrentAppUserID,
              !newAppUserID.isEmpty else {
            let message = maybeCurrentAppUserID == nil
                ? Strings.identity.logging_in_with_initial_appuserid_nil
                : Strings.identity.logging_in_with_nil_appuserid
            Logger.error(message)
            completion(nil, false, ErrorUtils.missingAppUserIDError())
            return
        }

        guard newAppUserID != currentAppUserID else {
            Logger.warn(Strings.identity.logging_in_with_same_appuserid)
            purchaserInfoManager.purchaserInfo(appUserID: currentAppUserID) { maybePurchaserInfo, maybeError in
                completion(maybePurchaserInfo, false, maybeError)
            }
            return
        }

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { maybePurchaserInfo, created, maybeError in
            if maybeError == nil,
               let purchaserInfo = maybePurchaserInfo {
                self.deviceCache.clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: newAppUserID)
                self.purchaserInfoManager.cache(purchaserInfo: purchaserInfo, appUserID: newAppUserID)
            }

            completion(maybePurchaserInfo, created, maybeError)
        }
    }

    @objc public func logOut(completion: (Error?) -> Void) {
        Logger.info(String(format: Strings.identity.log_out_called_for_user, maybeCurrentAppUserID ?? "<nil currentAppUserID>"))

        if currentUserIsAnonymous {
            completion(ErrorUtils.logOutAnonymousUserError())
            return
        }

        resetAppUserID()
        Logger.info(Strings.identity.log_out_success)
        completion(nil)
    }

    // TODO (post-migration): Change back to private.
    func generateRandomID() -> String {
        "$RCAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }

}

// MARK: Deprecated
// TODO: Migrate off these so we can mark them deprecated.
extension IdentityManager {

    @objc(identifyAppUserID:completion:)
    public func identify(appUserID: String, completion: @escaping (Error?) -> Void) {
        // TODO: Old code assumed we weren't nil, but it doesn't actually look like we need a value since
        // we'll end up changing the app user id anyway.
        let currentAppUserID = maybeCurrentAppUserID ?? ""
        if currentUserIsAnonymous {
            Logger.user(String(format: Strings.identity.identifying_anon_id, currentAppUserID))
            createAlias(appUserID: appUserID, completion: completion)
        } else {
            Logger.user(String(format: Strings.identity.changing_app_user_id, currentAppUserID, appUserID))
            deviceCache.clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: appUserID)
            completion(nil)
        }
    }

    @objc(createAliasForAppUserID:completion:)
    public func createAlias(appUserID alias: String, completion: @escaping (Error?) -> Void) {
        guard let currentAppUserID = maybeCurrentAppUserID else {
            Logger.warn(Strings.identity.creating_alias_failed_null_currentappuserid)
            completion(ErrorUtils.missingAppUserIDError())
            return
        }

        backend.createAlias(appUserID: currentAppUserID, newAppUserID: alias) { maybeError in
            if maybeError == nil {
                Logger.user(Strings.identity.creating_alias_success)
                self.deviceCache.clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: alias)
            }
            completion(maybeError)
        }
    }

    @objc public func resetAppUserID() {
        guard let oldAppUserID = maybeCurrentAppUserID else {
            Logger.info(Strings.identity.reset_missing_app_user_id)
            return
        }

        deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: generateRandomID())
        deviceCache.clearLatestNetworkAndAdvertisingIdsSent(appUserID: oldAppUserID)
        backend.clearCaches()
    }

}
