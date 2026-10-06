//
//  SubscriberDimensionsStore.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 10/2/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

protocol SubscriberDimensionsStoreType: Sendable {

    func store(_ customerInfo: CustomerInfo, appUserID: String)
    func dimensions(appUserID: String) -> SubscriberDimensions?
    func discard(appUserID: String, ifNotNewerThan supersededAt: UInt64)

}

/// Persists the timestamped subscriber dimensions returned by `POST /receipts`.
final class SubscriberDimensionsStore: SubscriberDimensionsStoreType, @unchecked Sendable {

    private let deviceCache: DeviceCache

    init(deviceCache: DeviceCache) {
        self.deviceCache = deviceCache
    }

    func store(_ customerInfo: CustomerInfo, appUserID: String) {
        let rawData = customerInfo.rawData
        guard rawData[Self.dimensionsKey] != nil || rawData[Self.asOfKey] != nil else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: rawData)
            let parsed = try JSONDecoder.default.decode(SubscriberDimensions.self, from: data)
            guard let dimensions = rawData[Self.dimensionsKey] as? [String: Any] else { return }

            self.deviceCache.cache(
                subscriberDimensions: try JSONSerialization.data(withJSONObject: dimensions),
                asOf: parsed.asOf,
                appUserID: appUserID
            )
        } catch {
            Logger.warn(Strings.localRules.subscriberDimensionsUnavailable(error))
        }
    }

    func dimensions(appUserID: String) -> SubscriberDimensions? {
        do {
            guard let cached = self.deviceCache.cachedSubscriberDimensions(appUserID: appUserID) else {
                return nil
            }
            let values = try JSONDecoder.default.decode([String: AnyDecodable].self, from: cached.data)

            return .init(
                values: values.compactMapValues(\AnyDecodable.dimensionValue),
                asOf: cached.asOf
            )
        } catch {
            Logger.warn(Strings.localRules.subscriberDimensionsUnavailable(error))
            return nil
        }
    }

    func discard(appUserID: String, ifNotNewerThan supersededAt: UInt64) {
        self.deviceCache.clearSubscriberDimensions(appUserID: appUserID, ifNotNewerThan: supersededAt)
    }

    private static let dimensionsKey = "dimensions"
    private static let asOfKey = "as_of"

}
