//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SandboxEnvironmentDetectorTests.swift
//
//  Created by Nacho Soto on 6/2/22.

import Nimble
import XCTest

@testable import RevenueCat

class SandboxEnvironmentDetectorTests: TestCase {

    func testIsSandbox() throws {
        expect(try SystemInfo.withReceiptResult(.sandboxReceipt).isSandbox) == true
    }

    func testIsNotSandbox() throws {
        expect(try SystemInfo.withReceiptResult(.receiptWithData).isSandbox) == false
    }

    func testIsNotSandboxIfNoReceiptURL() throws {
        expect(try SystemInfo.withReceiptResult(.nilURL).isSandbox) == false
    }

}

private extension SandboxEnvironmentDetector {

    static func withReceiptResult(_ result: MockBundle.ReceiptURLResult) throws -> SandboxEnvironmentDetector {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        return BundleSandboxEnvironmentDetector(bundle: bundle)
    }

}
