//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenStore.swift
//
//  Created by Antonio Pallares on 10/9/26.

import Foundation

/// Keeps the external purchase token registrations the backend has yet to answer for.
protocol ExternalPurchaseTokenStoreType: Sendable {

    /// Keep a registration, before it is posted.
    func store(_ registration: ExternalPurchaseTokenRegistration)

    /// Drop a registration the backend has answered for, whether it accepted or rejected it.
    func remove(_ registration: ExternalPurchaseTokenRegistration)

    /// Every registration kept, in no particular order.
    func allRegistrations() -> [ExternalPurchaseTokenRegistration]

}

/// Stores external purchase token registrations persistently on disk, so that one minted in a session that
/// never reached the backend can still be posted in a later one.
final class ExternalPurchaseTokenStore: ExternalPurchaseTokenStoreType {

    private static let storeKeyPrefix = "external_purchase_token_registration_"

    private let cache: SynchronizedLargeItemCache

    init(apiKey: String, fileManager: LargeItemCacheType = FileManager.default) {
        let directoryType: DirectoryHelper.DirectoryType
        #if os(tvOS)
        directoryType = .cache
        #else
        directoryType = .applicationSupport(overrideURL: nil)
        #endif

        self.cache = SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: "external-purchase-tokens-\(apiKey)",
            directoryType: directoryType
        )
    }

    func store(_ registration: ExternalPurchaseTokenRegistration) {
        self.cache.set(codable: registration, forKey: Self.key(for: registration))
    }

    func remove(_ registration: ExternalPurchaseTokenRegistration) {
        self.cache.removeObject(forKey: Self.key(for: registration))
    }

    func allRegistrations() -> [ExternalPurchaseTokenRegistration] {
        return self.cache.allKeys().compactMap { key in
            do {
                return try self.cache.value(forKey: key, decoder: .default)
            } catch {
                Logger.error(Strings.externalPurchase.error_loading_registration(error))
                self.cache.removeObject(forKey: key)
                return nil
            }
        }
    }

    /// Keys become file names, so they may not contain path separators. ``ExternalPurchaseTokenID`` only
    /// generates identifiers that are safe to use as they are.
    private static func key(for registration: ExternalPurchaseTokenRegistration) -> String {
        return Self.storeKeyPrefix + registration.tokenID
    }

}
