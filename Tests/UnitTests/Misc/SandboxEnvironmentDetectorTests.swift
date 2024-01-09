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

    override func setUpWithError() throws {
        try super.setUpWithError()

        // `macOS` sandbox detection does not rely on receipt path
        try AvailabilityChecks.skipIfMacOS()
    }

    func testIsSandboxIfReceiptURLIsSandbox() {
        expect(SystemInfo.with(receiptURLResult: .sandboxReceipt).isSandbox) == true
    }

    func testIsNotSandboxIfReceiptURLIsAppStore() {
        expect(SystemInfo.with(receiptURLResult: .appStoreReceipt).isSandbox) == false
    }

    func testIsNotSandboxIfNoReceiptURL() {
        expect(SystemInfo.with(receiptURLResult: .nilURL).isSandbox) == false
    }

    func testIsAlwaysSandboxIfRunningInSimulator() {
        expect(SystemInfo.with(receiptURLResult: .sandboxReceipt, inSimulator: true).isSandbox) == true
        expect(SystemInfo.with(receiptURLResult: .appStoreReceipt, inSimulator: true).isSandbox) == true
        expect(SystemInfo.with(receiptURLResult: .nilURL, inSimulator: true).isSandbox) == true
    }

    func testIsNotSandboxIfReceiptIsProduction() throws {
        try AvailabilityChecks.skipIfNotMacOS()

        expect(SystemInfo.with(receiptEnvironment: .production).isSandbox) == false
    }

    func testIsSandboxIfReceiptIsNotProduction() throws {
        try AvailabilityChecks.skipIfNotMacOS()

        expect(SystemInfo.with(receiptEnvironment: .sandbox).isSandbox) == true
    }

    func testIsSandboxIfReceiptParsingFailsAndBundleSignatureIsNotMacAppStore() throws {
        try AvailabilityChecks.skipIfNotMacOS()

        expect(SystemInfo.with(
            receiptEnvironment: .production,
            failReceiptParsing: true
        ).isSandbox) == true
    }

}

private extension SandboxEnvironmentDetector {

    static func with(
        receiptURLResult result: MockBundle.ReceiptURLResult = .appStoreReceipt,
        inSimulator: Bool = false,
        receiptEnvironment: AppleReceipt.Environment = .production,
        failReceiptParsing: Bool = false
    ) -> SandboxEnvironmentDetector {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let mockReceipt = AppleReceipt(
            environment: receiptEnvironment,
            bundleId: "bundle",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: []
        )

        return BundleSandboxEnvironmentDetector(
            bundle: bundle,
            isRunningInSimulator: inSimulator,
            receiptFetcher: MockLocalReceiptFetcher(mockReceipt: mockReceipt,
                                                    failReceiptParsing: failReceiptParsing)
        )
    }

}

private final class MockLocalReceiptFetcher: LocalReceiptFetcherType {

    let mockReceipt: AppleReceipt
    let failReceiptParsing: Bool

    init(mockReceipt: AppleReceipt, failReceiptParsing: Bool) {
        self.mockReceipt = mockReceipt
        self.failReceiptParsing = failReceiptParsing
    }

    func fetchAndParseLocalReceipt() throws -> RevenueCat.AppleReceipt {
        if failReceiptParsing {
            throw PurchasesReceiptParser.Error.receiptParsingError
        }
        return self.mockReceipt
    }

}
