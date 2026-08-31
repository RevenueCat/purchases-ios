//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberDimensionsProvider.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

import Foundation

/// Supplies the latest dimensions delivered alongside the subscriber as root-level rule values.
struct SubscriberDimensionsProvider: DimensionProvider {

    let name = "subscriber_dimensions"

    private let cachedDimensionsProvider: @Sendable () throws -> Data?

    init(
        deviceCache: DeviceCache,
        currentUserProvider: CurrentUserProvider
    ) {
        self.init {
            deviceCache.cachedSubscriberDimensionsData(appUserID: currentUserProvider.currentAppUserID)
        }
    }

    init(cachedDimensionsProvider: @escaping @Sendable () throws -> Data?) {
        self.cachedDimensionsProvider = cachedDimensionsProvider
    }

    func dimensions(at _: Date) -> [String: DimensionValue] {
        do {
            guard let data = try self.cachedDimensionsProvider() else { return [:] }
            let values = try JSONDecoder.default.decode([String: AnyDecodable].self, from: data)

            return values.compactMapValues(\AnyDecodable.dimensionValue)
        } catch {
            Logger.warn(Strings.remoteConfig.subscriberDimensionsUnavailable(error))
            return [:]
        }
    }

}
