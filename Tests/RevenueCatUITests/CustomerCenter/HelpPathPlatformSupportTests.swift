//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HelpPathPlatformSupportTests.swift
//
//  Created by Asier G. Morato on 14/9/26.

import Nimble
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class HelpPathPlatformSupportTests: TestCase {

    private typealias PathType = CustomerCenterConfigData.HelpPath.PathType

    func testRefundRequestIsOnlySupportedWhereStoreKitOffersTheRefundSheet() {
        #if os(macOS)
        expect(PathType.refundRequest.isSupportedOnCurrentPlatform) == false
        #else
        expect(PathType.refundRequest.isSupportedOnCurrentPlatform) == true
        #endif
    }

    func testChangePlansNeedsSubscriptionStoreView() {
        #if os(macOS)
        // Derived from the running OS, not from the same `#available` the implementation uses,
        // so the test would catch the implementation checking the wrong version.
        let isMacOS14OrLater = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14

        expect(PathType.changePlans.isSupportedOnCurrentPlatform) == isMacOS14OrLater
        #else
        expect(PathType.changePlans.isSupportedOnCurrentPlatform) == true
        #endif
    }

    func testEveryOtherPathIsSupportedEverywhere() {
        let others: [PathType] = [.missingPurchase, .cancel, .customUrl, .customAction]

        for type in others {
            expect(type.isSupportedOnCurrentPlatform).to(beTrue(), description: "\(type)")
        }
    }

    @MainActor
    func testTheManagementScreenOffersTheRefundRequestOnlyWhereItIsSupported() {
        let screen = CustomerCenterConfigData.mock(
            lastPublishedAppVersion: "1.0.0",
            refundWindowDuration: .forever
        ).screens[.management]!

        let viewModel = BaseManageSubscriptionViewModel(
            screen: screen,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: .subscription,
            purchasesProvider: MockCustomerCenterPurchases()
        )
        let types = viewModel.relevantPathsForPurchase.map(\.type)

        #if os(macOS)
        expect(types).toNot(contain(.refundRequest))
        #else
        expect(types).to(contain(.refundRequest))
        #endif
        expect(types).to(contain(.cancel))
    }

}

#endif
