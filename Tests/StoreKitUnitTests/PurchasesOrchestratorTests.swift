//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorTests.swift
//
//  Created by Mark Villacampa on 20/2/24.

protocol PurchasesOrchestratorTests {

    // MARK: - StoreFront Changes

    func testClearCachedProductsAndOfferingsAfterStorefrontChanges() async throws

    // MARK: - Purchasing

    func testPurchasePostsReceipt() async throws

    func testPurchaseReturnsCorrectValues() async throws

    func testPurchaseDoesNotPostReceiptIfPurchaseFailed() async throws

    func testPurchaseWithPromotionalOfferPostsReceiptIfSuccessful() async throws

    func testPurchaseWithInvalidPromotionalOfferSignatureFails() async throws

    // MARK: - Paywalls

    func testPurchaseWithPresentedPaywall() async throws

    func testPurchaseFailureRemembersPresentedPaywall() async throws

    // MARK: - AdServices and Attributes

    func testPurchaseDoesNotPostAdServicesTokenIfNotEnabled() async throws

    #if !os(tvOS) && !os(watchOS)
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testPurchasePostsAdServicesTokenAndSubscriberAttributes() async throws
    #endif

    // MARK: - Promotional Offers

    func testGetPromotionalOfferWorksIfThereIsATransaction() async throws

    func testGetPromotionalOfferFailsWithIneligibleIfNoTransactionIsFound() async throws

    func testGetPromotionalOfferFailsWithIneligibleIfBackendReturnsIneligible() async throws

    // MARK: - Sync Purchases

    func testSyncPurchasesPostsReceipt() async throws

    func testSyncPurchasesDoesntPostReceiptAndReturnsCustomerInfoIfNoTransaction() async throws

    func testSyncPurchasesCallsSuccessDelegateMethod() async throws

    func testSyncPurchasesPassesErrorOnFailure() async throws

}
