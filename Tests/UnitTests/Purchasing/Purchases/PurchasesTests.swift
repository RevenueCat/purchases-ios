//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by RevenueCat.
//

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesTests: BasePurchasesTests {

    func testDelegateIsCalledForRandomPurchaseSuccess() throws {
        setupPurchases()

        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        let product = MockSK1Product(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let customerInfoBeforePurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [:]
            ]])
        let customerInfoAfterPurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [product.mockProductIdentifier: []]
            ]])
        self.backend.overrideCustomerInfoResult = .success(customerInfoBeforePurchase)
        self.backend.postReceiptResult = .success(customerInfoAfterPurchase)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsOnlyCalledOnceIfCustomerInfoTheSame() throws {
        setupPurchases()

        let customerInfo1 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
        ])

        let customerInfo2 = customerInfo1

        let product = MockSK1Product(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo1)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo2)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testDelegateIsCalledTwiceIfCustomerInfoTheDifferent() throws {
        setupPurchases()

        let customerInfo1 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]
        ])

        let customerInfo2 = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "2.0"
            ]
        ])

        let product = MockSK1Product(mockProductIdentifier: "product")
        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo1)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(customerInfo2)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(3))
    }

    func testIsAbleToFetchProducts() {
        setupPurchases()
        var products: [StoreProduct]?
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.getProducts(productIdentifiers) { (newProducts) in
            products = newProducts
        }

        expect(products).toEventuallyNot(beNil())
        expect(products).toEventually(haveCount(productIdentifiers.count))
    }

    func testSetsSelfAsStoreKitWrapperDelegate() {
        setupPurchases()
        expect(self.storeKitWrapper.delegate).to(be(purchasesOrchestrator))
    }

    func testDoesntFetchProductDataIfEmptyList() {
        setupPurchases()
        var completionCalled = false
        mockProductsManager.resetMock()
        self.purchases.getProducts([]) { _ in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockProductsManager.invokedProducts) == false
    }

    func testSendsProductDataIfProductIsCached() throws {
        setupPurchases()
        let productIdentifiers = ["com.product.id1", "com.product.id2"]
        purchases!.getProducts(productIdentifiers) { (newProducts) in
            let product = newProducts[0]
            self.purchases.purchase(product: newProducts[0]) { (_, _, _, _) in

            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(product.productIdentifier))
            expect(self.backend.postedPrice).to(equal(product.price as Decimal))

            if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
                expect(self.backend.postedPaymentMode).to(equal(StoreProductDiscount.PaymentMode.payAsYouGo))
                expect(self.backend.postedIntroPrice).to(equal(product.introductoryDiscount?.price))
            } else {
                expect(self.backend.postedPaymentMode).to(beNil())
                expect(self.backend.postedIntroPrice).to(beNil())
            }

            if #available(iOS 12.0, tvOS 12.0, macOS 10.14, *) {
                expect(self.backend.postedSubscriptionGroup).to(equal(product.subscriptionGroupIdentifier))
            }

            if #available(iOS 12.2, *) {
                expect(self.backend.postedDiscounts?.count).to(equal(1))
                let postedDiscount: StoreProductDiscount = self.backend.postedDiscounts![0]
                expect(postedDiscount.offerIdentifier).to(equal("discount_id"))
                expect(postedDiscount.price).to(equal(1.99))
                let expectedPaymentMode = StoreProductDiscount.PaymentMode.payAsYouGo.rawValue
                expect(postedDiscount.paymentMode.rawValue).to(equal(expectedPaymentMode))
            }

            expect(self.backend.postedCurrencyCode) == product.priceFormatter!.currencyCode

            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testFetchesProductDataIfNotCached() throws {
        systemInfo.stubbedIsApplicationBackgrounded = true
        setupPurchases()
        let sk1Product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let product = StoreProduct(sk1Product: sk1Product)

        let transaction = MockTransaction()
        storeKitWrapper.payment = SKPayment(product: sk1Product)
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedProductsParameters).toEventually(contain([product.productIdentifier]))

        expect(self.backend.postedProductID).toNot(beNil())
        expect(self.backend.postedPrice).toNot(beNil())
        expect(self.backend.postedCurrencyCode).toNot(beNil())
        if #available(iOS 12.2, macOS 10.14.4, *) {
            expect(self.backend.postedIntroPrice).toNot(beNil())
        }
    }

    func testDoesntIgnorePurchasesThatDoNotHaveApplicationUserNames() {
        setupPurchases()
        let transaction = MockTransaction()

        let payment = SKMutablePayment()
        payment.productIdentifier = "test"

        expect(payment.applicationUsername).to(beNil())

        transaction.mockPayment = payment
        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testDoesntSetWrapperDelegateToNilIfDelegateNil() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.storeKitWrapper.delegate).toNot(beNil())

        purchases!.delegate = purchasesDelegate

        expect(self.storeKitWrapper.delegate).toNot(beNil())
    }

    func testSubscribesToUIApplicationDidBecomeActive() {
        setupPurchases()
        expect(self.notificationCenter.observers.count).to(equal(2))
        if self.notificationCenter.observers.count > 0 {
            let (_, _, name, _) = self.notificationCenter.observers[0]
            expect(name).to(equal(SystemInfo.applicationDidBecomeActiveNotification))
        }
    }

    func testTriggersCallToBackend() {
        setupPurchases()
        notificationCenter.fireNotifications()
        expect(self.backend.userID).toEventuallyNot(beNil())
    }

    func testAutomaticallyFetchesCustomerInfoOnDidBecomeActiveIfCacheStale() {
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        notificationCenter.fireNotifications()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(2))
    }

    func testDoesntAutomaticallyFetchCustomerInfoOnDidBecomeActiveIfCacheValid() {
        setupPurchases()
        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
        self.deviceCache.stubbedIsCustomerInfoCacheStale = false

        notificationCenter.fireNotifications()

        expect(self.backend.getSubscriberCallCount).toEventually(equal(1))
    }

    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        setupPurchases()
        notificationCenter.fireNotifications()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemoveObservationWhenDelegateNil() {
        setupPurchases()
        purchases!.delegate = nil

        expect(self.notificationCenter.observers.count).to(equal(2))
    }

    func testCallsShouldAddPromoPaymentDelegateMethod() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "mock_product"))
        let payment = SKPayment()

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product.sk1Product!)

        expect(self.purchasesDelegate.promoProduct) == product
    }

    func testShouldAddPromoPaymentDelegateMethodReturnsFalse() {
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "mock_product")
        let payment = SKPayment()

        let result = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                               shouldAddStorePayment: payment,
                                                               for: product)

        expect(result).to(beFalse())
    }

    func testPromoPaymentDelegateMethodMakesRightCalls() {
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedProductID).to(equal(product.productIdentifier))
        expect(self.backend.postedPrice).to(equal(product.price as Decimal))
    }

    func testPromoPaymentDelegateMethodCachesProduct() {
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        let transaction = MockTransaction()
        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == product
    }

    func testGetEligibility() {
        setupPurchases()
        purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: []) { (_) in
        }

        expect(self.trialOrIntroPriceEligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore)
            .to(beTrue())
    }

    func testCachesCustomerInfo() throws {
        setupPurchases()

        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))
        expect(self.deviceCache.cachedCustomerInfo[self.purchases.appUserID]).toEventuallyNot(beNil())

        let cachedData = try XCTUnwrap(self.deviceCache.cachedCustomerInfo[self.purchases.appUserID])
        try JSONSerialization.jsonObject(with: cachedData, options: [])
    }

    func testCachesCustomerInfoOnPurchase() throws {
        setupPurchases()

        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))

        self.backend.postReceiptResult = .success(try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]))

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in

        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())

        expect(self.deviceCache.cacheCustomerInfoCount).toEventually(equal(2))
    }

    func testWhenNoReceiptDataReceiptIsRefreshed() {
        setupPurchases()
        receiptFetcher.shouldReturnReceipt = true
        receiptFetcher.shouldReturnZeroBytesReceipt = true

        self.makeAPurchase()

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .onlyIfEmpty
    }

    func testPaymentSheetCancelledErrorIsParsedCorrectly() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedUserCancelled: Bool?
        var receivedError: NSError?

        let unknownError = NSError(
            domain: SKErrorDomain,
            code: 907,
            userInfo: [
                NSUnderlyingErrorKey: NSError(
                    domain: "AMSErrorDomain",
                    code: 6,
                    userInfo: [:]
                )
            ]
        )

        self.purchases.purchase(product: product) { (_, _, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = .failed
        transaction.mockError = unknownError
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventuallyNot(beNil())
        expect(receivedUserCancelled) == true
        expect(receivedError).to(matchError(ErrorCode.purchaseCancelledError))
    }

    func testIsAnonymous() {
        setupAnonPurchases()
        expect(self.purchases.isAnonymous).to(beTrue())
    }

    func testIsNotAnonymous() {
        setupPurchases()
        expect(self.purchases.isAnonymous).to(beFalse())
    }

    func testProductIsRemovedButPresentInTheQueuedTransaction() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = Set()
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "product")

        let customerInfoBeforePurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [:]
            ]])
        let customerInfoAfterPurchase = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "non_subscriptions": [product.mockProductIdentifier: []]
            ]])
        self.backend.overrideCustomerInfoResult = .success(customerInfoBeforePurchase)
        self.backend.postReceiptResult = .success(customerInfoAfterPurchase)

        let payment = SKPayment(product: product)

        let transaction = MockTransaction()

        transaction.mockPayment = payment

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(2))
    }

    func testProxyURL() {
        expect(SystemInfo.proxyURL).to(beNil())
        let defaultHostURL = URL(string: "https://api.revenuecat.com")
        expect(SystemInfo.serverHostURL) == defaultHostURL

        let testURL = URL(string: "https://test_url")
        Purchases.proxyURL = testURL

        expect(SystemInfo.serverHostURL) == testURL

        Purchases.proxyURL = nil

        expect(SystemInfo.serverHostURL) == defaultHostURL
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testSetDebugLogsEnabledSetsTheCorrectValue() {
        Logger.logLevel = .warn

        Purchases.debugLogsEnabled = true
        expect(Logger.logLevel) == .debug

        Purchases.debugLogsEnabled = false
        expect(Logger.logLevel) == .info
    }

    private func verifyUpdatedCaches(newAppUserID: String) {
        let expectedCallCount = 2
        expect(self.backend.getSubscriberCallCount).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.cachedCustomerInfo[newAppUserID]).toEventuallyNot(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(expectedCallCount))
        expect(self.deviceCache.setCustomerInfoCacheTimestampToNowCount).toEventually(equal(expectedCallCount))
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(expectedCallCount))
    }

}
