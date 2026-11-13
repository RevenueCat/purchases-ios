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

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

//    #if ENABLE_MULTISEAT_PURCHASES

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit)
    @available(iOS 27.3, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func presentMultiSeatInvitationSheet(
        for product: StoreProduct,
        from controller: UIViewController,
    ) async throws {
        let subscriptionGroupIdentifier = try validateCanPresentMultiSeatSheet(
            for: product
        )

        try await AppStore.presentMultiSeatInvitationSheet(
            from: controller,
            subscriptionGroupID: subscriptionGroupIdentifier
        )
    }
    #endif

    /// Determines if a multiseat sheet can be presented by the OS for a given StoreProduct.
    /// - Parameter storeProduct: The product that you would like to present a multiseat sheet for.
    /// - Throws: If a sheet cannot be presented
    /// - Returns: The subscription group identifier for the product, if the OS can present a multiseat sheet for the product.
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

        let supportsMultiSeatPurchase = (storeProduct.sk2Product?.supportsMultiSeatPurchase) ?? false
        guard supportsMultiSeatPurchase else {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheets for StoreKit 2 products " +
                "that do not support multiseat purchases."
            )
        }

        guard let subscriptionGroupIdentifier = storeProduct.subscriptionGroupIdentifier else {
            throw ErrorUtils.unsupportedError(
                message: "Cannot present multiseat sheet for this product: the subscription group identifier is missing."
            )
        }

        return subscriptionGroupIdentifier
    }

//    #endif
}
