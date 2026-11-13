//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MultiSeatSheetsHelperTests.swift
//
//  Created by Will Taylor on 11/13/26.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit)
import UIKit

// #if ENABLE_MULTISEAT_PURCHASES

@available(iOS 15.0, *)
class MultiSeatSheetsHelperTests: StoreKitConfigTestCase {

    private var presenter: MockMultiSeatSheetPresenter!

    override func setUp() async throws {
        try await super.setUp()
        try AvailabilityChecks.iOS273APIAvailableOrSkipTest()
        self.presenter = MockMultiSeatSheetPresenter()
    }
}

// MARK: - UIKit Functions
extension MultiSeatSheetsHelperTests {
    // --- Validation
    @MainActor
    @available(iOS 27.3, *)
    func testThrowsWhenStoreKit1IsConfigured() async throws {
        let helper = self.makeHelper(storeKitVersion: .storeKit1)
        let product = StoreProduct(sk2Product: try await self.fetchSk2Product())

        do {
            try await self.presentInvitationSheet(helper: helper, product: product)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.featureNotSupportedWithStoreKit1))
        }

        expect(self.presenter.invitationSheetInvocations).to(beEmpty())
    }

    @MainActor
    @available(iOS 27.3, *)
    func testThrowsForTestStoreProduct() async throws {
        let helper = self.makeHelper()
        let product = TestStoreProduct(
            localizedTitle: "Product",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: "product",
            productType: .autoRenewableSubscription,
            localizedDescription: "Description",
            subscriptionGroupIdentifier: "group",
            locale: Locale(identifier: "en_US")
        ).toStoreProduct()

        do {
            try await self.presentInvitationSheet(helper: helper, product: product)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.unsupportedError))
        }

        expect(self.presenter.invitationSheetInvocations).to(beEmpty())
    }

    @MainActor
    @available(iOS 27.3, *)
    func testThrowsForProductWithInstallments() async throws {
        let helper = self.makeHelper()
        let storeProduct = try await ProductsFetcherSK2()
            .product(withIdentifier: "\(Self.productIDWithBillingPlans):monthly")
        expect(storeProduct.installmentsInfo).toNot(beNil())

        do {
            try await self.presentInvitationSheet(helper: helper, product: storeProduct)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.unsupportedError))
        }

        expect(self.presenter.invitationSheetInvocations).to(beEmpty())
    }

    @MainActor
    @available(iOS 27.3, *)
    func testThrowsForProductWithoutSubscriptionGroupIdentifier() async throws {
        let helper = self.makeHelper()
        let storeProduct = try await ProductsFetcherSK2()
            .product(withIdentifier: "com.revenuecat.consumable")
        expect(storeProduct.subscriptionGroupIdentifier).to(beNil())

        do {
            try await self.presentInvitationSheet(helper: helper, product: storeProduct)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.unsupportedError))
            expect(error.localizedDescription).to(contain("subscription group identifier is missing"))
        }

        expect(self.presenter.invitationSheetInvocations).to(beEmpty())
    }

    @MainActor
    @available(iOS 27.3, *)
    func testThrowsForProductThatDoesNotSupportMultiSeatPurchases() async throws {
        let helper = self.makeHelper()
        let sk2Product = try await self.fetchSk2Product()
        expect(sk2Product.supportsMultiSeatPurchase) == false

        do {
            try await self.presentInvitationSheet(helper: helper, product: StoreProduct(sk2Product: sk2Product))
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.unsupportedError))
        }

        expect(self.presenter.invitationSheetInvocations).to(beEmpty())
    }

    // --- Presentation

    @MainActor
    @available(iOS 27.3, *)
    func testSuccessfullyPresentsInvitationSheet() async throws {
        let helper = self.makeHelper(supportsMultiSeatPurchaseOverride: true)
        let product = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let controller = UIViewController()

        try await self.presentInvitationSheet(helper: helper, product: product, controller: controller)

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
        expect(self.presenter.invitationSheetInvocations.first?.subscriptionGroupID) == "7096FF06"
        expect(self.presenter.invitationSheetInvocations.first?.controller) === controller
    }

    @MainActor
    @available(iOS 27.3, *)
    func testPresentsInvitationSheetForProductInADifferentSubscriptionGroup() async throws {
        let helper = self.makeHelper(supportsMultiSeatPurchaseOverride: true)
        let storeProduct = try await ProductsFetcherSK2()
            .product(withIdentifier: "com.revenuecat.annual_39.99_no_trial")

        try await self.presentInvitationSheet(helper: helper, product: storeProduct)

        expect(self.presenter.invitationSheetInvocations.map(\.subscriptionGroupID)) == ["4BB746BD"]
    }

    // --- Error mapping

    @MainActor
    @available(iOS 27.3, *)
    func testMapsUserCancelledStoreKitErrorToPurchaseCancelledError() async throws {
        do {
            try await self.presentInvitationSheet(simulatedPresenterError: StoreKitError.userCancelled)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.purchaseCancelledError))
        }

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
    }

    @MainActor
    @available(iOS 27.3, *)
    func testMapsNetworkStoreKitErrorToNetworkError() async throws {
        do {
            try await self.presentInvitationSheet(
                simulatedPresenterError: StoreKitError.networkError(URLError(.notConnectedToInternet))
            )
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.networkError))
        }

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
    }

    @MainActor
    @available(iOS 27.3, *)
    func testMapsSystemStoreKitErrorToStoreProblemError() async throws {
        do {
            try await self.presentInvitationSheet(
                simulatedPresenterError: StoreKitError.systemError(NSError(domain: "test", code: 1))
            )
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
    }

    #if compiler(>=6.4)
    @MainActor
    @available(iOS 27.3, *)
    func testMapsInvalidPresentationContextStoreKitErrorToStoreProblemError() async throws {
        do {
            try await self.presentInvitationSheet(simulatedPresenterError: StoreKitError.invalidPresentationContext)
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
    }
    #endif

    @MainActor
    @available(iOS 27.3, *)
    func testMapsNonStoreKitErrorToUnknownError() async throws {
        do {
            try await self.presentInvitationSheet(simulatedPresenterError: NSError(domain: "test", code: 1))
            fail("Expected presenting the invitation sheet to throw")
        } catch {
            expect(error).to(matchError(ErrorCode.unknownError))
        }

        expect(self.presenter.invitationSheetInvocations).to(haveCount(1))
    }
}

// MARK: - Helpers

@available(iOS 15.0, *)
private extension MultiSeatSheetsHelperTests {

    func makeHelper(
        storeKitVersion: StoreKitVersion = .storeKit2,
        supportsMultiSeatPurchaseOverride: Bool? = nil
    ) -> MultiSeatSheetsHelper {
        return MultiSeatSheetsHelper(
            systemInfo: MockSystemInfo(
                finishTransactions: true,
                storeKitVersion: storeKitVersion
            ),
            multiSeatSheetPresenter: self.presenter,
            supportsMultiSeatPurchaseCalculator: .init(overrideValue: supportsMultiSeatPurchaseOverride)
        )
    }

    /// Presents the invitation sheet, rethrowing any error thrown by the helper.
    @available(iOS 27.3, *)
    @MainActor
    func presentInvitationSheet(
        helper: MultiSeatSheetsHelper,
        product: StoreProduct,
        controller: UIViewController? = nil
    ) async throws {
        try await helper.presentMultiSeatInvitationSheet(
            for: product,
            from: controller ?? UIViewController()
        )
    }

    /// Presents the invitation sheet for a valid multi-seat product while the presenter
    /// throws `simulatedPresenterError`, rethrowing the error thrown by the helper.
    ///
    /// This can be replaced with SKTest's simulated error functionality in the future if/when
    /// SKTest introduces support for simulated errors when displaying the multiseat sheets.
    @available(iOS 27.3, *)
    @MainActor
    func presentInvitationSheet(simulatedPresenterError: Error) async throws {
        self.presenter.stubbedInvitationSheetError = simulatedPresenterError
        let helper = self.makeHelper(supportsMultiSeatPurchaseOverride: true)
        let product = StoreProduct(sk2Product: try await self.fetchSk2Product())

        try await self.presentInvitationSheet(helper: helper, product: product)
    }

}

// #endif

#endif
