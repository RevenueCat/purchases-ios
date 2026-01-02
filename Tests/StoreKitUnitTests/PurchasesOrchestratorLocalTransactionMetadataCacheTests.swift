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

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PurchasesOrchestratorLocalTransactionMetadataCacheTests: BasePurchasesOrchestratorTests {

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheSK1Tests: PurchasesOrchestratorLocalTransactionMetadataCacheTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testMetadataIsStoredWhenPurchaseProductIsInitiated() async throws {
        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let storeTransaction = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: nil,
                                  wrapper: self.storeKit1Wrapper) { transaction, _, _, _ in
                continuation.resume(returning: transaction)
                // TODO: can we verify stored by productID before migrated to transactionID?
            }
        }

        let transaction = try XCTUnwrap(storeTransaction)
        let metadata = try XCTUnwrap(localTransactionMetadataCache.retrieve(forTransactionID: transaction.id))
        expect(metadata.productIdentifier) == product.productIdentifier
        expect(metadata.appUserID) == Self.mockUserID
        expect(metadata.paywallPostReceiptData) == Self.paywallEvent.toPostReceiptData
    }

    func testMetadataIsStoredWhenPurchasePackageIsInitiated() async throws {
        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = PresentedOfferingContext(
            offeringIdentifier: "my-custom-offering",
            placementIdentifier: "my-custom-placement",
            targetingContext: .init(
                revision: 23,
                ruleId: "my-rule-id"
            )
        )

        let package = Package(
            identifier: "test",
            packageType: .custom,
            storeProduct: StoreProduct(sk1Product: product),
            presentedOfferingContext: presentedOfferingContext,
            webCheckoutUrl: nil
        )

        let storeTransaction = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, _, _, _ in
                continuation.resume(returning: transaction)
                // TODO: can we verify stored by productID before migrated to transactionID?
            }
        }

        let transaction = try XCTUnwrap(storeTransaction)
        let metadata = try XCTUnwrap(localTransactionMetadataCache.retrieve(forTransactionID: transaction.id))
        expect(metadata.productIdentifier) == product.productIdentifier
        expect(metadata.appUserID) == Self.mockUserID
        expect(metadata.paywallPostReceiptData) == Self.paywallEvent.toPostReceiptData
        expect(metadata.presentedOfferingContext?.offeringIdentifier) == "my-custom-offering"
        expect(metadata.presentedOfferingContext?.placementIdentifier) == "my-custom-placement"
        expect(metadata.presentedOfferingContext?.targetingContext?.revision) == 23
        expect(metadata.presentedOfferingContext?.targetingContext?.ruleId) == "my-rule-id"
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

        let transactionIdentifier = try XCTUnwrap(result.transaction?.transactionIdentifier)

        let metadata = try XCTUnwrap(localTransactionMetadataCache.retrieve(forTransactionID: transactionIdentifier))
        expect(metadata.productIdentifier) == product.id
        expect(metadata.appUserID) == Self.mockUserID
        expect(metadata.paywallPostReceiptData) == Self.paywallEvent.toPostReceiptData
    }

    func testMetadataIsStoredWhenPurchasePackageIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        orchestrator.track(paywallEvent: .impression(Self.paywallEventCreationData, Self.paywallEvent))

        let presentedOfferingContext = PresentedOfferingContext(
            offeringIdentifier: "my-custom-offering",
            placementIdentifier: "my-custom-placement",
            targetingContext: .init(
                revision: 23,
                ruleId: "my-rule-id"
            )
        )

        let package = Package(
            identifier: "test",
            packageType: .custom,
            storeProduct: StoreProduct(sk2Product: product),
            presentedOfferingContext: presentedOfferingContext,
            webCheckoutUrl: nil
        )

        let result = try await orchestrator.purchase(sk2Product: product,
                                                     package: package,
                                                     promotionalOffer: nil,
                                                     winBackOffer: nil,
                                                     introductoryOfferEligibilityJWS: nil,
                                                     promotionalOfferOptions: nil)

        let transactionIdentifier = try XCTUnwrap(result.transaction?.transactionIdentifier)

        let metadata = try XCTUnwrap(localTransactionMetadataCache.retrieve(forTransactionID: transactionIdentifier))
        expect(metadata.productIdentifier) == product.id
        expect(metadata.appUserID) == Self.mockUserID
        expect(metadata.paywallPostReceiptData) == Self.paywallEvent.toPostReceiptData
        expect(metadata.presentedOfferingContext?.offeringIdentifier) == "my-custom-offering"
        expect(metadata.presentedOfferingContext?.placementIdentifier) == "my-custom-placement"
        expect(metadata.presentedOfferingContext?.targetingContext?.revision) == 23
        expect(metadata.presentedOfferingContext?.targetingContext?.ruleId) == "my-rule-id"
    }
}

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
