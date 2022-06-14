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

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
class StoreKitConfigTestCase: TestCase {

    static var requestTimeout: TimeInterval = 60
    static var requestDispatchTimeout: DispatchTimeInterval {
        return .seconds(Int(Self.requestTimeout))
    }

    private static var hasWaited = false
    private static let waitLock = Lock()
    private static let waitTimeInSeconds: Double? = {
        ProcessInfo.processInfo.environment["CIRCLECI_STOREKIT_TESTS_DELAY_SECONDS"]
            .flatMap(Double.init)
    }()

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: "UnitTestsConfiguration")
        testSession.resetToDefaultState()
        testSession.disableDialogs = true
        testSession.clearTransactions()

        self.waitForStoreKitTestIfNeeded()

        let suiteName = "StoreKitConfigTests"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        super.tearDown()

        self.clearReceiptIfExists()
    }

    // MARK: - Transactions observation

    private static var transactionsObservation: Task<Void, Never>?

    override class func setUp() {
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
    }

}

private extension StoreKitConfigTestCase {

    func waitForStoreKitTestIfNeeded() {
        // StoreKitTest seems to take a few seconds to initialize, and running tests before that
        // might result in failure. So we give it a few seconds to load before testing.

        guard let waitTime = Self.waitTimeInSeconds else { return }

        Self.waitLock.perform {
            if !Self.hasWaited {
                Logger.warn("Delaying tests for \(waitTime) seconds for StoreKit initialization...")

                Thread.sleep(forTimeInterval: waitTime)

                Self.hasWaited = true
            }
        }
    }

    func clearReceiptIfExists() {
        let manager = FileManager.default

        guard let url = Bundle.main.appStoreReceiptURL, manager.fileExists(atPath: url.path) else { return }

        do {
            try manager.removeItem(at: url)
        } catch {
            Logger.appleWarning("Error attempting to remove receipt URL '\(url)': \(error)")
        }
    }

}
