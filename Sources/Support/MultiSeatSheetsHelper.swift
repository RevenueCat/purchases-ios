//
//  MultiseatSheetsHelper.swift
//  RevenueCat
//
//  Created by Will Taylor on 11/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

internal class MultiSeatSheetsHelper {

    private let systemInfo: SystemInfo
    private let multiSeatSheetPresenter: MultiSeatSheetPresenterType
    private let supportsMultiSeatPurchaseCalculator: MultiSeatSheetsHelper.SupportsMultiSeatPurchaseCalculator

    init(
        systemInfo: SystemInfo,
        multiSeatSheetPresenter: MultiSeatSheetPresenterType = StoreKitMultiSeatSheetPresenter(),
        supportsMultiSeatPurchaseCalculator: MultiSeatSheetsHelper.SupportsMultiSeatPurchaseCalculator = .init()
    ) {
        self.systemInfo = systemInfo
        self.multiSeatSheetPresenter = multiSeatSheetPresenter
        self.supportsMultiSeatPurchaseCalculator = supportsMultiSeatPurchaseCalculator
    }

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit) && ENABLE_MULTISEAT_PURCHASES
    @available(iOS 27.3, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(visionOS, unavailable)
    @MainActor
    func presentMultiSeatInvitationSheet(
        for product: StoreProduct,
        from controller: UIViewController
    ) async throws {
        let subscriptionGroupIdentifier = try validateCanPresentMultiSeatSheet(
            for: product
        )

        do {
            try await self.multiSeatSheetPresenter.presentMultiSeatInvitationSheet(
                from: controller,
                subscriptionGroupID: subscriptionGroupIdentifier
            )
        } catch {
            throw ErrorUtils.purchasesError(withStoreKitError: error)
        }
    }
    #endif

    /// Determines if a multiseat sheet can be presented by the OS for a given StoreProduct.
    /// - Parameter storeProduct: The product that you would like to present a multiseat sheet for.
    /// - Throws: If a sheet cannot be presented
    /// - Returns: The subscription group identifier for the product, if the OS can present a multiseat sheet
    /// for the product.
    @available(iOS 27.3, macOS 27.3, tvOS 27.3, visionOS 27.3, watchOS 27.3, *)
    private func validateCanPresentMultiSeatSheet(for storeProduct: StoreProduct) throws -> String {
        guard self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable else {
            throw ErrorUtils.featureNotSupportedWithStoreKit1Error()
        }

        if storeProduct.testStoreProduct != nil {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheets for Test Store products."
            )
        }

        if storeProduct.installmentsInfo != nil {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheets for products with installments."
            )
        }

        guard let subscriptionGroupIdentifier = storeProduct.subscriptionGroupIdentifier else {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheet for this product: " +
                "the subscription group identifier is missing."
            )
        }

        // This call can be replaced with storeProduct.sk2Product?.supportsMultiSeatPurchase
        // once multiseat subscriptions are supported in SKConfig files / SKTest.
        guard self.supportsMultiSeatPurchaseCalculator.doesProductSupportMultiSeatPurchase(
            storeProduct: storeProduct
        ) else {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheets for StoreKit 2 products " +
                "that do not support multiseat purchases."
            )
        }

        return subscriptionGroupIdentifier
    }
}

extension MultiSeatSheetsHelper {

    /// Abstraction around SK2Product.supportsMultiSeatPurchase that allows us to override the value
    /// when needed for tests. This is required as of the Xcode 27.3 beta, since SKConfig files/SKTest
    /// don't yet support multiseat purchases. This can be removed and replaced by simply using a product
    /// with multiseat purchases loaded from a SKConfig file in the future.
    internal struct SupportsMultiSeatPurchaseCalculator {

        private let overrideValue: Bool?

        init(
            overrideValue: Bool? = nil
        ) {
            self.overrideValue = overrideValue
        }

        func doesProductSupportMultiSeatPurchase(
            storeProduct: StoreProduct
        ) -> Bool {
            if let overrideValue {
                return overrideValue
            }

            #if ENABLE_MULTISEAT_PURCHASES
            if #available(iOS 27.3, macOS 27.3, tvOS 27.3, visionOS 27.3, watchOS 27.3, *) {
                return (storeProduct.sk2Product?.supportsMultiSeatPurchase) ?? false
            } else {
                return false
            }
            #else
            return false
            #endif
        }
    }
}
