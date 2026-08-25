//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesDimensionProvider.swift
//
//  Created by Rick van der Linden on 8/19/26.
//

import Foundation

/// Supplies the subscriber attributes stored for the current customer to the local rules engine.
struct SubscriberAttributesDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.clientSnapshot

    private let attributesProvider: @Sendable (String) throws -> SubscriberAttribute.Dictionary

    init(deviceCache: DeviceCache) {
        self.init { appUserID in
            deviceCache.subscriberAttributes(appUserID: appUserID)
        }
    }

    init(
        attributesProvider: @escaping @Sendable (String) throws -> SubscriberAttribute.Dictionary
    ) {
        self.attributesProvider = attributesProvider
    }

    /// Reads attributes for each evaluation because an app can update them at any time.
    ///
    /// A failed read contributes no dimensions rather than preventing the other
    /// dimensions from being evaluated.
    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        let attributes: SubscriberAttribute.Dictionary
        do {
            attributes = try self.attributesProvider(context.appUserID)
        } catch {
            Logger.warn(Strings.remoteConfig.subscriberAttributesUnavailable(error))
            return [:]
        }

        let dimensions: [String: DimensionValue] = attributes.values.reduce(into: [:]) { dimensions, attribute in
            // An empty value represents a deleted attribute, whether or not its tombstone has been synced.
            guard !attribute.value.isEmpty else { return }

            dimensions[attribute.key] = .object([
                Self.valueKey: .string(attribute.value),
                Self.updatedAtKey: .date(attribute.setTime),
                Self.evaluatedAtKey: .date(context.date)
            ])
        }

        return [Self.subscriberAttributesKey: .object(dimensions)]
    }

    private static let evaluatedAtKey = "evaluatedAt"
    private static let subscriberAttributesKey = "subscriberAttributes"
    private static let updatedAtKey = "updatedAt"
    private static let valueKey = "value"

}
