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

    func testIsSandboxIfReceiptURLIsSandbox() async {
        let detector = await SandboxEnvironmentDetector.with(receiptURLResult: .sandboxReceipt)
        expect(detector.isSandbox) == true
    }

    func testIsNotSandboxIfReceiptURLIsAppStore() async {
        let detector = await SandboxEnvironmentDetector.with(receiptURLResult: .appStoreReceipt)
        expect(detector.isSandbox) == false
    }

    func testIsNotSandboxIfNoReceiptURL() async {
        let detector = await SandboxEnvironmentDetector.with(receiptURLResult: .nilURL)
        expect(detector.isSandbox) == false
    }

    func testIsAlwaysSandboxIfRunningInSimulator() async {
        var detector = await SandboxEnvironmentDetector.with(receiptURLResult: .sandboxReceipt, inSimulator: true)
        expect(detector.isSandbox) == true

        detector = await SandboxEnvironmentDetector.with(receiptURLResult: .appStoreReceipt, inSimulator: true)
        expect(detector.isSandbox) == true

        detector = await SandboxEnvironmentDetector.with(receiptURLResult: .nilURL, inSimulator: true)
        expect(detector.isSandbox) == true
    }

    // MARK: - AppTransaction Environment Tests

    func testIsSandboxWhenAppTransactionEnvironmentIsSandbox() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            appTransactionEnvironment: .sandbox
        )
        expect(detector.isSandbox) == true
    }

    func testIsSandboxWhenAppTransactionEnvironmentIsXcode() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            appTransactionEnvironment: .xcode
        )
        expect(detector.isSandbox) == true
    }

    func testIsNotSandboxWhenAppTransactionEnvironmentIsProduction() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            appTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testAppTransactionEnvironmentTakesPrecedenceOverReceiptPath() async {
        // Receipt says sandbox, but AppTransaction says production
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            appTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testSimulatorTakesPrecedenceOverAppTransactionEnvironment() async {
        // AppTransaction says production, but we're in simulator
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            inSimulator: true,
            appTransactionEnvironment: .production
        )
        expect(detector.isSandbox) == true
    }

    func testFallsBackToSandboxReceiptPathWhenNoAppTransactionEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            appTransactionEnvironment: nil
        )
        expect(detector.isSandbox) == true
    }

    func testFallsBackToAppStoreReceiptPathWhenNoAppTransactionEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            appTransactionEnvironment: nil
        )
        expect(detector.isSandbox) == false
    }

    func testFallsBackToNilReceiptPathWhenNoAppTransactionEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .nilURL,
            appTransactionEnvironment: nil
        )
        expect(detector.isSandbox) == false
    }

    func testSimulatorTakesPrecedenceWhenNoAppTransactionEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            inSimulator: true,
            appTransactionEnvironment: nil
        )
        expect(detector.isSandbox) == true
    }

}

#else

// `macOS` sandbox detection does not rely on receipt path
class SandboxEnvironmentDetectorTests: TestCase {

    func testIsNotSandboxIfReceiptIsProduction() async {
        let detector = await SandboxEnvironmentDetector.with(
            macAppStore: true,
            receiptEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testIsSandboxIfReceiptIsNotProduction() async {
        let detector = await SandboxEnvironmentDetector.with(
            macAppStore: false,
            receiptEnvironment: .sandbox
        )
        expect(detector.isSandbox) == true
    }

    func testIsSandboxWhenReceiptEnvironmentIsUnknownDefaultToMacAppStoreDetector() async {
        var isSandbox = false
        var macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        var detector = await SandboxEnvironmentDetector.with(
            macAppStore: !isSandbox,
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
        expect(macAppStoreDetector.isMacAppStoreCalled) == true

        isSandbox = !isSandbox

        macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        detector = await SandboxEnvironmentDetector.with(
            macAppStore: !isSandbox,
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
    }

    func testIsSandboxWhenReceiptParsingFailsDefaultsToMacAppStoreDetector() async {
        var isSandbox = false
        var macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        var detector = await SandboxEnvironmentDetector.with(
            macAppStore: !isSandbox,
            failReceiptParsing: true,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
        expect(macAppStoreDetector.isMacAppStoreCalled) == true

        isSandbox = !isSandbox

        macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: !isSandbox)
        detector = await SandboxEnvironmentDetector.with(
            macAppStore: !isSandbox,
            failReceiptParsing: true,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == isSandbox
    }

    func testIsSandboxWhenReceiptIsProductionReturnsProductionAndDoesntHitMacAppStoreDetector() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
            macAppStore: false,
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector
        )

        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testIsSandboxWhenReceiptIsSandboxReturnsSandboxAndDoesntHitMacAppStoreDetector() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
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

private extension SandboxEnvironmentDetector {

    static func with(
        receiptURLResult result: MockBundle.ReceiptURLResult = .appStoreReceipt,
        inSimulator: Bool = false,
        macAppStore: Bool = false,
        receiptEnvironment: AppleReceipt.Environment = .production,
        failReceiptParsing: Bool = false,
        macAppStoreDetector: MockMacAppStoreDetector? = nil,
        appTransactionEnvironment: StoreEnvironment? = nil
    ) async -> SandboxEnvironmentDetector {
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

        let mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        mockTransactionFetcher.stubbedAppTransactionEnvironment = appTransactionEnvironment

        let detector = SandboxEnvironmentDetector(
            bundle: bundle,
            isRunningInSimulator: inSimulator,
            receiptFetcher: MockLocalReceiptFetcher(mockReceipt: mockReceipt,
                                                    failReceiptParsing: failReceiptParsing),
            macAppStoreDetector: macAppStoreDetector ?? MockMacAppStoreDetector(isMacAppStore: macAppStore),
            transactionFetcher: mockTransactionFetcher
        )

        // Wait for the async prefetch to complete
        await expect(mockTransactionFetcher.appTransactionEnvironmentCalled.value).toEventually(beTrue())

        return detector
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
