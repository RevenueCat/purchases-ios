//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfigurationTests.swift
//
//  Created by Nacho Soto on 5/16/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ConfigurationTests: TestCase {

    func testValidateAPIKeyWithPlatformSpecificKey() {
        expect(Configuration.validate(apiKey: "appl_1a2b3c4d5e6f7h")) == .validApplePlatform
    }

    func testValidateAPIKeyWithInvalidPlatformKey() {
        expect(Configuration.validate(apiKey: "goog_1a2b3c4d5e6f7h")) == .otherPlatforms
    }

    func testValidateAPIKeyWithLegacyKey() {
        expect(Configuration.validate(apiKey: "swRTCezdEzjnJSxdexDNJfcfiFrMXwqZ")) == .legacy
    }

    func testStoreKitVersionUsesStoreKit1ByDefault() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .build()

        expect(configuration.storeKitVersion) == .default
    }

    @available(*, deprecated)
    func testLegacyFlagSetsStoreKitVersionWhenStoreKit2Enabled() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(usesStoreKit2IfAvailable: true)
            .build()

        expect(configuration.storeKitVersion) == .storeKit2
    }

    @available(*, deprecated)
    func testLegacyFlagSetsStoreKitVersionWhenStoreKit1Enabled() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(usesStoreKit2IfAvailable: false)
            .build()

        expect(configuration.storeKitVersion) == .default
    }

}
