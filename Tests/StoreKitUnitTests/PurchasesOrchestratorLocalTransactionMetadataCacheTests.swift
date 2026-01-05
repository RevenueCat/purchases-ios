//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorLocalTransactionMetadataCacheTests.swift
//
//  Created by Rick van der Linden on 30/12/2025.
//

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

// swiftlint:disable line_length

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheTests: BasePurchasesOrchestratorTests {

    // MARK: - Test Helpers

    func createPresentedOfferingContext() -> PresentedOfferingContext {
        let offeringIdentifier = UUID().uuidString
        let placementIdentifier = UUID().uuidString
        let revision = Int.random(in: 1...1000)
        let ruleId = UUID().uuidString

        return PresentedOfferingContext(
            offeringIdentifier: offeringIdentifier,
            placementIdentifier: placementIdentifier,
            targetingContext: .init(
                revision: revision,
                ruleId: ruleId
            )
        )
    }

    func createPackage(
        with product: StoreProduct,
        presentedOfferingContext: PresentedOfferingContext?,
        packageIdentifier: String? = nil
    ) -> Package {
        let packageId = packageIdentifier ?? UUID().uuidString
        return Package(
            identifier: packageId,
            packageType: .custom,
            storeProduct: product,
            presentedOfferingContext: presentedOfferingContext ?? .init(offeringIdentifier: UUID().uuidString),
            webCheckoutUrl: nil
        )
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheSK1Tests: PurchasesOrchestratorLocalTransactionMetadataCacheTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testMetadataIsStoredWhenPurchaseProductIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let storeTransaction = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, _, _, _ in
                continuation.resume(returning: transaction)
            }
        }

        let transaction = try XCTUnwrap(storeTransaction)

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.productIdentifier,
            presentedOfferingContext: nil,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.productIdentifier, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.productIdentifier, toTransactionID: transaction.id),
            .remove(productID: nil, transactionID: transaction.id),
            .remove(productID: product.productIdentifier, transactionID: nil)
        ]

        // Verify metadata has been removed after successful POST receipt
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testMetadataIsStoredWhenPurchasePackageIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = self.createPresentedOfferingContext()
        let package = self.createPackage(
            with: StoreProduct(sk1Product: product),
            presentedOfferingContext: presentedOfferingContext
        )

        let storeTransaction = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, _, _, _ in
                continuation.resume(returning: transaction)
            }
        }

        let transaction = try XCTUnwrap(storeTransaction)

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.productIdentifier,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.productIdentifier, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.productIdentifier, toTransactionID: transaction.id),
            .remove(productID: nil, transactionID: transaction.id),
            .remove(productID: product.productIdentifier, transactionID: nil)
        ]

        // Verify metadata has been removed after successful POST receipt
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testPresentedOfferingContextAndPaywallIncludedInPostReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        // Create package with presentedOfferingContext
        let presentedOfferingContext = self.createPresentedOfferingContext()
        let packageId = UUID().uuidString
        let package = self.createPackage(
            with: StoreProduct(sk1Product: product),
            presentedOfferingContext: presentedOfferingContext,
            packageIdentifier: packageId
        )

        let result = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let transaction = try XCTUnwrap(result.0)

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is included
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext?.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(transactionData.presentedOfferingContext?.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(transactionData.presentedOfferingContext?.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(transactionData.presentedOfferingContext?.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.productIdentifier,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.productIdentifier, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.productIdentifier, toTransactionID: transaction.id),
            .remove(productID: nil, transactionID: transaction.id),
            .remove(productID: product.productIdentifier, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testPaywallIncludedInPostReceiptWithoutPackage() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        // Purchase product without a package
        let result = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: nil,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let transaction = try XCTUnwrap(result.0)

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is not included when purchasing without a package
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext).to(beNil())

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.productIdentifier,
            presentedOfferingContext: nil,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.productIdentifier, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.productIdentifier, toTransactionID: transaction.id),
            .remove(productID: nil, transactionID: transaction.id),
            .remove(productID: product.productIdentifier, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testCachedPresentedOfferingContextIncludedInPostReceiptAndRemoved() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let payment = self.storeKit1Wrapper.payment(with: product)

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = self.createPresentedOfferingContext()
        orchestrator.cachePresentedOfferingContext(
            presentedOfferingContext,
            productIdentifier: product.productIdentifier
        )

        // Purchase product without a package
        let result = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: nil,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let transaction = try XCTUnwrap(result.0)

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is included in POST receipt
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext?.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(transactionData.presentedOfferingContext?.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(transactionData.presentedOfferingContext?.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(transactionData.presentedOfferingContext?.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        // Verify operation log (includes initial manual store + purchase flow)
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.productIdentifier,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.productIdentifier, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.productIdentifier, toTransactionID: transaction.id),
            .remove(productID: nil, transactionID: transaction.id),
            .remove(productID: product.productIdentifier, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheSK2Tests: PurchasesOrchestratorLocalTransactionMetadataCacheTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUp() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        try await super.setUp()

    }

    func testMetadataIsStoredWhenPurchaseProductIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let result = try await orchestrator.purchase(sk2Product: product,
                                                     package: nil,
                                                     promotionalOffer: nil,
                                                     winBackOffer: nil,
                                                     introductoryOfferEligibilityJWS: nil,
                                                     promotionalOfferOptions: nil)

        let transaction = try XCTUnwrap(result.transaction)

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.id,
            presentedOfferingContext: nil,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.id, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.id, toTransactionID: transaction.transactionIdentifier),
            .remove(productID: nil, transactionID: transaction.transactionIdentifier),
            .remove(productID: product.id, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testMetadataIsStoredWhenPurchasePackageIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = self.createPresentedOfferingContext()
        let package = self.createPackage(
            with: StoreProduct(sk2Product: product),
            presentedOfferingContext: presentedOfferingContext
        )

        let result = try await orchestrator.purchase(sk2Product: product,
                                                     package: package,
                                                     promotionalOffer: nil,
                                                     winBackOffer: nil,
                                                     introductoryOfferEligibilityJWS: nil,
                                                     promotionalOfferOptions: nil)

        let transaction = try XCTUnwrap(result.transaction)

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.id,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.id, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.id, toTransactionID: transaction.transactionIdentifier),
            .remove(productID: nil, transactionID: transaction.transactionIdentifier),
            .remove(productID: product.id, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testPresentedOfferingContextAndPaywallIncludedInPostReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        // Create package with presentedOfferingContext
        let presentedOfferingContext = self.createPresentedOfferingContext()
        let packageId = UUID().uuidString
        let package = self.createPackage(
            with: StoreProduct(sk2Product: product),
            presentedOfferingContext: presentedOfferingContext,
            packageIdentifier: packageId
        )

        let result = try await self.orchestrator.purchase(
            sk2Product: product,
            package: package,
            promotionalOffer: nil,
            winBackOffer: nil,
            introductoryOfferEligibilityJWS: nil,
            promotionalOfferOptions: nil
        )

        let transaction = try XCTUnwrap(result.transaction)

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is included
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext?.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(transactionData.presentedOfferingContext?.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(transactionData.presentedOfferingContext?.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(transactionData.presentedOfferingContext?.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.id,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.id, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.id, toTransactionID: transaction.transactionIdentifier),
            .remove(productID: nil, transactionID: transaction.transactionIdentifier),
            .remove(productID: product.id, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testPaywallIncludedInPostReceiptWithoutPackage() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        // Purchase product without a package
        let result = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil,
            introductoryOfferEligibilityJWS: nil,
            promotionalOfferOptions: nil
        )

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is not included when purchasing without a package
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext).to(beNil())

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        let transaction = try XCTUnwrap(result.transaction)

        // Verify operation log
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.id,
            presentedOfferingContext: nil,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.id, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.id, toTransactionID: transaction.transactionIdentifier),
            .remove(productID: nil, transactionID: transaction.transactionIdentifier),
            .remove(productID: product.id, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }

    func testCachedPresentedOfferingContextIncludedInPostReceiptAndRemoved() async throws {
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        // Track paywall impression
        self.orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = self.createPresentedOfferingContext()
        orchestrator.cachePresentedOfferingContext(
            presentedOfferingContext,
            productIdentifier: product.id
        )

        // Purchase product without a package
        let result = try await self.orchestrator.purchase(
            sk2Product: product,
            package: nil,
            promotionalOffer: nil,
            winBackOffer: nil,
            introductoryOfferEligibilityJWS: nil,
            promotionalOfferOptions: nil
        )

        let transaction = try XCTUnwrap(result.transaction)

        // Verify POST receipt was called
        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptData).to(beTrue())

        // Verify presentedOfferingContext is included in POST receipt
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        expect(transactionData.presentedOfferingContext?.offeringIdentifier) == presentedOfferingContext.offeringIdentifier
        expect(transactionData.presentedOfferingContext?.placementIdentifier) == presentedOfferingContext.placementIdentifier
        expect(transactionData.presentedOfferingContext?.targetingContext?.revision) == presentedOfferingContext.targetingContext?.revision
        expect(transactionData.presentedOfferingContext?.targetingContext?.ruleId) == presentedOfferingContext.targetingContext?.ruleId

        // Verify presentedPaywall is included
        expect(transactionData.presentedPaywall) == Self.paywallEvent

        // Verify operation log (includes initial manual store + purchase flow)
        let expectedMetadata = LocalTransactionMetadata(
            appUserID: Self.mockUserID,
            productIdentifier: product.id,
            presentedOfferingContext: presentedOfferingContext,
            paywallPostReceiptData: Self.paywallEvent.toPostReceiptData,
            observerMode: !self.orchestrator.finishTransactions
        )
        expect(self.localTransactionMetadataCache.log) == [
            .store(productID: product.id, transactionID: nil, metadata: expectedMetadata),
            .migrate(fromProductID: product.id, toTransactionID: transaction.transactionIdentifier),
            .remove(productID: nil, transactionID: transaction.transactionIdentifier),
            .remove(productID: product.id, transactionID: nil)
        ]

        // Ensure transaction metadata has been removed
        expect(self.localTransactionMetadataCache.retrieve(for: transaction)).to(beNil())
    }
}

// TODO: add sk2 transaction queue listener

extension NetworkError {

    static func serverDown(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .errorResponse(
            .init(code: .internalServerError, originalCode: BackendErrorCode.internalServerError.rawValue),
            .internalServerError,
            file: file,
            function: function,
            line: line
        )
    }
}

// swiftlint:enable line_length
