//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestorePurchasesAlertViewModelTests.swift
//
//  Created by Cesar de la Vega on 2/4/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class RestorePurchasesAlertViewModelTests: TestCase {

    func testSucessfulRestoreRefreshesCustomerCenter() async {
        let mockPurchases = MockCustomerCenterPurchases()
        mockPurchases.restorePurchasesResult = .success(CustomerInfoFixtures.customerInfoWithAppleSubscriptions)

        let viewModel = RestorePurchasesAlertViewModel(
            purchasesProvider: mockPurchases,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.performRestore()
        expect(mockPurchases.loadCustomerCenterCallCount) == 1
    }

    func testUnSucessfulRestoreRefreshesCustomerCenter() async {
        let mockPurchases = MockCustomerCenterPurchases()

        let viewModel = RestorePurchasesAlertViewModel(
            purchasesProvider: mockPurchases,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.performRestore()
        expect(mockPurchases.loadCustomerCenterCallCount) == 0
    }

}

#endif
