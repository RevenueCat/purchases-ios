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

    func testPreviewCheckoutWaitsForProviderAndPreventsDuplicateActions() async throws {
        let provider = PreviewPaywallProvider()
        let handler = PurchaseHandler.customerCenterPreview(
            provider: provider, performPurchase: { _ in (false, nil) }, performRestore: { (true, nil) }
        )
        let url = try XCTUnwrap(URL(string: "https://example.com/checkout"))
        let started = expectation(description: "Preview action started")
        let resumeAction = Atomic<CheckedContinuation<Void, Never>?>(nil)
        defer { resumeAction.getAndSet(nil)?.resume() }
        provider.urlAction = { receivedURL in
            XCTAssertEqual(receivedURL, url)
            await withCheckedContinuation { continuation in
                resumeAction.value = continuation
                started.fulfill()
            }
        }
        var checkoutEvents = 0
        let subscription = handler.webCheckoutOpenedPublisher.sink { checkoutEvents += 1 }
        defer { subscription.cancel() }
        let action = Task { try await handler.performCustomerCenterPreviewCheckout(url: url) }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(handler.actionInProgress)
        XCTAssertEqual(checkoutEvents, 0)
        let duplicate = try await handler.performCustomerCenterPreviewCheckout(url: url)
        XCTAssertFalse(duplicate)

        resumeAction.getAndSet(nil)?.resume()
        let completed = try await action.value

        XCTAssertTrue(completed)
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertEqual(checkoutEvents, 1)
    }

    func testFailedPreviewCheckoutPreservesErrorAndClearsBusyState() async throws {
        let provider = PreviewPaywallProvider()
        let error = NSError(domain: "Preview", code: 1)
        provider.urlAction = { _ in throw error }
        let handler = PurchaseHandler.customerCenterPreview(
            provider: provider, performPurchase: { _ in (false, nil) }, performRestore: { (true, nil) }
        )
        var checkoutEvents = 0
        let subscription = handler.webCheckoutOpenedPublisher.sink { checkoutEvents += 1 }
        defer { subscription.cancel() }
        do {
            _ = try await handler.performCustomerCenterPreviewCheckout(
                url: XCTUnwrap(URL(string: "https://example.com/checkout"))
            )
            XCTFail("Expected the provider error")
        } catch let receivedError {
            XCTAssertEqual(receivedError as NSError, error)
        }
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertEqual(checkoutEvents, 0)
    }

    func testCancelledPreviewCheckoutDoesNotSignalCompletion() async throws {
        let provider = PreviewPaywallProvider()
        provider.urlAction = { _ in throw CancellationError() }
        let handler = PurchaseHandler.customerCenterPreview(
            provider: provider, performPurchase: { _ in (false, nil) }, performRestore: { (true, nil) }
        )
        var checkoutEvents = 0
        let subscription = handler.webCheckoutOpenedPublisher.sink { checkoutEvents += 1 }
        defer { subscription.cancel() }
        let completed = try await handler.performCustomerCenterPreviewCheckout(
            url: XCTUnwrap(URL(string: "https://example.com/checkout"))
        )
        XCTAssertFalse(completed)
        XCTAssertFalse(handler.actionInProgress)
        XCTAssertEqual(checkoutEvents, 0)
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
    var urlAction: (@Sendable (URL) async throws -> Void)?
    var previewAppUserID = "preview"
    var previewIsSandbox = true
    override var appUserID: String { previewAppUserID }
    override var isSandbox: Bool { previewIsSandbox }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { AsyncStream { $0.finish() } }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {
        if case let .openURL(url) = action { try await urlAction?(url) }
    }
}
#endif
