//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesMultiSeatSheetsTests.swift
//
//  Created by Will Taylor on 11/13/26.

import Nimble
import XCTest

@_spi(Experimental) @testable import RevenueCat

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit)
import UIKit

// #if ENABLE_MULTISEAT_PURCHASES

class PurchasesMultiSeatSheetsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS273APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    // MARK: - StoreProduct

    @MainActor
    @available(iOS 27.3, *)
    func testPresentInvitationSheetForStoreProductForwardsToHelper() async throws {
        let product = Self.product
        let controller = UIViewController()

        try await self.purchases.presentMultiSeatInvitationSheet(for: product, from: controller)

        let invocations = self.mockMultiSeatSheetsHelper.invitationSheetInvocations
        expect(invocations).to(haveCount(1))
        expect(invocations.first?.product) === product
        expect(invocations.first?.controller) === controller
    }

    @MainActor
    @available(iOS 27.3, *)
    func testPresentInvitationSheetForStoreProductPropagatesHelperError() async throws {
        self.mockMultiSeatSheetsHelper.stubbedInvitationSheetError = ErrorUtils.storeProblemError()

        do {
            try await self.purchases.presentMultiSeatInvitationSheet(for: Self.product, from: UIViewController())
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }

        expect(self.mockMultiSeatSheetsHelper.invitationSheetInvocations).to(haveCount(1))
    }

    // MARK: - Package

    @MainActor
    @available(iOS 27.3, *)
    func testPresentInvitationSheetForPackageForwardsPackageProductToHelper() async throws {
        let package = Self.package
        let controller = UIViewController()

        try await self.purchases.presentMultiSeatInvitationSheet(for: package, from: controller)

        let invocations = self.mockMultiSeatSheetsHelper.invitationSheetInvocations
        expect(invocations).to(haveCount(1))
        expect(invocations.first?.product) === package.storeProduct
        expect(invocations.first?.controller) === controller
    }

    @MainActor
    @available(iOS 27.3, *)
    func testPresentInvitationSheetForPackagePropagatesHelperError() async throws {
        self.mockMultiSeatSheetsHelper.stubbedInvitationSheetError = ErrorUtils.storeProblemError()

        do {
            try await self.purchases.presentMultiSeatInvitationSheet(for: Self.package, from: UIViewController())
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }

        expect(self.mockMultiSeatSheetsHelper.invitationSheetInvocations).to(haveCount(1))
    }

}

private extension PurchasesMultiSeatSheetsTests {

    static let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.multiseat"))

    static let package = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.multiseat")),
        offeringIdentifier: "offering",
        webCheckoutUrl: nil
    )

}

// #endif

#endif
