//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseBackendIntegrationTests.swift
//
//  Created by Nacho Soto on 4/1/22.

@testable import RevenueCat
import XCTest

final class TestPurchaseDelegate: NSObject, PurchasesDelegate {

    var customerInfo: CustomerInfo?
    var customerInfoUpdateCount = 0

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        customerInfoUpdateCount += 1
    }

}

class BaseBackendIntegrationTests: XCTestCase {

    private var userDefaults: UserDefaults!
    // swiftlint:disable:next weak_delegate
    private(set) var purchasesDelegate: TestPurchaseDelegate!

    class var storeKit2Setting: StoreKit2Setting {
        return .default
    }

    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        guard Constants.apiKey != "REVENUECAT_API_KEY", Constants.proxyURL != "REVENUECAT_PROXY_URL" else {
            XCTFail("Must set configuration in `Constants.swift`")
            throw ErrorCode.configurationError
        }

        userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        userDefaults?.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        if !Constants.proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: Constants.proxyURL)
        }

        configurePurchases()
    }

    override func tearDown() {
        Purchases.clearSingleton()

        super.tearDown()
    }

}

private extension BaseBackendIntegrationTests {

    func configurePurchases() {
        purchasesDelegate = TestPurchaseDelegate()
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults,
                            storeKit2Setting: Self.storeKit2Setting,
                            dangerousSettings: nil)
        Purchases.logLevel = .debug
        Purchases.shared.delegate = purchasesDelegate
    }

}
