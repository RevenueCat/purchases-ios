//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewPaywallTests.swift
//
//  Created by Monika on 2026-10-14.

import Combine
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewPaywallTests: TestCase {
    func testGeneralUIPreviewDoesNotEnableCustomerCenterIsolation() {
        let purchases = MockPurchases(
            purchase: { _, _, _ in (nil, TestData.customerInfo, false) },
            restorePurchases: { TestData.customerInfo },
            trackEvent: { _ in },
            customerInfo: { TestData.customerInfo }
        )
        purchases.isUIPreviewMode = true
        let handler = PurchaseHandler(purchases: purchases, eventTracker: .init(purchases: purchases))

        XCTAssertTrue(handler.isUIPreviewMode)
        XCTAssertFalse(handler.isCustomerCenterPreview)
        XCTAssertFalse(PurchaseHandler.mock().isCustomerCenterPreview)
        let isolated = PurchaseHandler.customerCenterPreview(
            provider: PreviewPaywallProvider(),
            performPurchase: { _ in (false, nil) },
            performRestore: { (true, nil) }
        )
        XCTAssertTrue(isolated.isCustomerCenterPreview)
    }

    func testPreviewIntroEligibilityHandlesDuplicatePackages() async {
        let checker = TrialOrIntroEligibilityChecker.producing(eligibility: .eligible)
        let package = TestData.packageWithIntroOffer
        let noIntroPackage = TestData.lifetimePackage

        let result = await checker.eligibility(for: [package, package, noIntroPackage, noIntroPackage])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[package], .eligible)
        XCTAssertEqual(result[noIntroPackage], .noIntroOfferExists)
    }

    func testPreviewCheckoutUsesCurrentProviderIdentityAndEnvironment() throws {
        let provider = PreviewPaywallProvider()
        let handler = PurchaseHandler.customerCenterPreview(
            provider: provider,
            performPurchase: { _ in (false, nil) },
            performRestore: { (true, nil) }
        )
        let component = PaywallComponent.PurchaseButtonComponent(
            stack: .init(components: []),
            action: nil,
            method: .customWebCheckout(.init(customUrl: .init(
                url: "checkout", appUserIDParam: "user", envParam: "env"
            ))),
            name: nil
        )
        let viewModel = try PurchaseButtonComponentViewModel(
            localizationProvider: .init(
                locale: .current,
                localizedStrings: ["checkout": .string("https://example.com/checkout?user=old&env=production")]
            ),
            component: component,
            offering: TestData.offeringWithIntroOffer,
            stackViewModel: .init(
                component: component.stack,
                viewModels: [],
                badgeViewModels: [],
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
            )
        )

        for isSandbox in [true, false] {
            provider.previewAppUserID = "preview customer + \(isSandbox)"
            provider.previewIsSandbox = isSandbox
            let context = handler.webCheckoutContext
            let launch = try XCTUnwrap(viewModel.urlForWebCheckout(
                packageContext: nil, appUserID: context.appUserID, isSandbox: context.isSandbox
            ))
            let queryItems = try XCTUnwrap(URLComponents(url: launch.url, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(queryItems.filter { $0.name == "user" }, [
                URLQueryItem(name: "user", value: provider.appUserID)
            ])
            XCTAssertEqual(queryItems.filter { $0.name == "env" }, [
                URLQueryItem(name: "env", value: isSandbox ? "sandbox" : "production")
            ])
        }
    }

    func testInjectedPaywallPurchasesUsePreviewCustomerInformation() async throws {
        let provider = PreviewPaywallProvider()
        let next = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        let handler = PurchaseHandler.customerCenterPreview(
            provider: provider,
            performPurchase: { _ in
                provider.mock.customerInfo = next
                return (false, nil)
            },
            performRestore: { (true, nil) }
        )
        try await handler.purchase(package: TestData.packageWithIntroOffer)
        XCTAssertEqual(handler.purchaseResult, .purchased(transaction: nil, customerInfo: next))
        XCTAssertTrue(handler.hasPurchasedInSession)
    }

}

@available(iOS 15.0, *)
private final class PreviewPaywallProvider: CustomerCenterStateTestProvider,
                                           CustomerCenterPreviewProvider, @unchecked Sendable {
    var previewAppUserID = "preview"
    var previewIsSandbox = true
    override var appUserID: String { previewAppUserID }
    override var isSandbox: Bool { previewIsSandbox }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { AsyncStream { $0.finish() } }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {}
}
#endif
