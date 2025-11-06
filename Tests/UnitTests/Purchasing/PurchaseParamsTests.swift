//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseParamsTests.swift
//
//  Created by Mark Villacampa on 30/10/24.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchaseParamsTests: TestCase {

    // MARK: - PurchaseParams
    func testPurchaseParamsBuilderWithProduct() async throws {
        let product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let storeProduct = StoreProduct(sk1Product: product)
        let params = PurchaseParams.Builder(product: storeProduct).build()
        expect(params.package).to(beNil())
        expect(params.product).to(equal(StoreProduct(sk1Product: product)))
    }

    func testPurchaseParamsBuilderWithPackage() async throws {
        let product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk1Product: product),
                              offeringIdentifier: "offering",
                              webCheckoutUrl: nil)
        let params = PurchaseParams.Builder(package: package).build()
        expect(params.package).to(equal(package))
        expect(params.product).to(beNil())
    }

    func testPurchaseParamsBuilderWithOptions() async throws {
        let product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: StoreProduct(sk1Product: product),
                              offeringIdentifier: "offering",
                              webCheckoutUrl: nil)
        let discount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                currencyCode: product.priceLocale.currencyCode,
                                                price: 11.1,
                                                localizedPriceString: "$11.10",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: .init(value: 1, unit: .month),
                                                numberOfPeriods: 2,
                                                type: .promotional)
        let signedData = PromotionalOffer.SignedData(identifier: "",
                                                     keyIdentifier: "",
                                                     nonce: UUID(),
                                                     signature: "",
                                                     timestamp: 0)
        let promoOffer = PromotionalOffer(discount: discount, signedData: signedData)
        let metadata = ["key": "value"]

        let winbackOffer = WinBackOffer(
            discount: MockStoreProductDiscount(
                offerIdentifier: nil,
                currencyCode: nil,
                price: 0,
                localizedPriceString: "",
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 1, unit: .week),
                numberOfPeriods: 1,
                type: .winBack
            )
        )

        var builder = PurchaseParams.Builder(package: package)
            .with(promotionalOffer: promoOffer)

        #if ENABLE_TRANSACTION_METADATA
        builder = builder.with(metadata: metadata)
        #endif

        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            builder = builder.with(winBackOffer: winbackOffer)
        }

        let params = builder.build()

        expect(params.package).to(equal(package))
        expect(params.product).to(beNil())

        #if ENABLE_TRANSACTION_METADATA
        expect(params.metadata).to(equal(metadata))
        #else
        expect(params.metadata).to(beNil())
        #endif

        expect(params.promotionalOffer).to(equal(promoOffer))

        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            expect(params.winBackOffer).to(equal(winbackOffer))
        }
    }

    func testPurchaseParamsBuilderWithQuantity() async throws {
        let product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let storeProduct = StoreProduct(sk1Product: product)

        let paramsDefault = PurchaseParams.Builder(product: storeProduct).build()
        expect(paramsDefault.quantity).to(beNil())

        let paramsWithQuantity = PurchaseParams.Builder(product: storeProduct)
            .with(quantity: 5)
            .build()
        expect(paramsWithQuantity.quantity).to(equal(5))

        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering",
                              webCheckoutUrl: nil)
        let paramsWithAllOptions = PurchaseParams.Builder(package: package)
            .with(quantity: 3)
            .build()
        expect(paramsWithAllOptions.quantity).to(equal(3))
        expect(paramsWithAllOptions.package).to(equal(package))
    }

}
