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

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
@available(iOS 15.0, *)
@MainActor
final class CustomerCenterPreviewProviderTests: TestCase {
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

}

@available(iOS 15.0, *)
private final class PreviewProvider: CustomerCenterStateTestProvider,
                                     CustomerCenterPreviewProvider, @unchecked Sendable {
    let stream: AsyncStream<CustomerInfo>
    let continuation: AsyncStream<CustomerInfo>.Continuation
    var actions: [CustomerCenterPreviewAction] = []
    override init() {
        (stream, continuation) = AsyncStream.makeStream()
        super.init()
    }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { stream }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws { actions.append(action) }
}
#endif
