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
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheSK1Tests: BasePurchasesOrchestratorTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testMetadataIsStoredWhenPurchaseProductIsInitiated() async throws {
        let product = try await self.fetchSk1Product()
        let payment = storeKit1Wrapper.payment(with: product)

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
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
// swiftlint:disable:next type_name
class PurchasesOrchestratorLocalTransactionMetadataCacheSK2Tests: BasePurchasesOrchestratorTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUp() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        try await super.setUp()

    }

    func testMetadataIsStoredWhenPurchaseProductIsInitiated() async throws {
        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()

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
