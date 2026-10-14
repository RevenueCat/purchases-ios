//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPreviewLoadingTests.swift
//
//  Created by Monika on 2026-10-14.

import Combine
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewLoadingTests: TestCase {
    func testOlderRestoreLoadCannotOverwriteNewerPreviewUpdate() async throws {
        try await assertOlderRestoreLoadCannotOverwriteNewerUpdate(failingOlderLoad: false)
    }

    func testOlderRestoreErrorCannotOverwriteNewerPreviewUpdate() async throws {
        try await assertOlderRestoreLoadCannotOverwriteNewerUpdate(failingOlderLoad: true)
    }

    private func assertOlderRestoreLoadCannotOverwriteNewerUpdate(failingOlderLoad: Bool) async throws {
        let provider = OverlappingPreviewProvider()
        let root = CustomerCenterViewModel(uiPreviewPurchaseProvider: provider)
        await root.loadScreen()
        let original = try XCTUnwrap(root.configuration)
        XCTAssertNotNil(root.onUpdateAppClick)
        let olderLoadSuspended = expectation(description: "Restore reload is suspended")
        let resumeOlderLoad = Atomic<CheckedContinuation<Void, Never>?>(nil)
        let didSuspend = Atomic(false)
        provider.beforeReturningConfiguration = {
            if !didSuspend.getAndSet(true) {
                await withCheckedContinuation { continuation in
                    resumeOlderLoad.value = continuation
                    olderLoadSuspended.fulfill()
                }
                if failingOlderLoad {
                    throw NSError(domain: "OlderPreviewLoad", code: 1)
                }
            }
        }
        defer { resumeOlderLoad.getAndSet(nil)?.resume() }

        root.onDismissRestorePurchasesAlert()
        let restoreLoad = try XCTUnwrap(root.currentTask)
        await fulfillment(of: [olderLoadSuspended], timeout: 2)

        provider.mock.loadCustomerCenterResult = .success(CustomerCenterConfigData(
            screens: original.screens, appearance: original.appearance, localization: original.localization,
            support: original.support, changePlans: original.changePlans,
            lastPublishedAppVersion: original.lastPublishedAppVersion, productId: nil
        ))
        let newerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        let newerLoadPublished = expectation(description: "Stream update published before restore reload")
        let subscription = root.$customerInfo.sink { if $0 == newerInfo { newerLoadPublished.fulfill() } }
        defer { subscription.cancel() }
        let observation = Task { await root.observePreviewCustomerInfoUpdates() }
        defer { observation.cancel() }
        provider.continuation.yield(newerInfo)
        await fulfillment(of: [newerLoadPublished], timeout: 2)
        XCTAssertEqual(root.state, .success)
        XCTAssertNil(root.onUpdateAppClick)

        resumeOlderLoad.getAndSet(nil)?.resume()
        await restoreLoad.value

        XCTAssertEqual(root.customerInfo, newerInfo)
        XCTAssertEqual(root.subscriptionsSection.map(\.productIdentifier), ["rc_promo_pro_cat_lifetime"])
        XCTAssertTrue(root.nonSubscriptionsSection.isEmpty)
        XCTAssertNil(root.configuration?.productId)
        XCTAssertNil(root.onUpdateAppClick)
        XCTAssertEqual(root.state, .success)
        observation.cancel()
        await observation.value
    }
}

@available(iOS 15.0, *)
private final class OverlappingPreviewProvider: CustomerCenterStateTestProvider,
                                               CustomerCenterPreviewProvider, @unchecked Sendable {
    let stream: AsyncStream<CustomerInfo>
    let continuation: AsyncStream<CustomerInfo>.Continuation
    var beforeReturningConfiguration: (@Sendable () async throws -> Void)?

    override init() {
        (stream, continuation) = AsyncStream.makeStream()
        super.init()
    }

    override func loadCustomerCenter() async throws -> CustomerCenterConfigData {
        let configuration = try await super.loadCustomerCenter()
        try await beforeReturningConfiguration?()
        return configuration
    }

    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { stream }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {}
}
#endif
