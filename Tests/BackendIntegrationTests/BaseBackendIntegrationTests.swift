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
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

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
class BaseBackendIntegrationTests: TestCase {

    private var userDefaults: UserDefaults!
    private var testUUID: UUID!

    // swiftlint:disable:next weak_delegate
    private(set) var purchasesDelegate: TestPurchaseDelegate!

    private var mainThreadMonitor: MainThreadMonitor!

    // MARK: - Overridable configuration

    class var storeKit2Setting: StoreKit2Setting { return .default }
    class var observerMode: Bool { return false }
    class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    var apiKey: String { return Constants.apiKey }
    var proxyURL: String? { return Constants.proxyURL }

    func configurePurchases() {
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
    }

    // MARK: -

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        guard self.apiKey != "REVENUECAT_API_KEY",
              self.apiKey != "REVENUECAT_LOAD_SHEDDER_API_KEY",
              self.proxyURL != "REVENUECAT_PROXY_URL" else {
            throw ErrorUtils.configurationError(message: "Must set configuration in `Constants.swift`")
        }

        self.mainThreadMonitor = .init()
        self.mainThreadMonitor.run()

        self.createUserDefaults()

        // We use a different identifier for each test to ensure the backend
        // doesn't produce conflicts when producing similar receipts across
        // separate test invocations.
        self.testUUID = UUID()

        self.clearReceiptIfExists()
        await self.createPurchases()
        self.verifyPurchasesDoesNotLeak()
    }

    override func tearDown() {
        super.tearDown()

        self.mainThreadMonitor = nil
    }

    /// Simulates closing the app and re-opening with a fresh instance of `Purchases`.
    final func resetSingleton() async {
        Logger.warn(TestMessage.resetting_purchases_singleton)

        Purchases.clearSingleton()
        await self.createPurchases()
    }

    /// - Returns: `Purchases.shared` if it's currently configured
    /// - Throws: `ErrorCode` if it's not
    /// - Note: This is the recomended way of accessing `Purchases.shared`, as it won't make the test crash.
    /// If an expectation fails in an `async` fails, sometimes `XCTest` seems to continue execution of the test despite
    /// having started tearing down the test (and therefore clearing `Purchases.shared`, which will lead to a crash
    /// and will prevent the test from being retried.
    final var purchases: Purchases {
        get throws {
            if Purchases.isConfigured {
                return Purchases.shared
            } else {
                throw ErrorCode.configurationError
            }
        }
    }

}

private extension BaseBackendIntegrationTests {

    func clearReceiptIfExists() {
        let manager = FileManager.default

        guard let url = Bundle.main.appStoreReceiptURL, manager.fileExists(atPath: url.path) else { return }

        do {
            Logger.info(TestMessage.removing_receipt(url))
            try manager.removeItem(at: url)
        } catch {
            Logger.appleWarning(TestMessage.error_removing_url(url, error))
        }
    }

    func createUserDefaults() {
        self.userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        self.userDefaults.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        // See also `SynchronizedUserDefaults`.
        // While Apple states `this method is unnecessary and shouldn't be used`, it's still
        // necessary to call `synchronize` in order for the `removePersistentDomain` changes to take effect.
        self.userDefaults.synchronize()

        // Verify that user defaults is indeed empty.
        // Reusing users across tests would lead to flaky failures.
        expect(self.userDefaults.value(forKey: DeviceCache.CacheKeys.appUserDefaults.rawValue))
            .to(
                beNil(),
                description: "Found existing user after clearing UserDefaults"
            )
    }

    func createPurchases() async {
        self.purchasesDelegate = TestPurchaseDelegate()
        self.configurePurchases()

        Purchases.shared.delegate = self.purchasesDelegate
        Purchases.proxyURL = self.proxyURL.flatMap(URL.init(string:))
        Purchases.logLevel = .verbose

        await self.waitForAnonymousUser()
    }

    func verifyPurchasesDoesNotLeak() {
        weak var purchases = Purchases.shared

        // See `addTeardownBlock` docs:
        // - These run *before* `tearDown`.
        // - They run in LIFO order.
        self.addTeardownBlock {
            Purchases.shared.delegate = nil
            Purchases.clearSingleton()

            // Note: this captures the boolean to avoid race conditions when Nimble tries
            // to print `purchases` while it's being deallocated.
            expect { purchases == nil }.toEventually(beTrue(), description: "Purchases has leaked")
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
    var forceSignatureFailures: Bool { return false }
    var testReceiptIdentifier: String? { return self.testUUID.uuidString }

}
