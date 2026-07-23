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

    func testAutoSyncPurchasesAndUseWorkflowsCanBeSetIndependently() {
        let settings = DangerousSettings(autoSyncPurchases: false, useWorkflows: true)

        expect(settings.autoSyncPurchases) == false
        expect(settings.useWorkflows) == true
    }

    func testConsolidatedInitSetsAllThreeFlagsIndependently() {
        let settings = DangerousSettings(autoSyncPurchases: false, uiPreviewMode: true, useWorkflows: true)

        expect(settings.autoSyncPurchases) == false
        expect(settings.uiPreviewMode) == true
        expect(settings.useWorkflows) == true
    }

    func testInternalSettingsAreExcludedFromEquality() {
        let defaultInternal: InternalDangerousSettingsType = DangerousSettings.Internal.default
        let customInternal: InternalDangerousSettingsType = DangerousSettings.Internal(enableReceiptFetchRetry: true)

        let lhs = DangerousSettings(autoSyncPurchases: true, internalSettings: defaultInternal)
        let rhs = DangerousSettings(autoSyncPurchases: true, internalSettings: customInternal)

        expect(lhs) == rhs
        expect(lhs.hashValue) == rhs.hashValue
    }

    // MARK: - Internal settings

    func testUsesRemoteConfigAPISourcesIsDisabledByDefault() {
        expect(DangerousSettings.Internal.default.usesRemoteConfigAPISources) == false
    }

    func testUsesRemoteConfigAPISourcesCanBeEnabled() {
        let internalSettings = DangerousSettings.Internal(usesRemoteConfigAPISources: true)
        expect(internalSettings.usesRemoteConfigAPISources) == true
    }

}
