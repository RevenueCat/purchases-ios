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

import Nimble
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

@MainActor
class BaseBackendIntegrationTests: XCTestCase {

    private var userDefaults: UserDefaults!
    // swiftlint:disable:next weak_delegate
    private(set) var purchasesDelegate: TestPurchaseDelegate!

    class var storeKit2Setting: StoreKit2Setting { return .default }
    class var observerMode: Bool { return false }

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        guard Constants.apiKey != "REVENUECAT_API_KEY", Constants.proxyURL != "REVENUECAT_PROXY_URL" else {
            throw ErrorUtils.configurationError(message: "Must set configuration in `Constants.swift`")
        }

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // Despite calling `SKTestSession.clearTransactions` tests sometimes
            // begin with leftover transactions. This ensures that we remove them
            // to always start with a clean state.
            await self.finishAllUnfinishedTransactions()
        }

        self.userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        self.userDefaults?.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        if !Constants.proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: Constants.proxyURL)
        }

        self.clearReceiptIfExists()
        try self.configurePurchases()
        self.verifyPurchasesDoesNotLeak()
    }

}

private extension BaseBackendIntegrationTests {

    func clearReceiptIfExists() {
        let manager = FileManager.default

        guard let url = Bundle.main.appStoreReceiptURL, manager.fileExists(atPath: url.path) else { return }

        do {
            Logger.info("Removing receipt from url: \(url)")
            try manager.removeItem(at: url)
        } catch {
            Logger.appleWarning("Error attempting to remove receipt URL '\(url)': \(error)")
        }
    }

    func configurePurchases() throws {
        self.purchasesDelegate = TestPurchaseDelegate()

        Purchases.logLevel = .verbose

        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: Self.observerMode,
                            userDefaults: self.userDefaults,
                            platformInfo: nil,
                            responseVerificationLevel: try .enforced(Signing.loadPublicKey()),
                            storeKit2Setting: Self.storeKit2Setting,
                            storeKitTimeout: Configuration.storeKitRequestTimeoutDefault,
                            networkTimeout: Configuration.networkTimeoutDefault,
                            dangerousSettings: self.dangerousSettings)
        Purchases.shared.delegate = self.purchasesDelegate
    }

    func verifyPurchasesDoesNotLeak() {
        // See `addTeardownBlock` docs:
        // - These run *before* `tearDown`.
        // - They run in LIFO order.
        self.addTeardownBlock { [weak purchases = Purchases.shared] in
            expect(purchases).toEventually(beNil(), description: "Purchases has leaked")
        }

        self.addTeardownBlock {
            Purchases.shared.delegate = nil
            Purchases.clearSingleton()
        }
    }

    private var dangerousSettings: DangerousSettings {
        return .init(autoSyncPurchases: true,
                     internalSettings: .init(enableReceiptFetchRetry: true))
    }

}
