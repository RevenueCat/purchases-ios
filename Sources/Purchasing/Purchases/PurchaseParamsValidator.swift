//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseParamsValidator.swift
//
//  Created by Will Taylor on 11/16/26.

import Foundation

/// Validates ``PurchaseParams`` before a purchase is started.
internal final class PurchaseParamsValidator: Sendable {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    /// Validates the given ``PurchaseParams``.
    ///
    /// - Parameter purchaseParams: The params to validate.
    /// - Throws: A ``PurchasesError`` describing why the params are invalid.
    func validate(purchaseParams: PurchaseParams) throws {
        try self.validateSeats(for: purchaseParams)
    }

}

// MARK: - Seats Validation
private extension PurchaseParamsValidator {
    private func validateSeats(for purchaseParams: PurchaseParams) throws {
        #if compiler(>=6.4.4)
        guard let seats = purchaseParams.seats else { return }

        guard purchaseParams.quantity == nil else {
            throw ErrorUtils.purchaseInvalidError(
                message: Strings.purchase.seats_and_quantity_not_supported.description
            )
        }

        guard !self.isStoreKit1(purchaseParams) else {
            throw ErrorUtils.featureNotSupportedWithStoreKit1Error()
        }

        guard seats >= 1 else {
            throw ErrorUtils.purchaseInvalidError(
                message: Strings.purchase.invalid_seats(seats: seats).description
            )
        }

        if purchaseParams.containsTestStoreProduct() {
            throw ErrorUtils.purchaseInvalidError(
                message: Strings.purchase.seats_not_supported_for_test_store.description
            )
        }
        #endif
    }

    /// Whether the purchase would be made with StoreKit 1, either because the SDK is configured
    /// for StoreKit 1 or because the product (or package's product) is backed by an `SK1Product`.
    /// The purchase path is chosen based on the product, so both must be checked.
    func isStoreKit1(_ purchaseParams: PurchaseParams) -> Bool {
        if self.systemInfo.storeKitVersion == .storeKit1 {
            return true
        }

        let isProductSK1 = purchaseParams.product?.sk1Product != nil
        let isPackageSK1 = purchaseParams.package?.storeProduct.sk1Product != nil
        return isProductSK1 || isPackageSK1
    }
}

private extension PurchaseParams {
    func containsTestStoreProduct() -> Bool {
        let product = self.product ?? self.package?.storeProduct
        return product?.testStoreProduct != nil
    }
}
