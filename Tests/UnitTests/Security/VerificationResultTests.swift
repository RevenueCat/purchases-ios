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

}
