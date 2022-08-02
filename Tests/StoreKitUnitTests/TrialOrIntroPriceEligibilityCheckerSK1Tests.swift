//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerSK1Tests.swift
//
//  Created by César de la Vega on 9/1/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

// swiftlint:disable:next type_name
class TrialOrIntroPriceEligibilityCheckerSK1Tests: StoreKitConfigTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!
    var mockOfferingsAPI: MockOfferingsAPI!
    var mockProductsManager: MockProductsManager!
    var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        mockSystemInfo = try MockSystemInfo(platformInfo: platformInfo,
                                            finishTransactions: true,
                                            storeKit2Setting: .disabled)
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        self.mockProductsManager = MockProductsManager(systemInfo: mockSystemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                        receiptParser: MockReceiptParser())
        mockBackend = MockBackend()

        self.mockOfferingsAPI = try XCTUnwrap(self.mockBackend.offerings as? MockOfferingsAPI)
        let mockOperationDispatcher = MockOperationDispatcher()
        let userProvider = MockCurrentUserProvider(mockAppUserID: "app_user")
        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: mockSystemInfo,
            receiptFetcher: receiptFetcher,
            introEligibilityCalculator: mockIntroEligibilityCalculator,
            backend: mockBackend,
            currentUserProvider: userProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: mockProductsManager
        )
    }

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntCrash() throws {
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { _ in
        }
    }

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntFetchAReceipt() throws {
        self.receiptFetcher.shouldReturnReceipt = false

        expect(self.receiptFetcher.receiptDataCalled) == false

        self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([]) { _ in }

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .never
    }

    func testSK1EligibilityIsCalculatedFromReceiptData() throws {
        let stubbedEligibility = ["product_id": IntroEligibilityStatus.eligible]
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = (stubbedEligibility, nil)

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { (receivedEligibilities) in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
    }

    func testSK1EligibilityProductsWithKnownIntroEligibilityStatus() throws {
        let productIdentifiersAndDiscounts = [("product_id", nil),
                        ("com.revenuecat.monthly_4.99.1_week_intro", MockSKProductDiscount()),
                        ("com.revenuecat.annual_39.99.2_week_intro", MockSKProductDiscount()),
                        ("lifetime", MockSKProductDiscount())
        ]
        let productIdentifiers = productIdentifiersAndDiscounts.map({$0.0})
        let storeProducts = productIdentifiersAndDiscounts.map { (productIdentifier, discount) -> StoreProduct in
            let sk1Product = MockSK1Product(mockProductIdentifier: productIdentifier)
            sk1Product.mockDiscount = discount
            return StoreProduct(sk1Product: sk1Product)
        }

        var finalResults: [String: IntroEligibility] = [:]

        self.mockProductsManager.stubbedProductsCompletionResult = .success(Set(storeProducts))
        trialOrIntroPriceEligibilityChecker.productsWithKnownIntroEligibilityStatus(
            productIdentifiers: productIdentifiers) { results in
            finalResults = results
        }

        expect(finalResults.count) == 1
        expect(finalResults["product_id"]?.status) == IntroEligibilityStatus.noIntroOfferExists
        expect(finalResults["com.revenuecat.monthly_4.99.1_week_intro"]?.status) == nil
        expect(finalResults["com.revenuecat.annual_39.99.2_week_intro"]?.status) == nil
        expect(finalResults["lifetime"]?.status) == nil
    }

    func testSK1EligibilityIsFetchedFromBackendIfErrorCalculatingEligibilityAndStoreKitDoesNotHaveIt() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        let productId = "product_id"
        let stubbedEligibility = [productId: IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)]
        mockOfferingsAPI.stubbedGetIntroEligibilityCompletionResult = (stubbedEligibility, nil)

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.eligible

        expect(self.mockOfferingsAPI.invokedGetIntroEligibilityCount) == 1
    }

    func testSK1EligibilityIsNotFetchedFromBackendIfEligibilityAlreadyExists() throws {
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        let sk1Product = MockSK1Product(mockProductIdentifier: "product_id")
        sk1Product.mockDiscount = nil
        let storeProduct =  StoreProduct(sk1Product: sk1Product)

        self.mockProductsManager.stubbedProductsCompletionResult = .success([
            storeProduct
        ])

        let productId = "product_id"
        let stubbedEligibility = [productId: IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)]
        mockOfferingsAPI.stubbedGetIntroEligibilityCompletionResult = (stubbedEligibility, nil)

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.noIntroOfferExists

        expect(self.mockOfferingsAPI.invokedGetIntroEligibilityCount) == 0
    }

    func testSK1ErrorFetchingFromBackendAfterErrorCalculatingEligibility() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])
        let productId = "product_id"

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey, message: nil),
                           400)
        )
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        mockOfferingsAPI.stubbedGetIntroEligibilityCompletionResult = ([:], stubbedError)

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.unknown
    }

}
