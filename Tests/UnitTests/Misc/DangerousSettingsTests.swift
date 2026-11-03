//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DangerousSettingsTests.swift
//
//  Created by Antonio Pallares on 17/5/26.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class DangerousSettingsTests: TestCase {

    // MARK: - Equality

    func testTwoDefaultDangerousSettingsAreEqual() {
        expect(DangerousSettings()) == DangerousSettings()
    }

    func testSameFieldsAreEqualAndHaveSameHash() {
        let lhs = DangerousSettings(autoSyncPurchases: false)
        let rhs = DangerousSettings(autoSyncPurchases: false)

        expect(lhs) == rhs
        expect(lhs.hashValue) == rhs.hashValue
    }

    func testDifferentAutoSyncPurchasesIsNotEqual() {
        expect(DangerousSettings(autoSyncPurchases: true))
            != DangerousSettings(autoSyncPurchases: false)
    }

    func testDifferentCustomEntitlementComputationIsNotEqual() {
        let withComputation = DangerousSettings(autoSyncPurchases: true, customEntitlementComputation: true)
        let withoutComputation = DangerousSettings(autoSyncPurchases: true, customEntitlementComputation: false)

        expect(withComputation) != withoutComputation
    }

    func testDifferentUIPreviewModeIsNotEqual() {
        expect(DangerousSettings(uiPreviewMode: true))
            != DangerousSettings(uiPreviewMode: false)
    }

    func testDifferentForceAllowTestStoreInReleaseBuildsIsNotEqual() {
        expect(DangerousSettings(autoSyncPurchases: true, forceAllowTestStoreInReleaseBuilds: true))
            != DangerousSettings(autoSyncPurchases: true, forceAllowTestStoreInReleaseBuilds: false)
    }

    func testInternalSettingsAreExcludedFromEquality() {
        let defaultInternal: InternalDangerousSettingsType = DangerousSettings.Internal.default
        let customInternal: InternalDangerousSettingsType = DangerousSettings.Internal(enableReceiptFetchRetry: true)

        let lhs = DangerousSettings(autoSyncPurchases: true, internalSettings: defaultInternal)
        let rhs = DangerousSettings(autoSyncPurchases: true, internalSettings: customInternal)

        expect(lhs) == rhs
        expect(lhs.hashValue) == rhs.hashValue
    }

    // MARK: - forceAllowTestStoreInReleaseBuilds

    func testForceAllowTestStoreInReleaseBuildsIsDisabledByDefault() {
        expect(DangerousSettings().forceAllowTestStoreInReleaseBuilds) == false
        expect(DangerousSettings(autoSyncPurchases: false).forceAllowTestStoreInReleaseBuilds) == false
        expect(DangerousSettings(uiPreviewMode: true).forceAllowTestStoreInReleaseBuilds) == false
    }

    func testForceAllowTestStoreInReleaseBuildsCanBeEnabled() {
        let settings = DangerousSettings(autoSyncPurchases: false, forceAllowTestStoreInReleaseBuilds: true)

        expect(settings.forceAllowTestStoreInReleaseBuilds) == true
        expect(settings.autoSyncPurchases) == false
        expect(settings.uiPreviewMode) == false
        expect(settings.customEntitlementComputation) == false
    }

}

final class SimulatedHostFailuresTests: TestCase {

    private static let primaryHost = "api.revenuecat.com"
    private static let backupHost = "api.rc-backup.com"

    func testNoneModeFailsNoHost() {
        expect(SimulatedHostFailures.Mode.none.hostFailures) == SimulatedHostFailures.none
    }

    func testPrimaryUnreachableModeTakesThePrimarySourceDown() {
        expect(SimulatedHostFailures.Mode.primaryUnreachable.hostFailures) == .init(
            serverErrorHosts: [],
            unreachableHosts: [Self.primaryHost]
        )
    }

    func testPrimaryServerErrorModeKeepsThePrimarySourceHealthy() {
        expect(SimulatedHostFailures.Mode.primaryServerError.hostFailures) == .init(
            serverErrorHosts: [Self.primaryHost],
            unreachableHosts: []
        )
    }

    func testAllUnreachableModeTakesEverySourceDown() {
        expect(SimulatedHostFailures.Mode.allUnreachable.hostFailures) == .init(
            serverErrorHosts: [],
            unreachableHosts: [Self.primaryHost, Self.backupHost]
        )
    }

    func testOnlyUnreachableHostsFailTheirHealthChecks() throws {
        let strategy = ForceServerErrorStrategy.simulating {
            .init(serverErrorHosts: ["erroring.rc-test.com"], unreachableHosts: ["down.rc-test.com"])
        }

        expect(strategy.healthCheckAction(try XCTUnwrap(URL(string: "https://down.rc-test.com/")))) == .fakeUnhealthy
        expect(strategy.healthCheckAction(try XCTUnwrap(URL(string: "https://erroring.rc-test.com/"))))
            == .performHealthCheck
        expect(strategy.healthCheckAction(try XCTUnwrap(URL(string: "https://other.rc-test.com/"))))
            == .performHealthCheck
    }

    func testHealthChecksUseTheFailuresCurrentAtCheckTime() throws {
        let failures: Atomic<SimulatedHostFailures> = .init(SimulatedHostFailures.none)
        let strategy = ForceServerErrorStrategy.simulating { failures.value }
        let url = try XCTUnwrap(URL(string: "https://down.rc-test.com/"))

        expect(strategy.healthCheckAction(url)) == .performHealthCheck

        failures.value = SimulatedHostFailures(serverErrorHosts: [], unreachableHosts: ["down.rc-test.com"])

        expect(strategy.healthCheckAction(url)) == .fakeUnhealthy
    }

}
