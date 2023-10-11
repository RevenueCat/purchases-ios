//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitConfigTestCase.swift
//
//  Created by Andrés Boedo on 23/9/21.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

/// Available from iOS 14.0 because that's when `SKTestSession` was introduced.
@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class StoreKitConfigTestCase: TestCase {

    static var requestTimeout: TimeInterval = 60
    static var requestDispatchTimeout: DispatchTimeInterval {
        return .seconds(Int(Self.requestTimeout))
    }

    private static let hasWaited: Atomic<Bool> = false
    private static let waitTimeInSeconds: TimeInterval? = {
        ProcessInfo.processInfo.environment["CIRCLECI_STOREKIT_TESTS_DELAY_SECONDS"]
            .flatMap(TimeInterval.init)
    }()

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        self.testSession = try SKTestSession(configurationFileNamed: "UnitTestsConfiguration")
        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true
        self.testSession.clearTransactions()

        await self.waitForStoreKitTestIfNeeded()

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            await self.deleteAllTransactions(session: self.testSession)
        }

        let suiteName = "StoreKitConfigTests"
        self.userDefaults = UserDefaults(suiteName: suiteName)
        self.userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        self.clearReceiptIfExists()

        // `SKTestSession` might have not been initialized if the test was skipped.
        if let session = self.testSession {
            if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                await self.deleteAllTransactions(session: session)
            }
            session.clearTransactions()
        }

        try await super.tearDown()
    }

    // MARK: - Transactions observation

    private static var transactionsObservation: Task<Void, Never>?

    override class func setUp() {
        super.setUp()

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            Self.transactionsObservation?.cancel()
            Self.transactionsObservation = Task {
                // Silence warning in tests:
                // "Making a purchase without listening for transaction updates risks missing successful purchases.
                for await _ in Transaction.updates {}
            }
        }
    }

    override class func tearDown() {
        Self.transactionsObservation?.cancel()
        Self.transactionsObservation = nil

        super.tearDown()
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension StoreKitConfigTestCase {

    func waitForStoreKitTestIfNeeded() async {
        // StoreKitTest seems to take a few seconds to initialize, and running tests before that
        // might result in failure. So we give it a few seconds to load before testing.

        guard let waitTime = Self.waitTimeInSeconds else { return }
        guard !Self.hasWaited.getAndSet(true) else { return }

        Logger.warn(StoreKitTestMessage.delayingTest(waitTime))

        try? await Task.sleep(nanoseconds: DispatchTimeInterval(waitTime).nanoseconds)
    }

    func clearReceiptIfExists() {
        let manager = FileManager.default

        guard let url = Bundle.main.appStoreReceiptURL, manager.fileExists(atPath: url.path) else { return }

        do {
            try manager.removeItem(at: url)
        } catch {
            Logger.appleWarning(StoreKitTestMessage.errorRemovingReceipt(url, error))
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension StoreKitConfigTestCase {

    func createTransaction(
        productID: String? = nil,
        finished: Bool
    ) async throws -> StoreTransaction {
        return StoreTransaction(
            sk2Transaction: try await self.simulateAnyPurchase(productID: productID,
                                                               finishTransaction: finished)
        )
    }

    func createTransactionForConsumableProduct(productID: String?, finished: Bool) async throws -> StoreTransaction {
        return try await self.createTransaction(productID: productID, finished: finished)
    }

}
