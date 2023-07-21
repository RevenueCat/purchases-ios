//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesGetProductsTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesGetProductsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testDoesntFetchProductDataIfEmptyList() {
        self.mockProductsManager.resetMock()

        waitUntil { completed in
            self.purchases.getProducts([]) { _ in
                completed()
            }
        }

        expect(self.mockProductsManager.invokedProducts) == false
    }

    func testIsAbleToFetchProducts() {
        let productIdentifiers = ["com.product.id1", "com.product.id2"]

        let products = waitUntilValue { completed in
            self.purchases.getProducts(productIdentifiers, completion: completed)
        }

        expect(products).to(haveCount(productIdentifiers.count))
    }

    func testGetEligibility() {
        self.purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: ["product 1"]) { (_) in }

        expect(
            self.trialOrIntroPriceEligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore
        ) == true
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func testGetEligibilityForPackages() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let packages: [Package] = [
            .init(identifier: "package1",
                  packageType: .weekly,
                  storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "product1")),
                  offeringIdentifier: "offering"),
            .init(identifier: "package2",
                  packageType: .monthly,
                  storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "product2")),
                  offeringIdentifier: "offering"),
            .init(identifier: "package3",
                  packageType: .annual,
                  storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "product3")),
                  offeringIdentifier: "offering"),
            .init(identifier: "package4",
                  packageType: .annual,
                  storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "product4")),
                  offeringIdentifier: "offering"),
            .init(identifier: "package5",
                  packageType: .annual,
                  storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "product1")),
                  offeringIdentifier: "offering")
        ]

        self.trialOrIntroPriceEligibilityChecker
            .stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult = [
            "product1": .init(eligibilityStatus: .eligible),
            "product2": .init(eligibilityStatus: .noIntroOfferExists),
            "product3": .init(eligibilityStatus: .ineligible)
        ]

        let result = await self.purchases.checkTrialOrIntroDiscountEligibility(packages: packages)

        expect(result) == [
            packages[0]: .init(eligibilityStatus: .eligible),
            packages[1]: .init(eligibilityStatus: .noIntroOfferExists),
            packages[2]: .init(eligibilityStatus: .ineligible),
            packages[3]: .init(eligibilityStatus: .unknown),
            packages[4]: .init(eligibilityStatus: .eligible)
        ]
    }

}

class PurchasesGetProductsBackgroundTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
    }

    func testFetchesProductDataIfNotCached() throws {
        let sk1Product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let product = StoreProduct(sk1Product: sk1Product)

        let transaction = MockTransaction()
        self.storeKit1Wrapper.payment = SKPayment(product: sk1Product)
        transaction.mockPayment = self.storeKit1Wrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedProductsParameters).toEventually(contain([product.productIdentifier]))

        expect(self.backend.postedProductID).toNot(beNil())
        expect(self.backend.postedPrice).toNot(beNil())
        expect(self.backend.postedCurrencyCode).toNot(beNil())
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expect(self.backend.postedIntroPrice).toNot(beNil())
        }
    }

}
