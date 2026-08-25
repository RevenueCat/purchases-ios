//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerDimensionProviders.swift
//
//  Created by Facundo Menzella on 25/8/26.
//

import Foundation

/// Reads the customer info a snapshot describes.
///
/// The customer is asked for by name rather than read here, so the entitlements a snapshot reports
/// and the ID it reports them under always describe the same customer even when the app logs in,
/// logs out, or switches user while the read is suspended.
protocol CustomerInfoDimensionSource: Sendable {

    func customerInfo(appUserID: String) async throws -> CustomerInfo
}

extension CustomerInfoManager: CustomerInfoDimensionSource {

    func customerInfo(appUserID: String) async throws -> CustomerInfo {
        return try await self.customerInfo(appUserID: appUserID, fetchPolicy: .default)
    }
}

// MARK: - Server snapshot

/// Forwards the dimensions the backend worked out for this customer, untouched.
///
/// Nothing here reads them. The backend can describe a customer in a way this version of the SDK
/// has never heard of and a rule can still be written against it, which is the point: a new
/// dimension ships without a new SDK.
///
/// They are only as fresh as the last answer received, so anything the device can be sure of right
/// now is reported by ``ActiveEntitlementsDimensionProvider`` instead and wins.
struct ServerSnapshotDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.serverSnapshot

    private let currentUserProvider: any CurrentUserProvider
    private let customerInfoProvider: any CustomerInfoDimensionSource

    init(
        currentUserProvider: any CurrentUserProvider,
        customerInfoProvider: any CustomerInfoDimensionSource
    ) {
        self.currentUserProvider = currentUserProvider
        self.customerInfoProvider = customerInfoProvider
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        let appUserID = self.currentUserProvider.currentAppUserID
        let customerInfo: CustomerInfo
        do {
            customerInfo = try await self.customerInfoProvider.customerInfo(appUserID: appUserID)
        } catch let error as CancellationError {
            throw error
        } catch {
            Logger.warn(Strings.remoteConfig.customerInfoUnavailable(error))
            return [:]
        }

        let subscriber = customerInfo.rawData[Self.subscriberKey] as? [String: Any]
        guard let dimensions = subscriber?[Self.dimensionsKey] as? [String: Any] else {
            return [:]
        }

        return DimensionValue.dimensions(from: dimensions)
    }

    private static let dimensionsKey = "dimensions"
    private static let subscriberKey = "subscriber"

}

// MARK: - Client snapshot

/// Supplies what this device is sure of about the customer right now.
///
/// The entitlements a customer holds are the question a rule asks most, and the one the SDK can
/// answer accurately without the backend, so they are reported from here and take precedence over
/// the same answer in the server snapshot.
struct ActiveEntitlementsDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.clientSnapshot

    private let currentUserProvider: any CurrentUserProvider
    private let customerInfoProvider: any CustomerInfoDimensionSource

    init(
        currentUserProvider: any CurrentUserProvider,
        customerInfoProvider: any CustomerInfoDimensionSource
    ) {
        self.currentUserProvider = currentUserProvider
        self.customerInfoProvider = customerInfoProvider
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        let appUserID = self.currentUserProvider.currentAppUserID

        var dimensions: [String: DimensionValue] = [:]
        if !appUserID.isEmpty {
            dimensions[Self.appUserIDKey] = .string(appUserID)
        }

        // Entitlements this device could not read are left out rather than reported as an empty
        // set, so a rule about them fails to resolve instead of reading as a customer holding none.
        do {
            let customerInfo = try await self.customerInfoProvider.customerInfo(appUserID: appUserID)
            dimensions[Self.activeEntitlementsKey] = .object(Self.activeEntitlements(of: customerInfo))
        } catch let error as CancellationError {
            throw error
        } catch {
            Logger.warn(Strings.remoteConfig.customerInfoUnavailable(error))
        }

        return dimensions
    }

    /// Keyed by identifier, so a rule about one entitlement reads it by name and needs no iteration.
    private static func activeEntitlements(of customerInfo: CustomerInfo) -> [String: DimensionValue] {
        return customerInfo.entitlements.active.reduce(into: [:]) { entitlements, entry in
            var entitlement: [String: DimensionValue] = [
                Self.productIdentifierKey: .string(entry.value.productIdentifier)
            ]
            if let expirationDate = entry.value.expirationDate {
                entitlement[Self.expiresAtKey] = .date(expirationDate)
            }
            entitlements[entry.key] = .object(entitlement)
        }
    }

    private static let activeEntitlementsKey = "activeEntitlements"
    private static let appUserIDKey = "appUserId"
    private static let expiresAtKey = "expiresAt"
    private static let productIdentifierKey = "productIdentifier"

}
