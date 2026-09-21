//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesUIServiceStrippedTests.swift
//

@_spi(Internal) import RevenueCat
import RevenueCatUI
import XCTest

/// Verifies `RCPurchasesUIService` survives Release dead-stripping / symbol stripping.
///
/// Run with the `RevenueCatUI-Stripped` scheme (Release). This target must not
/// mention `PurchasesUIService` by its Swift name: a Swift reference would keep
/// the class even if the ObjC keep-alive path failed, hiding the production bug.
///
/// `Purchases` looks the class up with `NSClassFromString("RCPurchasesUIService")`.
/// SPM links RevenueCatUI statically, so the class is only in the binary when a
/// public RevenueCatUI entry point is reachable.
///
/// Release modules are built without `-enable-testing`, so this file uses public
/// / SPI APIs only — no `@testable import`.
final class PurchasesUIServiceStrippedTests: XCTestCase {

    func testServiceSurvivesSymbolStrippingAndIsDiscoverable() throws {
        try skipIfNoPublicKeepAlive()

        self.retainPublicRevenueCatUIEntryPoints()

        // Must match `PurchasesConfiguredNotifier.serviceClassNames`.
        let className = "RCPurchasesUIService"
        let service = NSClassFromString(className)

        XCTAssertNotNil(
            service,
            "\(className) was stripped from the binary. Purchases.configure cannot notify RevenueCatUI."
        )
        XCTAssertNotNil(
            service as? PurchasesPostConfigurationStep.Type,
            "\(className) is present but does not conform to PurchasesPostConfigurationStep."
        )

        _ = Purchases.configure(withAPIKey: "test_purchases_ui_service_stripped")

        XCTAssertNotNil(
            NSClassFromString(className) as? PurchasesPostConfigurationStep.Type,
            "\(className) must still be discoverable after Purchases.configure."
        )
    }

    /// Touches the same public types an app would. That keeps `RCPurchasesUIService`
    /// through `activateIfNeeded()` without naming the class in this test target.
    private func retainPublicRevenueCatUIEntryPoints() {
        #if os(tvOS)
        return
        #else
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
            _ = PaywallView()
            #if os(iOS)
            _ = CustomerCenterView()
            #endif
        }
        #endif
    }

    private func skipIfNoPublicKeepAlive() throws {
        #if os(tvOS)
        throw XCTSkip("RevenueCatUI has no public keep-alive for RCPurchasesUIService on tvOS.")
        #else
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
            return
        }
        throw XCTSkip("PaywallView requires iOS 15 / macOS 12 / watchOS 8.")
        #endif
    }

}
