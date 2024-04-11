//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CloudSyncedAnonymousIDProvider.swift
//
//  Created by Andrés Boedo on 4/10/24.

import Foundation

class CloudSyncedAnonymousIDProvider {

    // todo: inject store
    private let store = NSUbiquitousKeyValueStore.default
    private enum Constants {
        static let keyValueStoreKey: String = "appUserID"
        static let appUserIDPrefix: String = "$RCCloudAnonymousID:"
    }

    var appUserID: String {
        get {
            if let id = self.store.string(forKey: Constants.keyValueStoreKey) {
                return id
            } else {
                return self.resetAppUserID()
            }
        }
        set {
            self.store.set(newValue, forKey: Constants.keyValueStoreKey)
            self.store.synchronize()
        }
    }

    // todo: add checks for this
    func isKeyValueStoreAvailable() -> Bool {
        let token = FileManager.default.ubiquityIdentityToken
        return token != nil
    }

    func resetAppUserID() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let newID = Constants.appUserIDPrefix + uuid
        store.set(newID, forKey: Constants.keyValueStoreKey)
        store.synchronize()
        return newID
    }

    func isCloudSyncedAnonymousID(appUserID: String) -> Bool {
        return appUserID.starts(with: Constants.appUserIDPrefix)
    }

}
