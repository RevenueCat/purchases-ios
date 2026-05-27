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

    func testValidateAPIKeyWithApplPlatformSpecificKey() {
        expect(Configuration.validateAndLog(apiKey: "appl_1a2b3c4d5e6f7h")) == .validApplePlatform
    }

    func testValidateAPIKeyWithMacPlatformSpecificKey() {
        expect(Configuration.validateAndLog(apiKey: "mac_1a2b3c4d5e6f7h")) == .validApplePlatform
    }

    func testValidateAPIKeyWithInvalidPlatformKey() {
        expect(Configuration.validateAndLog(apiKey: "goog_1a2b3c4d5e6f7h")) == .otherPlatforms
    }

    func testValidateAPIKeyWithLegacyKey() {
        expect(Configuration.validateAndLog(apiKey: "swRTCezdEzjnJSxdexDNJfcfiFrMXwqZ")) == .legacy
    }

    func testValidateAPIKeyWithTestStoreKey() {
        expect(Configuration.validateAndLog(apiKey: "test_eg2t9g3098bgqqn")) == .simulatedStore
    }

    func testNoObserverModeWithStoreKit1() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(storeKitVersion: .storeKit1)
            .build()

        expect(configuration.observerMode) == false
        expect(configuration.storeKitVersion) == .storeKit1
    }

    func testNoObserverModeWithStoreKit2() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(storeKitVersion: .storeKit2)
            .build()

        expect(configuration.observerMode) == false
        expect(configuration.storeKitVersion) == .storeKit2
    }

    func testPurchasesAreCompletedByMyAppWithStoreKit1() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit1)
            .build()

        expect(configuration.observerMode) == true
        expect(configuration.storeKitVersion) == .storeKit1
    }

    @available(*, deprecated)
    func testPurchasesAreCompletedByMyAppWithStoreKit2() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
            .build()

        expect(configuration.observerMode) == true
        expect(configuration.storeKitVersion) == .storeKit2
    }

    func testDiagnosticsEnabled() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is unavailable for this test")
        }

        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(diagnosticsEnabled: true)
            .build()

        expect(configuration.diagnosticsEnabled) == true
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

    func testAutomaticDeviceIdentifierCollectionEnabledIsTrueByDefault() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .build()
        expect(configuration.automaticDeviceIdentifierCollectionEnabled) == true
    }

    func testAutomaticDeviceIdentifierCollectionEnabledCanBeSet() {
        let configuration = Configuration.Builder(withAPIKey: "test")
            .with(automaticDeviceIdentifierCollectionEnabled: false)
            .build()
        expect(configuration.automaticDeviceIdentifierCollectionEnabled) == false
    }

    // MARK: - Equality

    func testTwoConfigurationsWithIdenticalFieldsAreEqualAndHaveSameHash() {
        let lhs = Self.fullyConfiguredBuilder().build()
        let rhs = Self.fullyConfiguredBuilder().build()

        expect(lhs) == rhs
        expect(lhs.hashValue) == rhs.hashValue
    }

    func testDifferentApiKeyIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "key_a").build()
        let rhs = Configuration.Builder(withAPIKey: "key_b").build()

        expect(lhs) != rhs
    }

    func testDifferentAppUserIDIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(appUserID: "user_a").build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(appUserID: "user_b").build()

        expect(lhs) != rhs
    }

    func testDifferentObserverModeIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test")
            .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
            .build()
        let rhs = Configuration.Builder(withAPIKey: "test")
            .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
            .build()

        expect(lhs) != rhs
    }

    func testDifferentStoreKitVersionIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(storeKitVersion: .storeKit1).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(storeKitVersion: .storeKit2).build()

        expect(lhs) != rhs
    }

    func testDifferentDangerousSettingsIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test")
            .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
            .build()
        let rhs = Configuration.Builder(withAPIKey: "test")
            .with(dangerousSettings: DangerousSettings(autoSyncPurchases: false))
            .build()

        expect(lhs) != rhs
    }

    func testDifferentNetworkTimeoutIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(networkTimeout: 5).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(networkTimeout: 10).build()

        expect(lhs) != rhs
    }

    func testDifferentStoreKit1TimeoutIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(storeKit1Timeout: 5).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(storeKit1Timeout: 10).build()

        expect(lhs) != rhs
    }

    func testDifferentPlatformInfoIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test")
            .with(platformInfo: .init(flavor: "flutter", version: "1.0"))
            .build()
        let rhs = Configuration.Builder(withAPIKey: "test")
            .with(platformInfo: .init(flavor: "react-native", version: "1.0"))
            .build()

        expect(lhs) != rhs
    }

    func testDifferentEntitlementVerificationModeIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test")
            .with(entitlementVerificationMode: .disabled)
            .build()
        let rhs = Configuration.Builder(withAPIKey: "test")
            .with(entitlementVerificationMode: .informational)
            .build()

        expect(lhs) != rhs
    }

    func testDifferentShowStoreMessagesAutomaticallyIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(showStoreMessagesAutomatically: true).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(showStoreMessagesAutomatically: false).build()

        expect(lhs) != rhs
    }

    func testDifferentPreferredLocaleIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(preferredUILocaleOverride: "en-US").build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(preferredUILocaleOverride: "fr-FR").build()

        expect(lhs) != rhs
    }

    func testDifferentAutomaticDeviceIdentifierCollectionEnabledIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test")
            .with(automaticDeviceIdentifierCollectionEnabled: true).build()
        let rhs = Configuration.Builder(withAPIKey: "test")
            .with(automaticDeviceIdentifierCollectionEnabled: false).build()

        expect(lhs) != rhs
    }

    func testDifferentDiagnosticsEnabledIsNotEqual() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is unavailable for this test")
        }

        let lhs = Configuration.Builder(withAPIKey: "test").with(diagnosticsEnabled: true).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(diagnosticsEnabled: false).build()

        expect(lhs) != rhs
    }

    // MARK: - UserDefaults equality (reference identity)

    func testNilUserDefaultsAreEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").build()
        let rhs = Configuration.Builder(withAPIKey: "test").build()

        expect(lhs) == rhs
    }

    func testStandardUserDefaultsAreEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: .standard).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: .standard).build()

        expect(lhs) == rhs
    }

    func testSameCustomUserDefaultsInstanceIsEqual() {
        let shared = UserDefaults(suiteName: "rc_eq_test_shared")!
        defer { shared.removePersistentDomain(forName: "rc_eq_test_shared") }

        let lhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: shared).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: shared).build()

        expect(lhs) == rhs
    }

    func testDifferentCustomUserDefaultsInstancesAreNotEqual() {
        // Distinct `UserDefaults` instances are considered a real configuration change,
        // even if they ultimately point to the same underlying suite.
        let suiteA = UserDefaults(suiteName: "rc_eq_test_a")!
        let suiteB = UserDefaults(suiteName: "rc_eq_test_b")!
        defer {
            suiteA.removePersistentDomain(forName: "rc_eq_test_a")
            suiteB.removePersistentDomain(forName: "rc_eq_test_b")
        }

        let lhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: suiteA).build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: suiteB).build()

        expect(lhs) != rhs
    }

    func testNilVsStandardUserDefaultsIsNotEqual() {
        let lhs = Configuration.Builder(withAPIKey: "test").build()
        let rhs = Configuration.Builder(withAPIKey: "test").with(userDefaults: .standard).build()

        expect(lhs) != rhs
    }

    // MARK: - Helpers

    /// A builder pre-populated on every comparable field so equality tests for individual
    /// fields can vary one field at a time and rely on the rest matching by default.
    private static func fullyConfiguredBuilder() -> Configuration.Builder {
        return Configuration.Builder(withAPIKey: "test")
            .with(appUserID: "user")
            .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)
            .with(userDefaults: .standard)
            .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
            .with(networkTimeout: 5)
            .with(storeKit1Timeout: 5)
            .with(platformInfo: .init(flavor: "flutter", version: "1.0"))
            .with(showStoreMessagesAutomatically: true)
            .with(entitlementVerificationMode: .disabled)
            .with(preferredUILocaleOverride: "en-US")
            .with(automaticDeviceIdentifierCollectionEnabled: true)
    }

}
