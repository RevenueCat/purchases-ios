//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewActionsTests.swift
//
//  Created by Monika on 2026-10-14.

import Combine
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewActionsTests: TestCase {
    func testStandardProviderKeepsPlatformActionRoutes() async throws {
        let provider = CustomerCenterStateTestProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let detail = SubscriptionDetailViewModel(
            customerInfoViewModel: root, screen: try XCTUnwrap(root.configuration?.screens[.management]),
            showPurchaseHistory: false, showVirtualCurrencies: false, allowsMissingPurchaseAction: false,
            actionWrapper: root.actionWrapper, purchaseInformation: .subscription, purchasesProvider: provider
        )
        detail.didAppear()
        detail.purchaseInformation = .subscription
        XCTAssertNil(detail.previewActions)
        await detail.handleHelpPath(cancelPath)
        XCTAssertTrue(root.manageSubscriptionsSheet)
        await detail.handleHelpPath(.init(id: "change", title: "Change", type: .changePlans, detail: nil))
        XCTAssertTrue(root.changePlansSheet)
    }

    func testListDiagnosticsMatchRenderedPathsAfterSelection() {
        let provider = PreviewProvider()
        let model = RelevantPurchasesListViewModel(
            screen: CustomerCenterConfigData.mock().screens[.management]!,
            actionWrapper: CustomerCenterActionWrapper(), shouldShowSeeAllPurchases: true,
            purchasesProvider: provider
        )
        model.startPublishingPreviewDiagnostics()
        model.purchaseInformation = .subscription
        XCTAssertEqual(Set(provider.diagnostics.filter(\.visible).map(\.pathID)),
                       Set(model.relevantPathsForPurchase.map(\.id)))
        XCTAssertTrue(provider.diagnostics.allSatisfy { $0.productID == nil })
    }

    func testHelpPathFailureReachesPreviewAlertState() async throws {
        let provider = PreviewProvider()
        let model = makeModel(provider)
        provider.actionError = ErrorCode.networkError
        await model.handleHelpPath(cancelPath)
        XCTAssertNotNil(model.previewActions?.failure)
        XCTAssertEqual(model.previewActions?.isRunning, false)
        XCTAssertEqual(provider.actions.count, 1)
    }

    func testCancellationOutcomesDoNotPresentErrors() async {
        let provider = PreviewProvider()
        let model = makeModel(provider)
        for error in [CancellationError() as Error, ErrorCode.purchaseCancelledError as Error] {
            provider.actionError = error
            await model.handleHelpPath(cancelPath)
            XCTAssertNil(model.previewActions?.failure)
            XCTAssertEqual(model.previewActions?.isRunning, false)
        }
        provider.actionError = NSError(domain: "OtherDomain", code: ErrorCode.purchaseCancelledError.rawValue)
        await model.handleHelpPath(cancelPath)
        XCTAssertNotNil(model.previewActions?.failure)
    }

    func testPendingHelpPathRejectsCompetingActions() async {
        let provider = PreviewProvider()
        let model = makeModel(provider)
        let started = expectation(description: "Action started")
        provider.beforeAction = {
            started.fulfill()
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        let action = Task { await model.handleHelpPath(cancelPath) }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertEqual(model.previewActions?.isRunning, true)
        await model.handleHelpPath(cancelPath)
        await model.handleHelpPath(.init(id: "change", title: "Change", type: .changePlans, detail: nil))
        XCTAssertEqual(provider.actions.count, 1)
        model.previewActions?.cancel()
        await action.value
        XCTAssertEqual(model.previewActions?.isRunning, false)
        XCTAssertNil(model.previewActions?.failure)
    }

    func testRemovingViewCancelsPendingActionWithoutReplayingIt() async {
        let provider = PreviewProvider()
        let model = makeModel(provider)
        let started = expectation(description: "Action started")
        let cancelled = expectation(description: "Action cancelled")
        provider.beforeAction = {
            started.fulfill()
            do {
                try await Task.sleep(nanoseconds: 10_000_000_000)
            } catch {
                cancelled.fulfill()
                throw error
            }
        }
        let view = ActiveSubscriptionButtonsView(viewModel: model)
            .modifier(CustomerCenterPreviewActionsModifier(actions: model.previewActions))
        let controller = UIHostingController(rootView: AnyView(view))
        let window = host(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let action = Task { await model.handleHelpPath(cancelPath) }
        await fulfillment(of: [started], timeout: 2)
        controller.rootView = AnyView(EmptyView())
        controller.view.layoutIfNeeded()
        await fulfillment(of: [cancelled], timeout: 2)
        await action.value
        XCTAssertEqual(model.previewActions?.isRunning, false)
        controller.rootView = AnyView(view)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(provider.actions.count, 1)
        XCTAssertNil(model.previewActions?.failure)
    }

    func testLateCancelledActionDoesNotClearNewAction() async throws {
        let provider = PreviewProvider()
        let model = makeModel(provider)
        let started = expectation(description: "First action started")
        var finishFirst: CheckedContinuation<Void, Never>?
        provider.beforeAction = {
            await withCheckedContinuation { continuation in
                finishFirst = continuation
                started.fulfill()
            }
        }
        let first = Task { await model.handleHelpPath(cancelPath) }
        await fulfillment(of: [started], timeout: 2)
        model.previewActions?.cancel()
        let nextStarted = expectation(description: "Second action started")
        provider.beforeAction = {
            nextStarted.fulfill()
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        let second = Task { await model.handleHelpPath(cancelPath) }
        await fulfillment(of: [nextStarted], timeout: 2)
        provider.actionError = ErrorCode.networkError
        try XCTUnwrap(finishFirst).resume()
        await first.value
        XCTAssertEqual(model.previewActions?.isRunning, true)
        XCTAssertNil(model.previewActions?.failure)
        model.previewActions?.cancel()
        await second.value
    }

    func testStreamUpdateDuringActionDoesNotSyncOrEndTheAction() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let detail = SubscriptionDetailViewModel(
            customerInfoViewModel: root, screen: try XCTUnwrap(root.configuration?.screens[.management]),
            showPurchaseHistory: false, showVirtualCurrencies: false, allowsMissingPurchaseAction: false,
            actionWrapper: root.actionWrapper, purchaseInformation: .subscription, purchasesProvider: provider
        )
        let view = SubscriptionDetailView(
            customerInfoViewModel: root, screen: detail.screen, purchaseInformation: .subscription,
            showPurchaseHistory: false, showVirtualCurrencies: false, allowsMissingPurchaseAction: false,
            purchasesProvider: provider, actionWrapper: root.actionWrapper
        )
        let controller = UIHostingController(rootView: view)
        let window = host(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let started = expectation(description: "Action started")
        provider.beforeAction = {
            started.fulfill()
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        let action = Task { await detail.handleHelpPath(cancelPath) }
        await fulfillment(of: [started], timeout: 2)
        let unexpectedSync = expectation(description: "No extra sync")
        unexpectedSync.isInverted = true
        provider.onSync = { unexpectedSync.fulfill() }
        let observation = Task { await root.observePreviewCustomerInfoUpdates() }
        let next = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let updated = expectation(description: "Stream update rendered")
        let subscription = root.$customerInfo.filter { $0 == next }.first().sink { _ in updated.fulfill() }
        provider.mock.customerInfo = next
        provider.continuation.yield(next)
        await fulfillment(of: [updated, unexpectedSync], timeout: 1)
        withExtendedLifetime(subscription) {}
        XCTAssertFalse(root.manageSubscriptionsSheet)
        XCTAssertFalse(root.changePlansSheet)
        XCTAssertEqual(detail.previewActions?.isRunning, true)
        detail.previewActions?.cancel()
        await action.value
        observation.cancel()
        await observation.value
    }

    private var cancelPath: CustomerCenterConfigData.HelpPath {
        .init(id: "cancel", title: "Cancel", type: .cancel, detail: nil)
    }

    private func makeModel(_ provider: PreviewProvider) -> BaseManageSubscriptionViewModel {
        BaseManageSubscriptionViewModel(
            screen: CustomerCenterConfigData.mock().screens[.management]!,
            actionWrapper: CustomerCenterActionWrapper(), purchaseInformation: .subscription,
            purchasesProvider: provider
        )
    }

    private func host<Content: View>(_ controller: UIHostingController<Content>) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 600))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        return window
    }

    func testDiagnosticsAreNotPublishedBeforeViewAppears() {
        let provider = PreviewProvider()
        let model = BaseManageSubscriptionViewModel(
            screen: CustomerCenterConfigData.mock().screens[.management]!,
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: provider
        )
        XCTAssertEqual(provider.diagnosticCalls, 0)
        _ = model.relevantPathsForPurchase
        _ = model.relevantPathsForPurchase
        model.purchaseInformation = .subscription
        XCTAssertEqual(provider.diagnosticCalls, 0)
    }

    func testDetailDiagnosticsFollowScreenLifecycleWithActionsOffscreen() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let title = String(repeating: "Subscription\n", count: 100)
        root.subscriptionsSection = [
            .mock(title: title, isSubscription: true, productType: .autoRenewableSubscription)
        ]
        let appeared = expectation(description: "Detail screen appeared")
        let disappeared = expectation(description: "Detail screen disappeared")
        let view = SubscriptionDetailView(
            customerInfoViewModel: root, screen: try XCTUnwrap(root.configuration?.screens[.management]),
            purchaseInformation: root.subscriptionsSection.first,
            showPurchaseHistory: false, showVirtualCurrencies: false, allowsMissingPurchaseAction: false,
            purchaseObservationMode: .currentPurchase, purchasesProvider: provider, actionWrapper: root.actionWrapper
        )
        let controller = UIHostingController(rootView: AnyView(view
            .onAppear { appeared.fulfill() }
            .onDisappear { disappeared.fulfill() }))
        let window = host(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        await fulfillment(of: [appeared], timeout: 2)

        XCTAssertFalse(provider.diagnostics.isEmpty)
        let cancelPathID = try XCTUnwrap(root.configuration?.screens[.management]?.paths
            .first { $0.type == .cancel }?.id)
        root.subscriptionsSection = [
            .mock(title: title, isSubscription: true, productType: .autoRenewableSubscription,
                  isCancelled: true, renewalDate: nil)
        ]
        root.customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        controller.view.layoutIfNeeded()
        XCTAssertEqual(provider.diagnostics.first { $0.pathID == cancelPathID }?.title, "Resubscribe")

        controller.rootView = AnyView(EmptyView())
        controller.view.layoutIfNeeded()
        await fulfillment(of: [disappeared], timeout: 2)
        let callsAfterDisappearance = provider.diagnosticCalls
        root.subscriptionsSection = []
        root.nonSubscriptionsSection = []
        root.customerInfo = CustomerInfoFixtures.customerInfo(subscriptions: [], entitlements: [])
        XCTAssertEqual(provider.diagnosticCalls, callsAfterDisappearance)

        let reappeared = expectation(description: "Detail screen reappeared")
        controller.rootView = AnyView(view.onAppear { reappeared.fulfill() })
        controller.view.layoutIfNeeded()
        await fulfillment(of: [reappeared], timeout: 2)
        XCTAssertGreaterThan(provider.diagnosticCalls, callsAfterDisappearance)
        XCTAssertTrue(provider.diagnostics.allSatisfy { $0.productID == nil })
    }

    func testListPublishesDiagnosticsWithActionsOffscreen() async throws {
        let provider = PreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        root.subscriptionsSection = (0..<30).map {
            .mock(productIdentifier: "subscription.\($0)", isSubscription: true,
                  productType: .autoRenewableSubscription)
        }
        let appeared = expectation(description: "List screen appeared")
        let screen = try XCTUnwrap(root.configuration?.screens[.management])
        let view = RelevantPurchasesListView(
            customerInfoViewModel: root, screen: screen, shouldShowSeeAllPurchases: false,
            purchasesProvider: provider, actionWrapper: root.actionWrapper
        )
        .onAppear { appeared.fulfill() }
        let window = host(UIHostingController(rootView: view))
        defer { window.isHidden = true; window.rootViewController = nil }
        await fulfillment(of: [appeared], timeout: 2)

        XCTAssertEqual(Set(provider.diagnostics.map(\.pathID)), Set(screen.paths.map(\.id)))
        XCTAssertTrue(provider.diagnostics.allSatisfy { $0.productID == nil })
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
        model.startPublishingPreviewDiagnostics()
        let diagnostic = try XCTUnwrap(provider.diagnostics.first { $0.pathID == rendered.id })
        XCTAssertEqual(rendered.title, "Resubscribe")
        XCTAssertEqual(diagnostic.title, rendered.title)
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
        model.startPublishingPreviewDiagnostics()
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
    var beforeAction: (@MainActor () async throws -> Void)?
    var onSync: (@Sendable () -> Void)?

    override init() {
        var continuation: AsyncStream<CustomerInfo>.Continuation?
        self.stream = AsyncStream { continuation = $0 }
        guard let continuation else {
            fatalError("AsyncStream did not provide a continuation")
        }
        self.continuation = continuation
        super.init()
    }

    override func syncPurchases() async throws -> CustomerInfo {
        onSync?()
        return try await super.syncPurchases()
    }

    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { stream }

    @MainActor func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {
        actions.append(action)
        try await beforeAction?()
        if let actionError { throw actionError }
    }

    func onPreviewDiagnostics(_ values: [CustomerCenterPreviewDiagnostic]) {
        diagnosticCalls += 1
        diagnostics = values
    }
}
#endif
