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

}

class DisabledSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .disabled
    }

    func testFetchingCustomerInfoWithFailedSignature() async throws {
        self.invalidSignature = true

        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .notRequested
    }

}

class InformationalSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .informational(Signing.loadPublicKey())
    }

    func testCustomerInfoWithValidSignature() async throws {
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .verified
    }

    func testCustomerInfo304ResponseWithValidSignature() async throws {
        // 1. Fetch user once
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 1. Re-fetch user
        let user = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user.entitlements.verification) == .verified
    }

    func testLoggedInCustomerInfo304ResponseWithValidSignature() async throws {
        // 1. Log-in to force a new user
        _ = try await self.purchases.logIn(UUID().uuidString)

        // 2. Fetch user once
        let user1 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user1.entitlements.verification) == .verified

        // 3. Re-fetch user
        let user2 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user2.entitlements.verification) == .verified

        expect(user2.requestDate) != user1.requestDate
    }

    func testCustomerInfoWithInvalidSignature() async throws {
        self.invalidSignature = true

        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .failed
    }

    func testLogInWithValidSignature() async throws {
        let info = try await self.purchases.logIn(UUID().uuidString).customerInfo
        expect(info.entitlements.verification) == .verified
    }

    func testLogInWithInvalidSignature() async throws {
        self.invalidSignature = true

        let info = try await self.purchases.logIn(UUID().uuidString).customerInfo
        expect(info.entitlements.verification) == .failed
    }

    func testNotModifiedCustomerInfoWithInvalidSignature() async throws {
        // 1. Log-in to force a new user
        _ = try await self.purchases.logIn(UUID().uuidString)

        // 2. Fetch user once
        let user1 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(user1.entitlements.verification) == .verified

        // 3. Re-fetch user
        self.invalidSignature = true

        let user2 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 4. Verify failed verification returns original `requestDate`
        expect(user2.entitlements.verification) == .failed
        expect(user2.requestDate).to(beCloseToDate(user1.requestDate))
    }

    func testCanPurchaseWithInvalidSignatures() async throws {
        self.invalidSignature = true

        let user = try await self.purchaseMonthlyProduct().customerInfo
        expect(user.entitlements.verification) == .failed
    }

    func testOfferingsWithInvalidSignatureDontThrowError() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.invalidSignature = true

        try self.purchases.invalidateOfferingsCache()

        // Currently there's no API to detect signature failures
        // See also `EnforcedSignatureVerificationIntegrationTests.testOfferingsWithInvalidSignature`
        _ = try await self.purchases.offerings()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testEntitlementMappingWithInvalidSignatureDontThrowError() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.invalidSignature = true
        _ = try await self.purchases.productEntitlementMapping()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPostingReceiptInLieuOfCustomerInfoReturnsVerificationResult() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.serverDown()
        try await self.purchaseMonthlyOffering()

        self.serverUp()
        self.invalidSignature = true

        let customerInfo = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(customerInfo.entitlements.verification) == .failed
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

}

class EnforcedSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    func testCustomerInfoWithValidSignature() async throws {
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .verified
    }

    func testCustomerInfoWithInvalidSignature() async throws {
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        }
    }

    func testLogInWithValidSignature() async throws {
        let info = try await self.purchases.logIn(UUID().uuidString).customerInfo
        expect(info.entitlements.verification) == .verified
    }

    func testLogInWithInvalidSignature() async throws {
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await self.purchases.logIn(UUID().uuidString).customerInfo
        }
    }

    func testOfferingsWithInvalidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.invalidSignature = true

        try self.purchases.invalidateOfferingsCache()

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await self.purchases.offerings()
        }
    }

    func testOfferingsWithValidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try self.purchases.invalidateOfferingsCache()
        _ = try await self.purchases.offerings()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testEntitlementMappingWithInvalidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            _ = try await self.purchases.productEntitlementMapping()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testEntitlementMappingWithValidSignature() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        _ = try await self.purchases.productEntitlementMapping()
    }

    func testTransactionIsNotFinishedAfterSignatureFailure() async throws {
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            try await self.purchaseMonthlyProduct()
        }

        self.logger.verifyMessageWasNotLogged("Finishing transaction")
    }

    func testTransactionIsFinishedAfterSuccessfulyPostingPurchase() async throws {
        // 1. Purchase and receive invalid signature
        self.invalidSignature = true

        try await Self.verifyThrowsSignatureVerificationFailed {
            try await self.purchaseMonthlyProduct()
        }

        // 2. Get customer info again, which should post the pending transaction
        self.invalidSignature = false

        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 3. Verify entitlement is active
        try await self.verifyEntitlementWentThrough(info)

        // 4. Verify transaction was finished
        self.logger.verifyMessageWasLogged("Finishing transaction", level: .info)
    }

}

class DynamicModeSignatureVerificationIntegrationTests: BaseSignatureVerificationIntegrationTests {

    private static var currentMode: Signing.ResponseVerificationMode = .disabled

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return self.currentMode
    }

    override func setUp() async throws {
        Self.currentMode = .disabled

        try await super.setUp()
    }

    func testDisablingSignatureVerificationDoesNotResetCustomerInfoCache() async throws {
        // 1. Start with enforced mode
        await self.changeMode(to: Signing.enforcedVerificationMode())

        // 2. Fetch CustomerInfo
        _ = try await self.purchases.customerInfo()

        // 3. Disable verification again
        await self.changeMode(to: .disabled)

        // 4. Verify CustomerInfo is still cached
        _ = try await self.purchases.customerInfo(fetchPolicy: .fromCacheOnly)
    }

    func testChangingToInformationalModeResetsCustomerInfoCache() async throws {
        // 1. Fetch CustomerInfo
        _ = try await self.purchases.customerInfo()

        // 2. Enable signature verification
        await self.changeMode(to: Signing.verificationMode(with: .informational))

        // 3. Verify CustomerInfo is not cached anymore
        await self.verifyNoCachedCustomerInfo()
    }

    func testChangingToEnforcedModeResetsCustomerInfoCache() async throws {
        // 1. Fetch CustomerInfo
        _ = try await self.purchases.customerInfo()

        // 2. Enable signature verification
        await self.changeMode(to: Signing.enforcedVerificationMode())

        // 3. Verify CustomerInfo is not cached anymore
        await self.verifyNoCachedCustomerInfo()
    }

    private func changeMode(to newMode: Signing.ResponseVerificationMode) async {
        Self.currentMode = newMode
        await self.resetSingleton()
    }

    private func verifyNoCachedCustomerInfo() async {
        do {
            _ = try await self.purchases.customerInfo(fetchPolicy: .fromCacheOnly)
        } catch {
            expect(error).to(matchError(ErrorCode.customerInfoError))
            expect(error.localizedDescription)
                .to(
                    contain(Strings.purchase.missing_cached_customer_info.description),
                    description: "Unexpected error: \(error)"
                )
        }
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

    func waitForPendingCustomerInfoRequests() async {
        _ = try? await self.purchases.customerInfo()
    }

}
