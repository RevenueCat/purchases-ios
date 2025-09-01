//
//  NoSubscriptionsCardViewModel.swift
//  RevenueCatUI
//
//  Created by Facundo Menzella on 11/8/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class NoSubscriptionsCardViewModel: ObservableObject {

    @Published var offering: Offering?
    @Published var isLoadingOffering = true
    @Published var showOffering = false

    private let screenOffering: CustomerCenterConfigData.ScreenOffering?
    private let purchasesProvider: CustomerCenterPurchasesType

    init(
        screenOffering: CustomerCenterConfigData.ScreenOffering?,
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.screenOffering = screenOffering
        self.purchasesProvider = purchasesProvider
    }

    func refreshOffering() {
        guard let screenOffering else {
            isLoadingOffering = false
            return
        }

        isLoadingOffering = true

        Task { @MainActor in
            defer { isLoadingOffering = false }

            do {
                let offerings = try await purchasesProvider.offerings()

                switch screenOffering.type {
                case .current:
                    self.offering = offerings.current
                case .specific:
                    if let offeringId = screenOffering.offeringId {
                        self.offering = offerings.offering(identifier: offeringId)
                    } else {
                        Logger.debug("ScreenOffering type is .specific but offeringId is nil")
                        self.offering = nil
                    }
                }
            } catch {
                Logger.debug("Error fetching offerings: \(error)")
                self.offering = nil
            }
        }
    }

    func showPaywall() {
        showOffering = true
    }

    func hidePaywall() {
        showOffering = false
    }

    @Sendable @MainActor
    func performPurchase(packageToPurchase: Package) async -> (userCancelled: Bool, error: Error?) {
        do {
            let result = try await purchasesProvider.purchase(product: packageToPurchase.storeProduct,
                                                              promotionalOffer: nil)
            return (result.userCancelled, nil)
        } catch {
            return (false, error)
        }
    }

    @Sendable @MainActor
    func performRestore() async -> (success: Bool, error: Error?) {
        do {
            _ = try await purchasesProvider.restorePurchases()
            return (true, nil)
        } catch {
            return (false, error)
        }
    }
}

#endif
