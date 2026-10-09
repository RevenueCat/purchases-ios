//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewProviderTests.swift
//
//  Created by Monika on 6/10/2026.

import Combine
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewProviderTests: TestCase {
    func testUpdatesReloadTheRootCustomerInformation() async throws {
        let provider = PreviewProvider()
        let model = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await model.loadScreen()
        let observation = Task { await model.observePreviewUpdates() }
        let before = model.customerInfo
        let next = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let updated = expectation(description: "Preview customer information updated")
        let subscription = model.$customerInfo.filter { $0 == next }.first().sink { _ in updated.fulfill() }
        provider.mock.customerInfo = next
        provider.continuation.yield(next)
        await fulfillment(of: [updated], timeout: 2)
        withExtendedLifetime(subscription) {}
        XCTAssertEqual(model.customerInfo, next)
        XCTAssertNotEqual(before, next)
        observation.cancel()
        await observation.value
    }

    func testDiagnosticReadsDoNotEmitNewUpdates() {
        let provider = PreviewProvider()
        let model = BaseManageSubscriptionViewModel(
            screen: CustomerCenterConfigData.mock().screens[.management]!,
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: provider
        )
        let initialCount = provider.diagnosticCalls
        _ = model.relevantPathsForPurchase
        _ = model.relevantPathsForPurchase
        XCTAssertEqual(provider.diagnosticCalls, initialCount)
        model.purchaseInformation = .subscription
        XCTAssertEqual(provider.diagnosticCalls, initialCount + 1)
    }

    func testDiagnosticsUseTheRenderedResubscribeTitle() throws {
        let provider = PreviewProvider()
        let model = BaseManageSubscriptionViewModel(
            screen: CustomerCenterConfigData.mock().screens[.management]!,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: .mock(isSubscription: true, productType: .autoRenewableSubscription,
                                       isCancelled: true, renewalDate: nil),
            purchasesProvider: provider
        )
        let rendered = try XCTUnwrap(model.relevantPathsForPurchase.first { $0.type == .cancel })
        let diagnostic = try XCTUnwrap(provider.diagnostics.first { $0.pathID == rendered.id })
        XCTAssertEqual(rendered.title, "Resubscribe")
        XCTAssertEqual(diagnostic.title, rendered.title)
    }

    func testProviderCancellationDismissesThePreviewAction() async {
        let provider = PreviewProvider()
        provider.actionError = CancellationError()
        var isPresented = true
        let dismissed = expectation(description: "Cancelled preview action dismissed")
        let view = Text("Preview").modifier(CustomerCenterPreviewActionModifier(
            provider: provider,
            isPresented: Binding(get: { isPresented }, set: {
                isPresented = $0
                if !$0 { dismissed.fulfill() }
            }),
            action: .manageSubscriptions
        ))
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.view.layoutIfNeeded()
        await fulfillment(of: [dismissed], timeout: 2)
        XCTAssertFalse(isPresented)
        XCTAssertEqual(provider.actions.count, 1)
    }

    func testInjectedPaywallPurchasesUsePreviewCustomerInformation() async throws {
        let provider = PreviewProvider()
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

    func testPreviewPurchaseOnlyTreatsRevenueCatCancellationAsCancelled() async {
        let provider = PreviewProvider()
        let model = NoSubscriptionsCardViewModel(screenOffering: nil, purchasesProvider: provider)
        provider.purchaseError = NSError(domain: ErrorCode.errorDomain,
                                         code: ErrorCode.purchaseCancelledError.rawValue)
        let cancelled = await model.performPurchase(packageToPurchase: TestData.packageWithIntroOffer)
        XCTAssertTrue(cancelled.userCancelled)
        XCTAssertNil(cancelled.error)

        provider.purchaseError = NSError(domain: "OtherDomain", code: ErrorCode.purchaseCancelledError.rawValue)
        let failed = await model.performPurchase(packageToPurchase: TestData.packageWithIntroOffer)
        XCTAssertFalse(failed.userCancelled)
        XCTAssertEqual((failed.error as NSError?)?.domain, "OtherDomain")
    }

    func testDiagnosticsUseTheSamePathsAsTheRenderedScreen() {
        let provider = PreviewProvider()
        let config = CustomerCenterConfigData.mock()
        let screen = config.screens[.management]!
        let model = BaseManageSubscriptionViewModel(
            screen: screen,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil),
            purchasesProvider: provider
        )
        let visible = Set(model.relevantPathsForPurchase.map(\.id))
        XCTAssertEqual(Set(provider.diagnostics.filter(\.visible).map(\.pathID)), visible)
        XCTAssertTrue(provider.diagnostics.filter { !visible.contains($0.pathID) }.allSatisfy { !$0.reason.isEmpty })
    }

    func testCustomActionsAndURLsAreIntercepted() async {
        let provider = PreviewProvider()
        let screen = CustomerCenterConfigData.Screen(
            type: .management, title: "Manage", subtitle: nil,
            paths: [], offering: nil)
        let model = BaseManageSubscriptionViewModel(
            screen: screen,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: nil),
            purchasesProvider: provider
        )
        await model.handleHelpPath(.init(
            id: "custom", title: "Custom", type: .customAction, detail: nil,
            customActionIdentifier: "preview-action"
        ))
        await model.handleHelpPath(.init(
            id: "url", title: "URL", url: URL(string: "https://example.com"),
            openMethod: .external, type: .customUrl, detail: nil
        ))
        XCTAssertEqual(provider.actions.count, 2)
        guard case .customAction("preview-action") = provider.actions.first else {
            return XCTFail("Missing custom action")
        }
        guard case .openURL = provider.actions.last else { return XCTFail("Missing URL action") }
    }

}

@available(iOS 15.0, *)
private final class PreviewProvider: CustomerCenterStateTestProvider,
                                     CustomerCenterPreviewProvider, @unchecked Sendable {
    let stream: AsyncStream<CustomerInfo>
    let continuation: AsyncStream<CustomerInfo>.Continuation
    var diagnosticCalls = 0
    var diagnostics: [CustomerCenterPreviewDiagnostic] = []
    var actions: [CustomerCenterPreviewAction] = []
    var actionError: Error?
    override init() {
        (stream, continuation) = AsyncStream.makeStream()
        super.init()
    }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { stream }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {
        actions.append(action)
        if let actionError { throw actionError }
    }
    func onPreviewDiagnostics(_ values: [CustomerCenterPreviewDiagnostic]) {
        diagnosticCalls += 1
        diagnostics = values
    }
}
#endif
