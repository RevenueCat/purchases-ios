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

#if !os(macOS)

class SandboxEnvironmentDetectorTests: TestCase {

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

}

#else

// `macOS` sandbox detection does not rely on receipt path
class SandboxEnvironmentDetectorTests: TestCase {

    func testIsNotSandboxIfReceiptIsProductionAndMAS() throws {
        expect(
            SystemInfo.with(
                macAppStore: true,
                receiptEnvironment: .production
            ).isSandbox
        ) == false
    }

    func testIsSandboxIfReceiptIsProductionAndNotMAS() throws {
        expect(
            SystemInfo.with(
                macAppStore: false,
                receiptEnvironment: .production
            ).isSandbox
        ) == true
    }

    func testIsSandboxIfReceiptIsNotProductionAndNotMAS() throws {
        expect(
            SystemInfo.with(
                macAppStore: false,
                receiptEnvironment: .sandbox
            ).isSandbox
        ) == true
    }

    func testIsSandboxIfReceiptIsNotProductionAndMAS() throws {
        expect(
            SystemInfo.with(
                macAppStore: true,
                receiptEnvironment: .sandbox
            ).isSandbox
        ) == true
    }

    func testIsSandboxIfReceiptParsingFailsAndBundleSignatureIsNotMAS() throws {
        expect(
            SystemInfo.with(
                macAppStore: false,
                receiptEnvironment: .production,
                failReceiptParsing: true
            ).isSandbox
        ) == true
    }

}

#endif

// MARK: - Private

private extension SandboxEnvironmentDetector {

    static func with(
        receiptURLResult result: MockBundle.ReceiptURLResult = .appStoreReceipt,
        inSimulator: Bool = false,
        macAppStore: Bool = false,
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
                                                    failReceiptParsing: failReceiptParsing),
            macAppStoreDetector: MockMacAppStoreDetector(isMacAppStore: macAppStore)
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

private struct MockMacAppStoreDetector: MacAppStoreDetector {

    let isMacAppStore: Bool

    init(isMacAppStore: Bool) {
        self.isMacAppStore = isMacAppStore
    }

}
