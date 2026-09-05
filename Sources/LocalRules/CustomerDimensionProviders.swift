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

/// Forwards the dimensions the backend worked out for this customer, untouched, so a new one
/// ships without a new SDK. They are only as fresh as the last answer received.
struct ServerSnapshotDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.serverSnapshot

    private let customerInfoProvider: any CustomerInfoDimensionSource

    init(customerInfoProvider: any CustomerInfoDimensionSource) {
        self.customerInfoProvider = customerInfoProvider
    }

    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        let appUserID = context.appUserID
        let customerInfo: CustomerInfo
        do {
            customerInfo = try await self.customerInfoProvider.customerInfo(appUserID: appUserID)
        } catch let error as CancellationError {
            throw error
        } catch {
            Logger.warn(Strings.remoteConfig.customerInfoUnavailable(error))
            return [:]
        }

        guard let dimensions = customerInfo.backendDimensions else { return [:] }

        return dimensions.compactMapValues(DimensionValue.init(json:))
    }

}

// MARK: - Client snapshot

/// Supplies what this device is sure of right now, which takes precedence over the server
/// snapshot's older answer to the same question.
struct ActiveEntitlementsDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.clientSnapshot

    private let customerInfoProvider: any CustomerInfoDimensionSource

    init(customerInfoProvider: any CustomerInfoDimensionSource) {
        self.customerInfoProvider = customerInfoProvider
    }

    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        let appUserID = context.appUserID

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

    /// Keyed by identifier, so a rule reads one by name and needs no iteration.
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

extension DimensionValue {

    /// A value JSON Logic has no reading for is left out rather than guessed at.
    init?(json: AnyDecodable) {
        switch json {
        case .string(let value):
            self = .string(value)
        case .bool(let value):
            self = .bool(value)
        case .int(let value):
            self = .int(Int64(value))
        case .double(let value):
            self = .double(value)
        case .object(let value):
            self = .object(value.compactMapValues(DimensionValue.init(json:)))
        case .array(let value):
            // A collection is only readable by an iteration operator, which walks records, so a
            // scalar or mixed array has no reading at all.
            let records = value.compactMap { element -> [String: AnyDecodable]? in
                guard case .object(let record) = element else { return nil }
                return record
            }
            guard records.count == value.count else { return nil }
            self = .objectList(records.map { $0.compactMapValues(DimensionValue.init(json:)) })
        case .null:
            return nil
        }
    }

}
