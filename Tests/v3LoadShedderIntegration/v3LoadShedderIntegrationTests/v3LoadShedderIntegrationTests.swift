//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  v3LoadShedderIntegrationTests.swift
//
//  Created by Andrés Boedo on 3/29/23.

import XCTest
@testable import v3LoadShedderIntegration
import StoreKit
import StoreKitTest
@testable import Purchases

final class v3LoadShedderIntegrationTests: XCTestCase {
    let apiKey = "API_KEY"

    override func setUpWithError() throws {
        Purchases.logLevel = .debug
        let userDefaultsSuite = "v3LoadShedderIntegrationTests"
        let userDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        Purchases.configure(withAPIKey: self.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)



    }

    override func tearDownWithError() throws {
    }

    func testExample() throws {

    }

}
