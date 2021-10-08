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
class StoreKitConfigTestCase: XCTestCase {

    private static var hasWaited = false
    private static let waitLock = NSLock()

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        testSession = try SKTestSession(configurationFileNamed: "UnitTestsConfiguration")
        testSession.resetToDefaultState()
        testSession.disableDialogs = true
        testSession.clearTransactions()

        self.waitForStoreKitTestIfNeeded()

        let suiteName = "StoreKitConfigTests"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.removePersistentDomain(forName: suiteName)
    }

}

private extension StoreKitConfigTestCase {

    func waitForStoreKitTestIfNeeded() {
        // StoreKitTest seems to take a few seconds to initialize, and running tests before that
        // might result in failure. So we give it a few seconds to load before testing.
        Self.waitLock.lock()
        if !Self.hasWaited {
            Self.hasWaited = true
            Thread.sleep(forTimeInterval: 5)
        }
        Self.waitLock.unlock()
    }

}
