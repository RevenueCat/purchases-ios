//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSDKSettingsConfigProvider.swift
//
//  Created by Antonio Pallares on 24/9/26.

import Foundation
@testable import RevenueCat

final class MockSDKSettingsConfigProvider: SDKSettingsConfigProviderType {

    var stubbedSettings = SDKSettings()
    var stubbedCachedSettings: SDKSettings?

    weak var delegate: SDKSettingsConfigProviderDelegate?

    private(set) var invokedSettingsCount: Int = 0

    func settings() async -> SDKSettings {
        self.invokedSettingsCount += 1
        return self.stubbedSettings
    }

    func cachedSettings() -> SDKSettings? {
        return self.stubbedCachedSettings
    }

    func remoteConfigStateDidChange(generation _: Int) {}

}

extension MockSDKSettingsConfigProvider: @unchecked Sendable {}

extension SDKSettings {

    static func allowingExternalPurchases(in storefronts: Set<String>, reportingTokens: Bool) -> SDKSettings {
        return .init(
            externalPurchases: .init(appStore: .init(storefrontsAllowedWithoutStoreEligibility: storefronts,
                                                     tokenReportingEnabled: reportingTokens))
        )
    }

}
