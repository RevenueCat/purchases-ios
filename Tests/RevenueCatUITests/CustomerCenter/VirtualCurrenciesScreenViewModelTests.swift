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

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class VirtualCurrenciesScreenViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.viewState) == .loading
    }

    func testInitialStateWithCustomState() {
        let viewModel = VirtualCurrenciesScreenViewModel(
            viewState: .error,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.viewState) == .error
    }

    func testOnAppearSkipsLoadingInPreview() async {
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: MockCustomerCenterPurchases(),
            isRunningInSwiftUIPreview: true
        )

        await viewModel.onAppear()

        expect(viewModel.viewState) == .loading
    }

    func testLoadDataSuccess() async {
        let customerInfo = CustomerInfoFixtures.customerInfoWithVirtualCurrencies
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onAppear()

        switch viewModel.viewState {
        case .loaded(let virtualCurrencyRowData):
            expect(virtualCurrencyRowData.count) == 4
        default:
            fail("Expected state to be .loaded")
        }
    }

    func testLoadDataEmptyVirtualCurrencies() async {
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [],
            entitlements: [],
            virtualCurrencies: [:]
        )
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onAppear()

        switch viewModel.viewState {
        case .loaded(let data):
            expect(data).to(beEmpty())
        default:
            fail("Expected state to be .loaded with empty data")
        }
    }

    func testLoadDataFailure() async {
        let mockPurchases = MockCustomerCenterPurchases(customerInfoError: error)
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onAppear()

        expect(viewModel.viewState) == .error
    }

    func testVirtualCurrenciesSortedByBalance() async {
        let customerInfo = CustomerInfoFixtures.customerInfoWithVirtualCurrencies
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let viewModel = VirtualCurrenciesScreenViewModel(
            purchasesProvider: mockPurchases
        )

        await viewModel.onAppear()

        switch viewModel.viewState {
        case .loaded(let data):
            expect(data.count) == 4
            expect(data[0].balance) == 400
            expect(data[0].virtualCurrencyCode) == "PLTNM"
            expect(data[1].balance) == 300
            expect(data[1].virtualCurrencyCode) == "BRNZ"
            expect(data[2].balance) == 200
            expect(data[2].virtualCurrencyCode) == "SLV"
            expect(data[3].balance) == 100
            expect(data[3].virtualCurrencyCode) == "GLD"
        default:
            fail("Expected state to be .loaded")
        }
    }
}

#endif
