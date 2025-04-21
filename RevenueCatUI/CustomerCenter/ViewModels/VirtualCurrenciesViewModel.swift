//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesViewModel.swift
//
//  Created by Will Taylor on 4/21/25.

import Foundation

import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class VirtualCurrenciesViewModel: ObservableObject {

    @Published var viewState: VirtualCurrenciesView.ViewState

    private let isRunningInSwiftUIPreview: Bool

    init(
        viewState: VirtualCurrenciesView.ViewState = .loading,
        purchasesProvider: CustomerCenterPurchasesType,
        isRunningInSwiftUIPreview: Bool = false
    ) {
        self.viewState = viewState
        self.purchasesProvider = purchasesProvider
        self.isRunningInSwiftUIPreview = isRunningInSwiftUIPreview
    }

    private let purchasesProvider: CustomerCenterPurchasesType

    func onAppear() async {
        if isRunningInSwiftUIPreview {
            // We don't want to load data in previews.
            return
        }

        await self.loadData()
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
internal extension VirtualCurrenciesViewModel {

    func loadData() async {
        await MainActor.run {
            self.viewState = .loading
        }

        do {
            let customerInfo = try await self.purchasesProvider.customerInfo()
            let virtualCurrencyBalanceData = self.extractVirtualCurrencyBalanceData(from: customerInfo)

            await MainActor.run {
                self.viewState = .loaded(virtualCurrencyBalanceData)
            }
        } catch {
            await MainActor.run {
                self.viewState = .error
            }
        }
    }

    private func extractVirtualCurrencyBalanceData(
        from customerInfo: RevenueCat.CustomerInfo) -> [VirtualCurrenciesView.VirtualCurrencyBalanceRowData] {
            return customerInfo.virtualCurrencies
                .map {
                    VirtualCurrenciesView.VirtualCurrencyBalanceRowData(
                        code: $0.key, // VC Code
                        balance: $0.value.balance
                    )
                }
                .sorted { $0.balance < $1.balance }
    }
}
