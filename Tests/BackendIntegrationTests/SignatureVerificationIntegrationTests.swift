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

    func testCustomerInfoWithInvalidSignature() async throws {
        self.invalidSignature = true

        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.verification) == .failed
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

        do {
            _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            fail("Expected error")
        } catch ErrorCode.signatureVerificationFailed {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

}
