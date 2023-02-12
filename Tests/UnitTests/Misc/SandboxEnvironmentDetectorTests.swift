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
        expect(try SystemInfo.with(receiptResult: .sandboxReceipt, inSimulator: false).isSandbox) == true
    }

    func testIsNotSandbox() throws {
        expect(try SystemInfo.with(receiptResult: .receiptWithData, inSimulator: false).isSandbox) == false
    }

    func testIsNotSandboxIfNoReceiptURL() throws {
        expect(try SystemInfo.with(receiptResult: .nilURL, inSimulator: false).isSandbox) == false
    }

    func testMacSandboxReceiptIsSandbox() throws {
        expect(try SystemInfo.with(receiptResult: .macOSSandboxReceipt, inSimulator: false).isSandbox) == true
    }

    func testMacAppStoreReceiptIsNotSandbox() throws {
        expect(try SystemInfo.with(receiptResult: .macOSAppStoreReceipt, inSimulator: false).isSandbox) == false
    }

    func testIsAlwaysSandboxIfRunningInSimulator() {
        expect(try SystemInfo.with(receiptResult: .sandboxReceipt, inSimulator: true).isSandbox) == true
        expect(try SystemInfo.with(receiptResult: .receiptWithData, inSimulator: true).isSandbox) == true
        expect(try SystemInfo.with(receiptResult: .nilURL, inSimulator: true).isSandbox) == true
    }

}

private extension SandboxEnvironmentDetector {

    static func with(
        receiptResult result: MockBundle.ReceiptURLResult,
        inSimulator: Bool
    ) throws -> SandboxEnvironmentDetector {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        return BundleSandboxEnvironmentDetector(bundle: bundle, isRunningInSimulator: inSimulator)
    }

}
