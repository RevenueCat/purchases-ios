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

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        testSession = try SKTestSession(configurationFileNamed: "UnitTestsConfiguration")
        testSession.disableDialogs = true
        testSession.clearTransactions()
        testSession.failTransactionsEnabled = false
        let suiteName = "StoreKitConfigTests"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.removePersistentDomain(forName: suiteName)
    }

}
