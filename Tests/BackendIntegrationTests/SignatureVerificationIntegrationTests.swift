//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SignatureVerificationIntegrationTests.swift
//
//  Created by Nacho Soto on 6/13/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

// swiftlint:disable type_name

class BaseSignatureVerificationIntegrationTests: BaseStoreKitIntegrationTests {

    override var forceSignatureFailures: Bool { return self.invalidSignature }

    fileprivate var invalidSignature: Bool = false

    override func setUp() async throws {
        self.invalidSignature = false
        try await super.setUp()

        await self.waitForPendingCustomerInfoRequests()
    }

    private func waitForPendingCustomerInfoRequests() async {
        _ = try? await Purchases.shared.customerInfo()
    }

}

class DisabledSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .disabled
    }

    func testFetchingCustomerInfoWithFailedSignature() async throws {
        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .notRequested
    }

}

class InformationalSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .informational(Signing.loadPublicKey())
    }

    func testCustomerInfoWithValidSignature() async throws {
        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .verified
    }

    func testCustomerInfo304ResponseWithValidSignature() async throws {
        // 1. Fetch user once
        _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        // 1. Re-fetch user
        let user = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user.entitlements.verification) == .verified
    }

    func testLoggedInCustomerInfo304ResponseWithValidSignature() async throws {
        // 1. Log-in to force a new user
        _ = try await Purchases.shared.logIn(UUID().uuidString)

        // 2. Fetch user once
        let user1 = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user1.entitlements.verification) == .verified

        // 3. Re-fetch user
        let user2 = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user2.entitlements.verification) == .verified

        expect(user2.requestDate) != user1.requestDate
    }

    func testCustomerInfoWithInvalidSignature() async throws {
        self.invalidSignature = true

        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .failed
    }

    func testNotModifiedCustomerInfoWithInvalidSignature() async throws {
        // 1. Log-in to force a new user
        _ = try await Purchases.shared.logIn(UUID().uuidString)

        // 2. Fetch user once
        let user1 = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user1.entitlements.verification) == .verified

        // 3. Re-fetch user
        self.invalidSignature = true

        let user2 = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        // 4. Verify failed verification returns original `requestDate`
        expect(user2.entitlements.verification) == .failed
        expect(user2.requestDate).to(beCloseToDate(user1.requestDate))
    }

    func testCanPurchaseWithInvalidSignatures() async throws {
        self.invalidSignature = true

        let user = try await self.purchaseMonthlyProduct().customerInfo
        expect(user.entitlements.verification) == .failed
    }

}

class EnforcedSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    func testCustomerInfoWithValidSignature() async throws {
        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .verified
    }

    func testCustomerInfoWithInvalidSignature() async throws {
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testEntitlementMappingWithInvalidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        XCTExpectFailure("Not implemented yet")

        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await Purchases.shared.productEntitlementMapping()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testEntitlementMappingWithValidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        _ = try await Purchases.shared.productEntitlementMapping()
    }

    func testTransactionIsNotFinishedAfterSignatureFailure() async throws {
        let logger = TestLogHandler()

        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            try await self.purchaseMonthlyProduct()
        }

        logger.verifyMessageWasNotLogged("Finishing transaction")
    }

    func testTransactionIsFinishedAfterSuccessfulyPostingPurchase() async throws {
        // 1. Purchase and receive invalid signature
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            try await self.purchaseMonthlyProduct()
        }

        // 2. Get customer info again, which should post the pending transaction
        self.invalidSignature = false

        let logger = TestLogHandler()
        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)

        // 3. Verify entitlement is active
        try await self.verifyEntitlementWentThrough(info)

        // 4. Verify transaction was finished
        logger.verifyMessageWasLogged("Finishing transaction", level: .info)
    }

}

// MARK: - Private

private extension BaseSignatureVerificationIntegrationTests {

    static func verifyThrowsSignatureVerificationFailed(_ method: () async throws -> Void) async throws {
        do {
            try await method()
            fail("Expected error")
        } catch ErrorCode.signatureVerificationFailed {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

}
