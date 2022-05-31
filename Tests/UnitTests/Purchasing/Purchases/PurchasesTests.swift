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

    func testSyncPurchasesPostsTheReceipt() {
        setupPurchases()
        purchases.syncPurchases(completion: nil)
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testSyncPurchasesPostsTheReceiptIfAutoSyncPurchasesSettingIsOff() throws {
        systemInfo = try MockSystemInfo(platformInfo: nil,
                                        finishTransactions: false,
                                        dangerousSettings: DangerousSettings(autoSyncPurchases: false))
        self.initializePurchasesInstance(appUserId: nil)

        purchases.syncPurchases(completion: nil)
        expect(self.backend.postReceiptDataCalled).to(beTrue())
    }

    func testSyncPurchasesDoesntPostIfReceiptEmptyAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]])

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        setupPurchases()
        purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == false
    }

    func testSyncPurchasesPostsIfReceiptEmptyAndCustomerInfoNotLoaded() {
        mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = false

        setupPurchases()
        purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoLoaded() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]])

        let object = try info.asData()
        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        setupPurchases()
        purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesPostsIfReceiptHasTransactionsAndCustomerInfoNotLoaded() {
        mockTransactionsManager.stubbedCustomerHasTransactionsCompletionParameter = true

        setupPurchases()
        purchases.syncPurchases(completion: nil)

        expect(self.backend.postReceiptDataCalled) == true
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfNotEmpty() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = true
        purchases.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesDoesntRefreshTheReceiptIfEmpty() {
        setupPurchases()
        self.receiptFetcher.shouldReturnReceipt = false
        purchases.syncPurchases(completion: nil)

        expect(self.receiptFetcher.receiptDataTimesCalled) == 1
        expect(self.requestFetcher.refreshReceiptCalled) == false
    }

    func testSyncPurchasesPassesIsRestoreAsAllowSharingAppStoreAccount() {
        setupPurchases()

        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

    func testSyncPurchasesSetsIsRestoreForAnon() {
        setupAnonPurchases()

        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == false

        deprecated.allowSharingAppStoreAccount = true
        purchases.syncPurchases(completion: nil)
        expect(self.backend.postedIsRestore!) == true
    }

    func testSyncPurchasesCallsSuccessDelegateMethod() throws {
        setupPurchases()

        let customerInfo = try CustomerInfo(data: Self.emptyCustomerInfoData)
        self.backend.postReceiptResult = .success(customerInfo)

        var receivedCustomerInfo: CustomerInfo?

        purchases!.syncPurchases { (info, _) in
            receivedCustomerInfo = info
        }

        expect(receivedCustomerInfo).toEventually(be(customerInfo))
    }

    func testSyncPurchasesPassesErrorOnFailure() {
        setupPurchases()

        let error: BackendError = .missingAppUserID()

        self.backend.postReceiptResult = .failure(error)
        self.purchasesDelegate.customerInfo = nil

        var receivedError: Error?

        purchases!.syncPurchases { (_, newError) in
            receivedError = newError
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError).to(matchError(error.asPurchasesError))
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

    func testDeferBlockMakesPayment() {
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        guard let storeKitWrapperDelegate = storeKitWrapper.delegate else {
            fail("storeKitWrapperDelegate nil")
            return
        }

        _ = storeKitWrapperDelegate.storeKitWrapper(storeKitWrapper,
                                                    shouldAddStorePayment: payment,
                                                    for: product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())

        expect(self.storeKitWrapper.payment).to(beNil())

        guard let makeDeferredPurchase = purchasesDelegate.makeDeferredPurchase else {
            fail("makeDeferredPurchase should have been nonNil")
            return
        }

        makeDeferredPurchase { (_, _, _, _) in
        }

        expect(self.storeKitWrapper.payment).to(be(payment))
    }

    func testGetEligibility() {
        setupPurchases()
        purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: []) { (_) in
        }

        expect(self.trialOrIntroPriceEligibilityChecker.invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore)
            .to(beTrue())
    }

    func testCachesCustomerInfo() {
        setupPurchases()

        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))
        expect(self.deviceCache.cachedCustomerInfo[self.purchases!.appUserID]).toEventuallyNot(beNil())

        let customerInfo = self.deviceCache.cachedCustomerInfo[self.purchases!.appUserID]

        do {
            if customerInfo != nil {
                try JSONSerialization.jsonObject(with: customerInfo!, options: [])
            }
        } catch {
            fail()
        }
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

    func testAddAttributionAlwaysAddsAdIdsEmptyDict() {
        setupPurchases()

        Purchases.deprecated.addAttributionData([:], fromNetwork: AttributionNetwork.adjust)

        // swiftlint:disable:next line_length
        let attributionData = self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParameters?.attributionData
        expect(attributionData?.count) == 2
        expect(attributionData?["rc_idfa"] as? String) == "rc_idfa"
        expect(attributionData?["rc_idfv"] as? String) == "rc_idfv"
    }

    func testPassesTheArrayForAllNetworks() {
        setupPurchases()
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appleSearchAds)

        for key in data.keys {
            expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains(key))
                .toEventually(beTrue())
        }
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfa")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].data?.keys.contains("rc_idfv")) == true
        expect(self.backend.invokedPostAttributionDataParametersList[0].network) == AttributionNetwork.appleSearchAds
        expect(self.backend.invokedPostAttributionDataParametersList[0].appUserID) == self.purchases?.appUserID
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

    func testDeferBlockCallsCompletionBlockAfterPurchaseCompletes() {
        setupPurchases()
        let product = MockSK1Product(mockProductIdentifier: "mock_product")
        let payment = SKPayment.init(product: product)

        _ = storeKitWrapper.delegate?.storeKitWrapper(storeKitWrapper,
                                                      shouldAddStorePayment: payment,
                                                      for: product)

        expect(self.purchasesDelegate.makeDeferredPurchase).toNot(beNil())

        expect(self.storeKitWrapper.payment).to(beNil())

        var completionCalled = false

        guard let makeDeferredPurchase = purchasesDelegate.makeDeferredPurchase else {
            fail("makeDeferredPurchase nil")
            return
        }

        makeDeferredPurchase { (_, _, _, _) in
            completionCalled = true
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.storeKitWrapper.payment).to(be(payment))
        expect(completionCalled).toEventually(beTrue())
    }

    func testAttributionDataIsPostponedIfThereIsNoInstance() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appsFlyer)

        setupPurchases()

        let invokedParameters = self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParameters
        expect(invokedParameters?.attributionData).toNot(beNil())

        for key in data.keys {
            expect(invokedParameters?.attributionData.keys.contains(key)).toEventually(beTrue())
        }

        expect(invokedParameters?.attributionData.keys.contains("rc_idfa")) == true
        expect(invokedParameters?.attributionData.keys.contains("rc_idfv")) == true
        expect(invokedParameters?.network) == AttributionNetwork.appsFlyer
        expect(invokedParameters?.appUserID) == self.purchases?.appUserID
    }

    func testAttributionDataSendsNetworkAppUserId() throws {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data,
                                                from: AttributionNetwork.appleSearchAds,
                                                forNetworkUserId: "newuser")

        setupPurchases()

        expect(self.backend.invokedPostAttributionData).toEventually(beTrue())

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)
        for key in data.keys {
            expect(invokedMethodParams.data?.keys.contains(key)).to(beTrue())
        }

        expect(invokedMethodParams.data?.keys.contains("rc_idfa")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_idfv")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_attribution_network_id")) == true
        expect(invokedMethodParams.data?["rc_attribution_network_id"] as? String) == "newuser"
        expect(invokedMethodParams.network) == AttributionNetwork.appleSearchAds
        expect(invokedMethodParams.appUserID) == identityManager.currentAppUserID
    }

    func testAttributionDataDontSendNetworkAppUserIdIfNotProvided() throws {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, fromNetwork: AttributionNetwork.appleSearchAds)

        setupPurchases()

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)
        for key in data.keys {
            expect(invokedMethodParams.data?.keys.contains(key)) == true
        }

        expect(invokedMethodParams.data?.keys.contains("rc_idfa")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_idfv")) == true
        expect(invokedMethodParams.data?.keys.contains("rc_attribution_network_id")) == false
        expect(invokedMethodParams.network) == AttributionNetwork.appleSearchAds
        expect(invokedMethodParams.appUserID) == identityManager.currentAppUserID
    }

    func testAdClientAttributionDataIsAutomaticallyCollected() throws {
        setupPurchases(automaticCollection: true)

        let invokedMethodParams = try XCTUnwrap(self.backend.invokedPostAttributionDataParameters)

        expect(invokedMethodParams).toNot(beNil())
        expect(invokedMethodParams.network) == AttributionNetwork.appleSearchAds

        let obtainedVersionData = try XCTUnwrap(invokedMethodParams.data?["Version3.1"] as? NSDictionary)
        expect(obtainedVersionData["iad-campaign-id"]).toNot(beNil())
    }

    func testAdClientAttributionDataIsNotAutomaticallyCollectedIfDisabled() {
        setupPurchases(automaticCollection: false)
        expect(self.backend.invokedPostAttributionDataParameters).to(beNil())
    }

    func testAttributionDataPostponesMultiple() {
        let data = ["yo": "dog", "what": 45, "is": ["up"]] as [String: Any]

        Purchases.deprecated.addAttributionData(data, from: AttributionNetwork.adjust, forNetworkUserId: "newuser")

        setupPurchases(automaticCollection: true)
        expect(self.backend.invokedPostAttributionDataParametersList.count) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetParametersList.count) == 1
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

    @available(iOS 14.0, macOS 14.0, tvOS 14.0, watchOS 7.0, *)
    func testSyncsPurchasesIfEntitlementsRevokedForProductIDs() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        setupPurchases()
        guard purchases != nil else { fatalError() }
        expect(self.backend.postReceiptDataCalled).to(beFalse())
        (purchasesOrchestrator as StoreKitWrapperDelegate)
            .storeKitWrapper(storeKitWrapper, didRevokeEntitlementsForProductIdentifiers: ["a", "b"])
        expect(self.backend.postReceiptDataCalled).to(beTrue())
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
