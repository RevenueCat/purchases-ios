//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VerificationResultTests.swift
//
//  Created by Nacho Soto on 7/11/23.

import Nimble
import XCTest

@testable import RevenueCat

class VerificationResultTests: TestCase {

    func testIsVerified() {
        expect(VerificationResult.notRequested.isVerified) == false
        expect(VerificationResult.failed.isVerified) == false
        expect(VerificationResult.verified.isVerified) == true
        expect(VerificationResult.verifiedOnDevice.isVerified) == true
    }

    func testSignatureVerificationResultIsFailed() {
        expect(SignatureVerificationResult.notRequested.isFailed) == false
        expect(SignatureVerificationResult.verified.isFailed) == false
        expect(SignatureVerificationResult.failed(.unknown).isFailed) == true
    }

    func testPublicResultFromSignatureVerificationResult() {
        expect(SignatureVerificationResult.notRequested.result) == .notRequested
        expect(SignatureVerificationResult.verified.result) == .verified
        expect(SignatureVerificationResult.failed(.missingSignature).result) == .failed
    }

    func testSignatureVerificationFailureReason() {
        expect(SignatureVerificationResult.notRequested.failureReason).to(beNil())
        expect(SignatureVerificationResult.verified.failureReason).to(beNil())
        expect(SignatureVerificationResult.failed(.missingSignature).failureReason) == .missingSignature
    }

    func testSignatureVerificationFailureReasonRawValues() {
        expect(SignatureVerificationResult.FailureReason.missingSignature.rawValue) == "MISSING_SIGNATURE"
        expect(SignatureVerificationResult.FailureReason.missingRequestTime.rawValue) == "MISSING_REQUEST_TIME"
        expect(SignatureVerificationResult.FailureReason.missingSignedPayload.rawValue) == "MISSING_SIGNED_PAYLOAD"
        expect(SignatureVerificationResult.FailureReason.invalidSignatureFormat.rawValue) == "INVALID_SIGNATURE_FORMAT"
        expect(SignatureVerificationResult.FailureReason.invalidIntermediateKeySignature.rawValue) ==
            "INVALID_INTERMEDIATE_KEY_SIGNATURE"
        expect(SignatureVerificationResult.FailureReason.invalidIntermediateKey.rawValue) ==
            "INVALID_INTERMEDIATE_KEY"
        expect(SignatureVerificationResult.FailureReason.invalidResponsePayload.rawValue) ==
            "INVALID_RESPONSE_PAYLOAD"
        expect(SignatureVerificationResult.FailureReason.intermediateKeyExpired.rawValue) ==
            "INTERMEDIATE_KEY_EXPIRED"
        expect(SignatureVerificationResult.FailureReason.payloadSignatureMismatch.rawValue) ==
            "PAYLOAD_SIGNATURE_MISMATCH"
        expect(SignatureVerificationResult.FailureReason.unknown.rawValue) == "UNKNOWN"
    }

}
