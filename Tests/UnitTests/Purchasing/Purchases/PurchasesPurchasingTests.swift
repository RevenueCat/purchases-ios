//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesPurchasingTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesPurchasingTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testDelegateIsNotCalledWhenPurchasingIfBlockPassed() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedIsRestore) == false
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testAddsPaymentToWrapper() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        expect(self.storeKitWrapper.payment).toNot(beNil())
        expect(self.storeKitWrapper.payment?.productIdentifier).to(equal(product.productIdentifier))
    }

    func testPurchaseProductCachesProduct() {
        let sk1Product = MockSK1Product(mockProductIdentifier: "com.product.id1")
        let product = StoreProduct(sk1Product: sk1Product)
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        expect(self.mockProductsManager.invokedCacheProduct) == true
        expect(self.mockProductsManager.invokedCacheProductParameter) == sk1Product
    }

    func testTransitioningToPurchasedSendsToBackend() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedIsRestore) == false
    }

    func testReceiptsSendsAsRestoreWhenNotAnonymousAndAllowingSharingAppStoreAccount() {
        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = true
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedIsRestore) == true
    }

    func testFinishesTransactionsIfSentToBackendCorrectly() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testDoesntFinishTransactionsIfFinishingDisabled() throws {
        self.purchases.finishTransactions = false
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testAfterSendingDoesntFinishTransactionIfBackendError() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        self.backend.postReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .unknownBackendError, message: nil),
                .internalServerError
            ))
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled) == false
    }

    func testAfterSendingFinishesFromBackendErrorIfAppropriate() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .unknownBackendError, message: nil),
                .invalidRequest
            ))
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNotifiesIfTransactionFailsFromBackend() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .unknownBackendError, message: nil),
                .internalServerError
            ))
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled) == false
    }

    func testNotifiesIfTransactionFailsFromStoreKit() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedError: Error?
        self.purchases.purchase(product: product) { (_, _, error, _) in
            receivedError = error
        }

        let transaction = MockTransaction()
        transaction.mockError = NSError.init(domain: SKErrorDomain, code: 2, userInfo: nil)
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptResult = .failure(.missingTransactionProductIdentifier())

        transaction.mockState = SKPaymentTransactionState.failed
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == false
        expect(self.storeKitWrapper.finishCalled) == true
        expect(receivedError).toEventuallyNot(beNil())
    }

    func testCompletionBlockOnlyCalledOnce() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        var callCount = 0

        self.purchases.purchase(product: product) { (_, _, _, _) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(callCount).toEventually(equal(1))
    }

    func testUserCancelledFalseIfPurchaseSuccessful() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedUserCancelled: Bool?

        self.purchases.purchase(product: product) { (_, _, _, userCancelled) in
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
    }

    func testUnknownErrorCurrentlySubscribedIsParsedCorrectly() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedUserCancelled: Bool?
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        let unknownError = NSError(
            domain: SKErrorDomain,
            code: SKError.unknown.rawValue,
            userInfo: [
                NSUnderlyingErrorKey: NSError(
                    domain: "ASDServerErrorDomain",
                    code: 3532,
                    userInfo: [:]
                )
            ]
        )

        self.purchases.purchase(product: product) { (_, _, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
            // swiftlint:disable:next force_cast
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as! NSError?
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = .failed
        transaction.mockError = unknownError
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.productAlreadyPurchasedError.rawValue))
        expect(receivedUnderlyingError?.domain).toEventually(equal(unknownError.domain))
        expect(receivedUnderlyingError?.code).toEventually(equal(unknownError.code))
    }

    func testUserCancelledTrueIfSK1PurchaseCancelled() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        var receivedTransaction: StoreTransaction?
        var receivedCustomerInfo: CustomerInfo?
        var receivedUserCancelled: Bool?
        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        self.purchases.purchase(product: product) { (transaction, customerInfo, error, userCancelled) in
            receivedTransaction = transaction
            receivedCustomerInfo = customerInfo
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        let transaction = MockTransaction()
        transaction.mockPayment = try XCTUnwrap(self.storeKitWrapper.payment)
        transaction.mockState = .failed
        transaction.mockError = NSError(domain: SKErrorDomain, code: SKError.Code.paymentCancelled.rawValue)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventuallyNot(beNil())

        expect(receivedTransaction).toNot(beNil())
        expect(receivedCustomerInfo).to(beNil())
        expect(receivedUserCancelled) == true
        expect(receivedError).to(matchError(ErrorCode.purchaseCancelledError))
        expect(receivedUnderlyingError?.domain) == SKErrorDomain
        expect(receivedUnderlyingError?.code) == SKError.Code.paymentCancelled.rawValue
    }

    @MainActor
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testUserCancelledTrueIfSK1AsyncPurchaseCancelled() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        var receivedError: NSError?

        _ = Task {
            do {
                _ = try await self.purchases.purchase(
                    product: product
                )
            } catch {
                receivedError = error as NSError
            }
        }

        expect(self.storeKitWrapper.payment).toEventuallyNot(beNil())

        let transaction = MockTransaction()
        transaction.mockPayment = try XCTUnwrap(self.storeKitWrapper.payment)
        transaction.mockState = .failed
        transaction.mockError = NSError(domain: SKErrorDomain, code: SKError.Code.paymentCancelled.rawValue)
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError).to(matchError(ErrorCode.purchaseCancelledError))
    }

    func testDoNotSendEmptyReceiptWhenMakingPurchase() {
        self.receiptFetcher.shouldReturnReceipt = false

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedUserCancelled: Bool?
        var receivedError: NSError?

        self.purchases.purchase(product: product) { (_, _, error, userCancelled) in
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(receivedUserCancelled).toEventually(beFalse())
        expect(receivedError).toEventuallyNot(beNil())
        expect(self.backend.postReceiptDataCalled).toEventually(beFalse())

        expect(receivedError?.domain) == RCPurchasesErrorCodeDomain
        expect(receivedError?.code) == ErrorCode.missingReceiptFileError.rawValue
    }

    func testObserverModeSetToFalseSetFinishTransactions() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
    }

    func testNoCrashIfPaymentIsMissing() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }
        let transaction = SKPaymentTransaction()

        transaction.setValue(SKPaymentTransactionState.purchasing.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.setValue(SKPaymentTransactionState.purchased.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

    func testNoCrashIfPaymentDoesNotHaveProductIdenfier() {
        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment()

        transaction.setValue(SKPaymentTransactionState.purchasing.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.setValue(SKPaymentTransactionState.purchased.rawValue, forKey: "transactionState")
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

    func testReceiptsSendsObserverModeOffWhenObserverModeOff() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedObserverMode) == false
    }

    func testNotifiesIfTransactionIsDeferredFromStoreKit() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        var receivedError: NSError?
        self.purchases.purchase(product: product) { (_, _, error, _) in
            receivedError = error as NSError?
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.deferred
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == false
        expect(self.storeKitWrapper.finishCalled) == false
        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.paymentPendingError.rawValue))
    }

    func testPurchasingNilProductIdentifierRetrunsError() {
        let product = StoreProduct(sk1Product: SK1Product())
        var receivedError: Error?
        self.purchases.purchase(product: product) { (_, _, error, _) in
            receivedError = error
        }

        expect(receivedError).to(matchError(ErrorCode.storeProblemError))
    }

    func testPostsOfferingIfPurchasingPackage() throws {
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        self.purchases.getOfferings { (newOfferings, _) in
            let package = newOfferings!["base"]!.monthly!
            self.purchases.purchase(package: package) { (_, _, _, _) in }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKitWrapper.payment!

            transaction.mockState = SKPaymentTransactionState.purchasing
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)

            transaction.mockState = SKPaymentTransactionState.purchased
            self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

            expect(self.backend.postReceiptDataCalled).to(beTrue())
            expect(self.backend.postedReceiptData).toNot(beNil())

            expect(self.backend.postedProductID).to(equal(package.storeProduct.productIdentifier))
            expect(self.backend.postedPrice) == package.storeProduct.price
            expect(self.backend.postedOfferingIdentifier).to(equal("base"))
            expect(self.storeKitWrapper.finishCalled).toEventually(beTrue())
        }
    }

    func testPurchasingPackageDoesntThrowPurchaseAlreadyInProgressIfCallbackMakesANewPurchase() throws {
        var receivedError: NSError?
        var secondCompletionCalled = false
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:], data: .mockResponse))
        )

        self.purchases.getOfferings { (newOfferings, _) in
            let package = newOfferings!["base"]!.monthly!
            self.purchases.purchase(package: package) { _, _, _, _  in
                self.purchases.purchase(package: package) { (_, _, error, _) in
                    receivedError = error as NSError?
                    secondCompletionCalled = true
                }
            }

            self.performTransaction()
            self.performTransaction()
        }

        expect(secondCompletionCalled).toEventually(beTrue(), timeout: .seconds(10))
        expect(receivedError).to(beNil())
    }

    func testCallsDelegateAfterBackendResponse() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        var customerInfo: CustomerInfo?
        var receivedError: Error?
        var receivedUserCancelled: Bool?

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
                "non_subscriptions": [product.productIdentifier: []]
            ]])
        self.backend.overrideCustomerInfoResult = .success(customerInfoBeforePurchase)
        self.backend.postReceiptResult = .success(customerInfoAfterPurchase)

        self.purchases.purchase(product: product) { (_, info, error, userCancelled) in
            customerInfo = info
            receivedError = error
            receivedUserCancelled = userCancelled
        }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(customerInfo).toEventually(equal(customerInfoAfterPurchase))
        expect(receivedError).toEventually(beNil())
        expect(self.purchasesDelegate.customerInfoReceivedCount).to(equal(2))
        expect(receivedUserCancelled).toEventually(beFalse())
    }

    func testCompletionBlockNotCalledForDifferentProducts() throws {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        let otherProduct = MockSK1Product(mockProductIdentifier: "com.product.id2")

        var callCount = 0

        self.purchases.purchase(product: product) { (_, _, _, _) in
            callCount += 1
        }

        let transaction = MockTransaction()
        transaction.mockPayment = SKPayment.init(product: otherProduct)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(callCount).toEventually(equal(0))
    }

    func testCallingPurchaseWhileSameProductPendingIssuesError() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))

        // First one "works"
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        var receivedInfo: CustomerInfo?
        var receivedError: NSError?
        var receivedUserCancelled: Bool?

        // Second one issues an error
        self.purchases.purchase(product: product) { (_, info, error, userCancelled) in
            receivedInfo = info
            receivedError = error as NSError?
            receivedUserCancelled = userCancelled
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedInfo).to(beNil())
        expect(receivedError?.domain) == RCPurchasesErrorCodeDomain
        expect(receivedError?.code) == ErrorCode.operationAlreadyInProgressForProductError.rawValue
        expect(self.storeKitWrapper.addPaymentCallCount) == 1
        expect(receivedUserCancelled) == false
    }

    func testTransitioningToPurchasing() {
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!
        transaction.mockState = SKPaymentTransactionState.purchasing

        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled).to(beFalse())
    }

    func testCachesCustomerInfo() throws {
        expect(self.deviceCache.cachedCustomerInfo.count).toEventually(equal(1))
        expect(self.deviceCache.cachedCustomerInfo[self.purchases.appUserID]).toEventuallyNot(beNil())

        let cachedData = try XCTUnwrap(self.deviceCache.cachedCustomerInfo[self.purchases.appUserID])
        try JSONSerialization.jsonObject(with: cachedData, options: [])
    }

    func testCachesCustomerInfoOnPurchase() throws {
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
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = try XCTUnwrap(self.storeKitWrapper.payment)

        transaction.mockState = .purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.deviceCache.cacheCustomerInfoCount).toEventually(equal(2))
    }

    func testWhenNoReceiptDataReceiptIsRefreshed() {
        self.receiptFetcher.shouldReturnReceipt = true
        self.receiptFetcher.shouldReturnZeroBytesReceipt = true

        self.makeAPurchase()

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always
    }

    func testPaymentSheetCancelledErrorIsParsedCorrectly() {
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

    func testSendsProductDataIfProductIsCached() throws {
        let productIdentifiers = ["com.product.id1", "com.product.id2"]

        self.purchases.getProducts(productIdentifiers) { newProducts in
            let product = newProducts[0]
            self.purchases.purchase(product: newProducts[0]) { (_, _, _, _) in }

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

    // MARK: -

    private func performTransaction() {
        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
        self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)
        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)
    }

}

class PurchasesPurchasingCustomSetupTests: BasePurchasesTests {

    func testReceiptsSendsAsRestoreWhenAnon() {
        self.setupAnonPurchases()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedIsRestore) == true
    }

    func testReceiptsSendsAsNotRestoreWhenAnonymousAndNotAllowingSharingAppStoreAccount() {
        self.setupAnonPurchases()

        var deprecated = purchases.deprecated
        deprecated.allowSharingAppStoreAccount = false
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedIsRestore) == false
    }

    func testDoesntPostTransactionsIfAutoSyncPurchasesSettingIsOffInObserverMode() throws {
        self.systemInfo = try MockSystemInfo(platformInfo: nil,
                                             finishTransactions: false,
                                             dangerousSettings: DangerousSettings(autoSyncPurchases: false))
        self.initializePurchasesInstance(appUserId: nil)

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(
            self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == false
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testDoesntPostTransactionsIfAutoSyncPurchasesSettingIsOff() throws {
        self.systemInfo = try MockSystemInfo(platformInfo: nil,
                                             finishTransactions: true,
                                             dangerousSettings: DangerousSettings(autoSyncPurchases: false))
        self.initializePurchasesInstance(appUserId: nil)

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == false
        // Sync purchases never finishes transactions
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testDoesntFinishTransactionsIfObserverModeIsSet() throws {
        try self.setupPurchasesObserverModeOn()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        self.backend.postReceiptResult = .success(try CustomerInfo(data: Self.emptyCustomerInfoData))

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

    func testReceiptsSendsObserverModeWhenObserverMode() throws {
        try self.setupPurchasesObserverModeOn()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.backend.postedObserverMode) == true
    }

    func testRestoredPurchasesArePosted() throws {
        try self.setupPurchasesObserverModeOn()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.storeKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.restored
        self.storeKitWrapper.delegate?.storeKitWrapper(self.storeKitWrapper, updatedTransaction: transaction)

        expect(self.backend.postReceiptDataCalled) == true
        expect(self.storeKitWrapper.finishCalled).toEventually(beFalse())
    }

}
