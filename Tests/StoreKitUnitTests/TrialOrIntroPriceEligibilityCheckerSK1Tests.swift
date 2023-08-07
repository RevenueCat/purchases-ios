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

// swiftlint:disable type_name

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class TrialOrIntroPriceEligibilityCheckerSK1Tests: StoreKitConfigTestCase {

    private var receiptFetcher: MockReceiptFetcher!
    private var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    private var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    private var mockBackend: MockBackend!
    private var mockOfferingsAPI: MockOfferingsAPI!
    private var mockProductsManager: MockProductsManager!
    private var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        self.mockSystemInfo = MockSystemInfo(platformInfo: platformInfo,
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
        self.trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: self.mockSystemInfo,
            receiptFetcher: self.receiptFetcher,
            introEligibilityCalculator: self.mockIntroEligibilityCalculator,
            backend: self.mockBackend,
            currentUserProvider: userProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: self.mockProductsManager
        )
    }

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntCrash() throws {
        self.mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], nil)

        waitUntil { completion in
            self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([]) { _ in
                completion()
            }
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

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([], completion: completed)
        }

        expect(eligibilities).to(haveCount(1))
    }

    func testSK1EligibilityProductsWithKnownIntroEligibilityStatus() throws {
        let productIdentifiersAndDiscounts = [("product_id", nil),
                        ("com.revenuecat.monthly_4.99.1_week_intro", MockSKProductDiscount()),
                        ("com.revenuecat.annual_39.99.2_week_intro", MockSKProductDiscount()),
                        ("lifetime", MockSKProductDiscount())
        ]
        let productIdentifiers = Set(productIdentifiersAndDiscounts.map(\.0))
        let storeProducts = productIdentifiersAndDiscounts.map { (productIdentifier, discount) -> StoreProduct in
            let sk1Product = MockSK1Product(mockProductIdentifier: productIdentifier)
            sk1Product.mockDiscount = discount
            return StoreProduct(sk1Product: sk1Product)
        }

        self.mockProductsManager.stubbedProductsCompletionResult = .success(Set(storeProducts))

        let finalResults: [String: IntroEligibility]? = waitUntilValue { completion in
            self.trialOrIntroPriceEligibilityChecker.productsWithKnownIntroEligibilityStatus(
                productIdentifiers: productIdentifiers,
                completion: completion
            )
        }

        expect(finalResults).to(haveCount(1))
        expect(finalResults?["product_id"]?.status) == .noIntroOfferExists
        expect(finalResults?["com.revenuecat.monthly_4.99.1_week_intro"]?.status) == nil
        expect(finalResults?["com.revenuecat.annual_39.99.2_week_intro"]?.status) == nil
        expect(finalResults?["lifetime"]?.status) == nil
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

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([productId], completion: completed)
        }

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

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([productId], completion: completed)
        }

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.noIntroOfferExists

        expect(self.mockOfferingsAPI.invokedGetIntroEligibilityCount) == 0
    }

    func testSK1ErrorFetchingFromBackendAfterErrorCalculatingEligibility() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])
        let productId = "product_id"

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        mockOfferingsAPI.stubbedGetIntroEligibilityCompletionResult = ([:], stubbedError)

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.sk1CheckEligibility([productId], completion: completed)
        }

        expect(eligibilities).toEventuallyNot(beNil())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(1))
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.unknown
    }

}
