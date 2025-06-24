//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesScreenViewModelTests.swift
//
//  Created by Will Taylor on 4/23/25.

import Foundation
import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

// swiftlint:disable:next file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
// swiftlint:disable:next type_name
final class VirtualCurrencyBalancesScreenViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.viewState).to(equal(.loading))
    }

    func testInitialStateWithCustomState() {
        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            viewState: .error,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.viewState).to(equal(.error))
    }

    func testLoadDataSuccess() async {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        )
        mockPurchases.virtualCurrenciesResult = .success(VirtualCurrenciesFixtures.fourVirtualCurrencies)

        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onViewAppeared()
        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(1))

        switch viewModel.viewState {
        case .loaded(let virtualCurrencyRowData):
            expect(virtualCurrencyRowData.count).to(equal(4))
        default:
            fail("Expected state to be .loaded")
        }
    }

    func testLoadDataInvalidatesVirtualCurrencyCache() async {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        )
        mockPurchases.virtualCurrenciesResult = .success(VirtualCurrenciesFixtures.fourVirtualCurrencies)

        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onViewAppeared()

        expect(mockPurchases.invalidateVirtualCurrenciesCacheCallCount).to(equal(1))
        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(1))
    }

    func testLoadDataEmptyVirtualCurrencies() async {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        )
        mockPurchases.virtualCurrenciesResult = .success(VirtualCurrenciesFixtures.noVirtualCurrencies)
        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onViewAppeared()
        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(1))

        switch viewModel.viewState {
        case .loaded(let data):
            expect(data).to(beEmpty())
        default:
            fail("Expected state to be .loaded with empty data")
        }
    }

    func testLoadDataFailure() async {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        )
        mockPurchases.virtualCurrenciesResult = .failure(NSError(domain: "error", code: -1))
        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onViewAppeared()

        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(1))
        expect(viewModel.viewState).to(equal(.error))
    }

    func testVirtualCurrenciesSortedByBalance() async {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        )
        mockPurchases.virtualCurrenciesResult = .success(VirtualCurrenciesFixtures.fourVirtualCurrencies)
        let viewModel = VirtualCurrencyBalancesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onViewAppeared()

        switch viewModel.viewState {
        case .loaded(let data):
            expect(data.count).to(equal(4))
            expect(data[0].balance).to(equal(400))
            expect(data[0].virtualCurrencyCode).to(equal("PLTNM"))
            expect(data[1].balance).to(equal(300))
            expect(data[1].virtualCurrencyCode).to(equal("BRNZ"))
            expect(data[2].balance).to(equal(200))
            expect(data[2].virtualCurrencyCode).to(equal("SLV"))
            expect(data[3].balance).to(equal(100))
            expect(data[3].virtualCurrencyCode).to(equal("GLD"))
        default:
            fail("Expected state to be .loaded")
        }
    }
}

#endif
