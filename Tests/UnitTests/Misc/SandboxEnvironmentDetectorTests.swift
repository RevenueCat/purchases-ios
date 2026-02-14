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

    // MARK: - Prefetched Receipt Environment Tests

    func testIsSandboxWhenPrefetchedReceiptEnvironmentIsSandbox() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            prefetchedReceiptEnvironment: .sandbox
        )
        expect(detector.isSandbox) == true
    }

    func testIsSandboxWhenPrefetchedReceiptEnvironmentIsXcode() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            prefetchedReceiptEnvironment: .xcode
        )
        expect(detector.isSandbox) == true
    }

    func testIsNotSandboxWhenPrefetchedReceiptEnvironmentIsProduction() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            prefetchedReceiptEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testPrefetchedReceiptEnvironmentTakesPrecedenceOverReceiptPath() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            prefetchedReceiptEnvironment: .production
        )
        expect(detector.isSandbox) == false
    }

    func testSimulatorTakesPrecedenceOverPrefetchedReceiptEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            inSimulator: true,
            prefetchedReceiptEnvironment: .production
        )
        expect(detector.isSandbox) == true
    }

    func testFallsBackToSandboxReceiptPathWhenNoPrefetchedReceiptEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .sandboxReceipt,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == true
    }

    func testFallsBackToAppStoreReceiptPathWhenNoPrefetchedReceiptEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == false
    }

    func testFallsBackToNilReceiptPathWhenNoPrefetchedReceiptEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .nilURL,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == false
    }

    func testSimulatorTakesPrecedenceWhenNoPrefetchedReceiptEnvironment() async {
        let detector = await SandboxEnvironmentDetector.with(
            receiptURLResult: .appStoreReceipt,
            inSimulator: true,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == true
    }

    // MARK: - Prefetch Receipt Pending

    func testUsesReceiptPathBeforePrefetchCompletes() async {
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptURLResult: .sandboxReceiptMissingOnDisk,
            prefetchedReceiptEnvironment: .production
        )

        expect(detector.isSandbox) == true

        mockFetcher.resumeReceiptFetch()

        await expect(detector.isSandbox).toEventually(beFalse(), timeout: .seconds(3))
    }

    func testUsesPrefetchedReceiptEnvironmentAfterPrefetchCompletes() async {
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptURLResult: .appStoreReceiptMissingOnDisk,
            prefetchedReceiptEnvironment: .sandbox
        )

        expect(detector.isSandbox) == false

        mockFetcher.resumeReceiptFetch()

        await expect(detector.isSandbox).toEventually(beTrue(), timeout: .seconds(3))
    }

    func testSimulatorAlwaysReturnsTrueEvenBeforePrefetchCompletes() async {
        let (detector, _) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptURLResult: .appStoreReceiptMissingOnDisk,
            inSimulator: true,
            prefetchedReceiptEnvironment: .production
        )

        expect(detector.isSandbox) == true
    }

    func testSkipsPrefetchWhenDisabled() async {
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptURLResult: .appStoreReceiptMissingOnDisk,
            prefetchedReceiptEnvironment: .sandbox,
            shouldPrefetchReceiptEnvironment: false
        )

        expect(detector.isSandbox) == false
        expect(mockFetcher.fetchReceiptCalled.value) == false
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

    // MARK: - Prefetched Receipt Environment Tests

    func testIsSandboxWhenPrefetchedReceiptEnvironmentIsSandbox() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .sandbox
        )
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testIsSandboxWhenPrefetchedReceiptEnvironmentIsXcode() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .xcode
        )
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testIsNotSandboxWhenPrefetchedReceiptEnvironmentIsProduction() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .sandbox,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .production
        )
        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testPrefetchedReceiptEnvironmentTakesPrecedenceOverReceiptEnvironment() async {
        // Receipt says sandbox, but prefetched receipt environment says production
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .sandbox,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .production
        )
        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testFallsBackToProductionReceiptWhenNoPrefetchedReceiptEnvironment() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testFallsBackToSandboxReceiptWhenNoPrefetchedReceiptEnvironment() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let detector = await SandboxEnvironmentDetector.with(
            receiptEnvironment: .sandbox,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == false
    }

    func testFallsBackToMacAppStoreDetectorWhenNoPrefetchedReceiptEnvironmentAndUnknownReceipt() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let detector = await SandboxEnvironmentDetector.with(
            macAppStore: false,
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: nil
        )
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == true
    }

    // MARK: - Prefetch Receipt Pending

    func testUsesReceiptEnvironmentBeforePrefetchCompletes() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptEnvironment: .sandbox,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .production
        )

        // Before prefetch completes, should use receipt environment (sandbox)
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == false

        // Resume prefetch
        mockFetcher.resumeReceiptFetch()

        // After prefetch completes, should use prefetched receipt environment (production)
        await expect(detector.isSandbox).toEventually(beFalse(), timeout: .seconds(3))
    }

    func testUsesPrefetchedReceiptEnvironmentAfterPrefetchCompletes() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .sandbox
        )

        // Before prefetch completes, should use receipt environment (production)
        expect(detector.isSandbox) == false
        expect(macAppStoreDetector.isMacAppStoreCalled) == false

        // Resume prefetch
        mockFetcher.resumeReceiptFetch()

        // After prefetch completes, should use prefetched receipt environment (sandbox)
        await expect(detector.isSandbox).toEventually(beTrue(), timeout: .seconds(3))
    }

    func testFallsBackToMacAppStoreDetectorBeforePrefetchCompletesWithUnknownReceipt() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: false)
        let (detector, _) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptEnvironment: .unknown,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .sandbox
        )

        // Before prefetch completes with unknown receipt, should fall back to MacAppStoreDetector
        expect(detector.isSandbox) == true
        expect(macAppStoreDetector.isMacAppStoreCalled) == true
    }

    func testSkipsPrefetchWhenDisabled() async {
        let macAppStoreDetector = MockMacAppStoreDetector(isMacAppStore: true)
        let (detector, mockFetcher) = SandboxEnvironmentDetector.withStalledReceiptEnvironment(
            receiptEnvironment: .production,
            macAppStoreDetector: macAppStoreDetector,
            prefetchedReceiptEnvironment: .sandbox,
            shouldPrefetchReceiptEnvironment: false
        )

        expect(detector.isSandbox) == false
        expect(mockFetcher.fetchReceiptCalled.value) == false
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
        receiptEnvironment: AppleReceipt.Environment? = nil,
        failReceiptParsing: Bool = false,
        macAppStoreDetector: MockMacAppStoreDetector? = nil,
        prefetchedReceiptEnvironment: AppleReceipt.Environment? = nil,
        shouldPrefetchReceiptEnvironment: Bool = true
    ) async -> SandboxEnvironmentDetector {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let resolvedReceiptEnvironment: AppleReceipt.Environment = receiptEnvironment ?? {
            switch result {
            case .sandboxReceipt, .sandboxReceiptMissingOnDisk:
                return .sandbox
            case .appStoreReceipt, .appStoreReceiptMissingOnDisk:
                return .production
            case .emptyReceipt, .nilURL:
                return .unknown
            }
        }()

        let mockReceipt = AppleReceipt(
            environment: resolvedReceiptEnvironment,
            bundleId: "bundle",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: []
        )

        let prefetchedReceipt = AppleReceipt(
            environment: prefetchedReceiptEnvironment ?? .unknown,
            bundleId: "bundle",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: []
        )

        let mockRequestFetcher = MockRequestFetcherWithStall()
        let localReceiptFetcher = MockLocalReceiptFetcher(
            mockReceipt: mockReceipt,
            prefetchedReceipt: prefetchedReceipt,
            failReceiptParsing: failReceiptParsing
        )
        // If prefetch can use an already available receipt on disk,
        // make that parsed value match `prefetchedReceiptEnvironment` for these tests.
        if prefetchedReceiptEnvironment != nil {
            localReceiptFetcher.usePrefetchedReceipt.value = true
        }
        mockRequestFetcher.onReceiptFetchCompletion = {
            localReceiptFetcher.usePrefetchedReceipt.value = true
        }

        let detector = SandboxEnvironmentDetector(
            bundle: bundle,
            isRunningInSimulator: inSimulator,
            receiptFetcher: localReceiptFetcher,
            macAppStoreDetector: macAppStoreDetector ?? MockMacAppStoreDetector(isMacAppStore: macAppStore),
            requestFetcher: mockRequestFetcher,
            shouldPrefetchReceiptEnvironment: shouldPrefetchReceiptEnvironment
        )

        if shouldPrefetchReceiptEnvironment {
            await expect(localReceiptFetcher.fetchAndParseCalled.value).toEventually(beTrue())
        }

        return detector
    }

    /// Creates a detector with a stalled response to `prefetchedReceiptEnvironment`, returning both the detector and
    /// the mock fetcher.
    /// Use `mockFetcher.resumeReceiptFetch()` to complete the prefetch.
    static func withStalledReceiptEnvironment(
        receiptURLResult result: MockBundle.ReceiptURLResult = .appStoreReceiptMissingOnDisk,
        inSimulator: Bool = false,
        macAppStore: Bool = false,
        receiptEnvironment: AppleReceipt.Environment? = nil,
        failReceiptParsing: Bool = false,
        macAppStoreDetector: MockMacAppStoreDetector? = nil,
        prefetchedReceiptEnvironment: AppleReceipt.Environment? = nil,
        shouldPrefetchReceiptEnvironment: Bool = true
    ) -> (SandboxEnvironmentDetector, MockRequestFetcherWithStall) {
        let bundle = MockBundle()
        bundle.receiptURLResult = result

        let resolvedReceiptEnvironment: AppleReceipt.Environment = receiptEnvironment ?? {
            switch result {
            case .sandboxReceipt, .sandboxReceiptMissingOnDisk:
                return .sandbox
            case .appStoreReceipt, .appStoreReceiptMissingOnDisk:
                return .production
            case .emptyReceipt, .nilURL:
                return .unknown
            }
        }()

        let mockReceipt = AppleReceipt(
            environment: resolvedReceiptEnvironment,
            bundleId: "bundle",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: []
        )

        let prefetchedReceipt = AppleReceipt(
            environment: prefetchedReceiptEnvironment ?? .unknown,
            bundleId: "bundle",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: []
        )

        let mockRequestFetcher = MockRequestFetcherWithStall()
        mockRequestFetcher.shouldStall.value = true
        let localReceiptFetcher = MockLocalReceiptFetcher(
            mockReceipt: mockReceipt,
            prefetchedReceipt: prefetchedReceipt,
            failReceiptParsing: failReceiptParsing
        )
        mockRequestFetcher.onReceiptFetchCompletion = {
            localReceiptFetcher.usePrefetchedReceipt.value = true
        }

        let detector = SandboxEnvironmentDetector(
            bundle: bundle,
            isRunningInSimulator: inSimulator,
            receiptFetcher: localReceiptFetcher,
            macAppStoreDetector: macAppStoreDetector ?? MockMacAppStoreDetector(isMacAppStore: macAppStore),
            requestFetcher: mockRequestFetcher,
            shouldPrefetchReceiptEnvironment: shouldPrefetchReceiptEnvironment
        )

        return (detector, mockRequestFetcher)
    }

}

private final class MockLocalReceiptFetcher: LocalReceiptFetcherType {

    let mockReceipt: AppleReceipt
    let prefetchedReceipt: AppleReceipt
    let failReceiptParsing: Bool
    let usePrefetchedReceipt: Atomic<Bool> = false
    let fetchAndParseCalled: Atomic<Bool> = false

    init(mockReceipt: AppleReceipt, prefetchedReceipt: AppleReceipt, failReceiptParsing: Bool) {
        self.mockReceipt = mockReceipt
        self.prefetchedReceipt = prefetchedReceipt
        self.failReceiptParsing = failReceiptParsing
    }

    func fetchAndParseLocalReceipt() throws -> RevenueCat.AppleReceipt {
        self.fetchAndParseCalled.value = true

        if failReceiptParsing {
            throw PurchasesReceiptParser.Error.receiptParsingError
        }
        return self.usePrefetchedReceipt.value ? self.prefetchedReceipt : self.mockReceipt
    }

}

private final class MockRequestFetcherWithStall: StoreKitRequestFetcher {

    let shouldStall: Atomic<Bool> = false
    let fetchReceiptCalled: Atomic<Bool> = false
    var onReceiptFetchCompletion: (@Sendable () -> Void)?
    private let pendingCompletions: Atomic<[@MainActor @Sendable () -> Void]> = .init([])

    init() {
        super.init(operationDispatcher: OperationDispatcher())
    }

    override func fetchReceiptData(_ completion: @MainActor @Sendable @escaping () -> Void) {
        self.fetchReceiptCalled.value = true

        guard self.shouldStall.value else {
            self.onReceiptFetchCompletion?()
            OperationDispatcher.dispatchOnMainActor {
                completion()
            }
            return
        }

        self.pendingCompletions.modify { $0.append(completion) }
    }

    func resumeReceiptFetch() {
        let completions = self.pendingCompletions.modify { pending in
            defer { pending.removeAll() }
            return pending
        }

        self.onReceiptFetchCompletion?()

        for completion in completions {
            OperationDispatcher.dispatchOnMainActor {
                completion()
            }
        }
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
