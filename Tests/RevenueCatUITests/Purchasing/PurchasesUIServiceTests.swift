//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesUIServiceTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

class PurchasesUIServiceTests: TestCase {

    override func setUp() {
        super.setUp()

        Purchases.clearSingleton()
        PurchasesUIService.resetForTests()
    }

    override func tearDown() {
        Purchases.clearSingleton()
        PurchasesUIService.resetForTests()

        super.tearDown()
    }

    func testServiceConformsAndIsDiscoverable() {
        // swiftlint:disable:next force_unwrapping
        let service: AnyClass? = NSClassFromString(PurchasesConfiguredNotifier.serviceClassNames.first!)

        expect(service).toNot(beNil())
        expect(service as? PurchasesPostConfigurationStep.Type).toNot(beNil())
    }

    func testConfigurePingsRevenueCatUIOnce() {
        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service")
        expect(PurchasesUIService.configureCallCount) == 1

        // same config: dedup must not ping again
        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service")
        expect(PurchasesUIService.configureCallCount) == 1
    }

    func testActivateIfNeededDoesNothingWhenPurchasesIsNotConfigured() {
        PurchasesUIService.activateIfNeeded()
        expect(PurchasesUIService.configureCallCount) == 0
    }

    func testActivateIfNeededReplaysWhenPurchasesAlreadyConfigured() {
        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service")
        expect(PurchasesUIService.configureCallCount) == 1

        // Simulate RevenueCatUI loading after configuration: the class is now
        // present, but its once-only flag has not run yet.
        PurchasesUIService.resetForTests()
        expect(PurchasesUIService.configureCallCount) == 0

        PurchasesUIService.activateIfNeeded()
        expect(PurchasesUIService.configureCallCount) == 1
    }

    func testPaywallViewConfigurationActivateIfNeededWhenConfigured() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service")
        PurchasesUIService.resetForTests()

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            _ = PaywallViewConfiguration(purchaseHandler: .default())
        }

        expect(PurchasesUIService.configureCallCount) == 1
    }

    #if os(iOS)
    func testCustomerCenterViewActivateIfNeededWhenConfigured() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service")
        PurchasesUIService.resetForTests()

        if #available(iOS 15.0, *) {
            _ = CustomerCenterView()
        }

        expect(PurchasesUIService.configureCallCount) == 1
    }
    #endif

}
