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

    let name = "subscriber_attributes"

    private let attributesProvider: @Sendable () throws -> SubscriberAttribute.Dictionary

    init(
        deviceCache: DeviceCache,
        currentUserProvider: any CurrentUserProvider
    ) {
        self.init {
            deviceCache.subscriberAttributes(appUserID: currentUserProvider.currentAppUserID)
        }
    }

    init(
        attributesProvider: @escaping @Sendable () throws -> SubscriberAttribute.Dictionary
    ) {
        self.attributesProvider = attributesProvider
    }

    /// Reads attributes for each evaluation because an app can update them at any time.
    ///
    /// A failed read contributes no dimensions rather than preventing the other
    /// dimensions from being evaluated.
    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        let attributes: SubscriberAttribute.Dictionary
        do {
            attributes = try self.attributesProvider()
        } catch {
            Logger.warn(Strings.localRules.subscriberAttributesUnavailable(error))
            return [:]
        }

        let records = attributes.values.reduce(into: [String: DimensionValue]()) { dimensions, attribute in
            // An empty value represents a deleted attribute, whether or not its tombstone has been synced.
            guard !attribute.value.isEmpty else { return }

            dimensions[attribute.key] = .object([
                Self.valueKey: .string(attribute.value),
                Self.updatedAtKey: .date(attribute.setTime)
            ])
        }

        return records.isEmpty ? [:] : [Self.subscriberAttributesKey: .object(records)]
    }

    private static let subscriberAttributesKey = "subscriber_attributes"
    private static let updatedAtKey = "updated_at"
    private static let valueKey = "value"

}
