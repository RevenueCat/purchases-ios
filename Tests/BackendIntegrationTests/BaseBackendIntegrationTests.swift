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

final class TestPurchaseDelegate: NSObject, PurchasesDelegate, Sendable {

    private let _customerInfo: Atomic<CustomerInfo?> = nil
    private let _customerInfoUpdateCount: Atomic<Int> = .init(0)

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self._customerInfo.value = customerInfo
        self._customerInfoUpdateCount.value += 1
    }

    var customerInfo: CustomerInfo? { return self._customerInfo.value }
    var customerInfoUpdateCount: Int { return self._customerInfoUpdateCount.value }

}

@MainActor
class BaseBackendIntegrationTests: XCTestCase {

    private var userDefaults: UserDefaults!
    // swiftlint:disable:next weak_delegate
    private(set) var purchasesDelegate: TestPurchaseDelegate!

    private var mainThreadMonitor: MainThreadMonitor!

    class var storeKit2Setting: StoreKit2Setting { return .default }
    class var observerMode: Bool { return false }
    class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        let apiKey = self.apiKey
        let proxyURL = self.proxyURL

        guard apiKey != "REVENUECAT_API_KEY",
                apiKey != "REVENUECAT_LOAD_SHEDDER_API_KEY",
                proxyURL != "REVENUECAT_PROXY_URL" else {
            throw ErrorUtils.configurationError(message: "Must set configuration in `Constants.swift`")
        }

        self.mainThreadMonitor = .init()
        self.mainThreadMonitor.run()

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
        await self.configurePurchases(apiKey: apiKey, proxyURL: proxyURL)
        self.verifyPurchasesDoesNotLeak()
    }

    override func tearDown() {
        super.tearDown()

        self.mainThreadMonitor = nil
    }

    /// Simulates closing the app and re-opening with a fresh instance of `Purchases`.
    final func resetSingleton() async {
        Logger.warn("Resetting Purchases.shared")

        Purchases.clearSingleton()
        await self.createPurchases()
    }

    // MARK: - Configuration

    var apiKey: String { return Constants.apiKey }
    var proxyURL: String? { return Constants.proxyURL }

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

    func configurePurchases(apiKey: String, proxyURL: String?) async {
        self.purchasesDelegate = TestPurchaseDelegate()

        Purchases.proxyURL = proxyURL.flatMap(URL.init(string:))
        Purchases.logLevel = .verbose

        await self.createPurchases()
    }

    func createPurchases() async {
        Purchases.configure(withAPIKey: self.apiKey,
                            appUserID: nil,
                            observerMode: Self.observerMode,
                            userDefaults: self.userDefaults,
                            platformInfo: nil,
                            responseVerificationMode: Self.responseVerificationMode,
                            storeKit2Setting: Self.storeKit2Setting,
                            storeKitTimeout: Configuration.storeKitRequestTimeoutDefault,
                            networkTimeout: Configuration.networkTimeoutDefault,
                            dangerousSettings: self.dangerousSettings)
        Purchases.shared.delegate = self.purchasesDelegate

        await self.waitForAnonymousUser()
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

    func waitForAnonymousUser() async {
        // SDK initialization begins with an initial request to offerings,
        // which results in a get-create of the initial anonymous user.
        // To avoid race conditions with when this request finishes and make all tests deterministic
        // this waits for that request to finish.
        //
        // This ignores errors because this class does not set up `SKTestSession`,
        // so subclasses would fail to load offerings if they don't set one up.
        // However, it still serves the purpose of waiting for the anonymous user.
        // If there is something broken when loading offerings, there is a dedicated test that would fail instead.
        _ = try? await Purchases.shared.offerings()
    }

    private var dangerousSettings: DangerousSettings {
        return .init(autoSyncPurchases: true,
                     internalSettings: self)
    }

}

extension BaseBackendIntegrationTests: InternalDangerousSettingsType {

    var enableReceiptFetchRetry: Bool { return true }
    var forceServerErrors: Bool { return false }

}
