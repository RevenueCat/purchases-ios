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

    // MARK: - AppTransaction Environment Tests

    func testIsSandboxWhenCachedAppTransactionEnvironmentIsSandbox() {
        let detector = SystemInfo.with(
            receiptURLResult: .appStoreReceipt,
            cachedAppTransactionEnvironment: .sandbox
        )
        expect(detector.isSandbox) == true
    }

    func testIsSandboxWhenCachedAppTransactionEnvironmentIsXcode() {
        let detector = SystemInfo.with(
            receiptURLResult: .appStoreReceipt,
            cachedAppTransactionEnvironment: .xcode
        )
        expect(detector.isSandbox) == true
    }

    func testIsNotSandboxWhenCachedAppTransactionEnvironmentIsProduction() {
        let detector = SystemInfo.with(
            receiptURLResult: .sandboxReceipt,
            cachedAppTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testCachedAppTransactionEnvironmentTakesPrecedenceOverReceiptPath() {
        // Receipt says sandbox, but AppTransaction says production
        let detector = SystemInfo.with(
            receiptURLResult: .sandboxReceipt,
            cachedAppTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testSimulatorTakesPrecedenceOverCachedAppTransactionEnvironment() {
        // AppTransaction says production, but we're in simulator
        let detector = SystemInfo.with(
            receiptURLResult: .appStoreReceipt,
            inSimulator: true,
            cachedAppTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == true
    }

    func testFallsBackToReceiptPathWhenNoCachedAppTransactionEnvironment() {
        let detector = SystemInfo.with(
            receiptURLResult: .sandboxReceipt,
            cachedAppTransactionEnvironment: nil
        )
        expect(detector.isSandbox) == true
    }

}

#else

// `macOS` sandbox detection does not rely on receipt path
class SandboxEnvironmentDetectorTests: TestCase {

    func testIsNotSandboxIfReceiptIsProduction() throws {
        expect(
            SystemInfo.with(
                macAppStore: true,
                receiptEnvironment: .production
            ).isSandbox
        ) == false
    }

    func testIsSandboxIfReceiptIsNotProduction() throws {
        expect(
            SystemInfo.with(
                macAppStore: false,
                receiptEnvironment: .sandbox
            ).isSandbox
        ) == true
    }

    func testIsSandboxWhenReceiptEnvironmentIsUnknownDefaultToMacAppStoreDetector() throws {
        var isSandbox = false
        var macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        var detector = SystemInfo.with(
            macAppStore: !isSandbox,
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
        expect(macAppStoreDetector.isMacAppStoreCalled) == true

        isSandbox = !isSandbox

        macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        detector = SystemInfo.with(
            macAppStore: !isSandbox,
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
    }

    func testIsSandboxWhenReceiptParsingFailsDefaultsToMacAppStoreDetector() throws {
        var isSandbox = false
        var macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        var detector = SystemInfo.with(
            macAppStore: !isSandbox,
            failReceiptParsing: true,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
        expect(macAppStoreDetector.isMacAppStoreCalled) == true

        isSandbox = !isSandbox

        macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        detector = SystemInfo.with(
            macAppStore: !isSandbox,
            failReceiptParsing: true,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
    }

    func testIsSandboxWhenReceiptIsProductionReturnsProductionAndDoesntHitMacAppStoreDetector() throws {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = SystemInfo.with(
            macAppStore: false,
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testIsSandboxWhenReceiptIsSandboxReturnsSandboxAndDoesntHitMacAppStoreDetector() throws {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = SystemInfo.with(
            macAppStore: false,
            receiptEnvironment: .sandbox,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

}

#endif

// MARK: - Private

private extension SystemInfo {

    static func with(
        receiptURLResult result: MockBundle.ReceiptURLResult = .appStoreReceipt,
        inSimulator: Bool = false,
        macAppStore: Bool = false,
        receiptEnvironment: AppleReceipt.Environment = .production,
        failReceiptParsing: Bool = false,
        macAppStoreDetector: MockMacAppStoreDetector? = nil,
        cachedAppTransactionEnvironment: StoreEnvironment? = nil
    ) -> SandboxEnvironmentDetectorType {
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

        return SandboxEnvironmentDetector(
            bundle: bundle,
            isRunningInSimulator: inSimulator,
            receiptFetcher: MockLocalReceiptFetcher(mockReceipt: mockReceipt,
                                                    failReceiptParsing: failReceiptParsing),
            macAppStoreDetector: macAppStoreDetector ?? MockMacAppStoreDetector(isMacAppStore: macAppStore),
            cachedAppTransactionEnvironment: cachedAppTransactionEnvironment
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

private final class MockMacAppStoreDetector: MacAppStoreDetector, @unchecked Sendable {

    let isMacAppStoreValue: Bool
    private(set) var isMacAppStoreCalled = false

    init(isMacAppStore: Bool) {
        self.isMacAppStoreValue = isMacAppStore
    }

    var isMacAppStore: Bool {
        isMacAppStoreCalled = true
        return isMacAppStoreValue
    }
}
