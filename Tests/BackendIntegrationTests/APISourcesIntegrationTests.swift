//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  APISourcesIntegrationTests.swift
//
//  Created by Antonio Pallares on 19/10/26.

import Nimble
@testable import RevenueCat
import XCTest

private enum APISources {

    static let primary = "https://api.revenuecat.com/"
    static let backup = "https://api.rc-backup.com/"
    /// `.invalid` is a reserved TLD that never resolves, so these sources are always unreachable.
    static let unreachable = "https://api.revenuecat.invalid/"
    static let otherUnreachable = "https://api-backup.revenuecat.invalid/"

}

/// Exercises API source failover against the real backend through a `Backend` wired like the SDK's, but
/// fed a fixed `sources` list so each test decides which hosts act as primary and backup.
class APISourceFailoverBackendIntegrationTests: BaseBackendIntegrationTests {

    private let appUserID = IdentityManager.generateRandomID()
    private let apiSourceRecorder = APISourceRecorder()

    override var configuresPurchasesOnSetUp: Bool { return false }

    override func setUp() async throws {
        try await super.setUp()

        // `configurePurchases()` normally sets these globals. A proxy pins every request to itself,
        // bypassing API sources.
        Purchases.proxyURL = nil
        Purchases.logLevel = .verbose
    }

    func testRequestsStayOnTheHealthyPrimarySource() async throws {
        let backend = self.createBackend(sources: [APISources.primary, APISources.backup])

        let customerInfo = try await backend.customerInfo(appUserID: self.appUserID).get()

        expect(customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources) == [APISources.primary]
        self.logger.verifyMessageWasNotLogged("Health check for")
    }

    func testFailsOverToTheBackupSourceWhenThePrimaryIsUnreachable() async throws {
        let backend = self.createBackend(sources: [APISources.unreachable, APISources.backup])

        let customerInfo = try await backend.customerInfo(appUserID: self.appUserID).get()

        expect(customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources) == [APISources.unreachable, APISources.backup]
        self.logger.verifyMessageWasLogged("Health check for \(APISources.unreachable)v1/health/connectivity " +
                                           "failed to connect")

        // The source list advanced, so later requests go straight to the backup source.
        let secondCustomerInfo = try await backend.customerInfo(appUserID: self.appUserID).get()

        expect(secondCustomerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources) == [APISources.unreachable, APISources.backup, APISources.backup]
    }

    func testBackupSourceServesVerifiedResponses() async throws {
        let backend = self.createBackend(sources: [APISources.backup])

        let customerInfo = try await backend.customerInfo(appUserID: self.appUserID).get()
        expect(customerInfo.entitlements.verification) == .verified

        let logInResult = try await backend.logIn(currentAppUserID: self.appUserID,
                                                  newAppUserID: UUID().uuidString).get()
        expect(logInResult.info.entitlements.verification) == .verified

        let offerings = try await backend.offerings(appUserID: self.appUserID).get()
        expect(offerings.contents.response.offerings).toNot(beEmpty())
        expect(offerings.contents.originalSource) != .fallbackUrl

        expect(Set(self.apiSourceRecorder.sources)) == [APISources.backup]
    }

    func testBackupSourceServesVerifiedRemoteConfig() async throws {
        let backend = self.createBackend(sources: [APISources.backup])

        let result = try await backend.remoteConfig(appUserID: self.appUserID).get()

        expect(result.verificationResult) == .verified
        expect(result.container).toNot(beNil())
        expect(self.apiSourceRecorder.sources) == [APISources.backup]
    }

    func testRemoteConfigFailsOverToTheBackupSourceWhenThePrimaryIsUnreachable() async throws {
        let backend = self.createBackend(sources: [APISources.unreachable, APISources.backup])

        let result = try await backend.remoteConfig(appUserID: self.appUserID).get()

        expect(result.verificationResult) == .verified
        expect(result.container).toNot(beNil())
        expect(self.apiSourceRecorder.sources) == [APISources.unreachable, APISources.backup]
    }

    func testServerErrorFromAHealthySourceDoesNotFailOver() async throws {
        let backend = self.createBackend(sources: [APISources.primary, APISources.backup],
                                         failingRequestsTo: APISources.primary)

        let result = await backend.customerInfo(appUserID: self.appUserID)

        guard case let .failure(.networkError(networkError)) = result else {
            fail("Expected a network error, got \(result)")
            return
        }
        expect(networkError.isServerDown) == true
        expect(Set(self.apiSourceRecorder.sources)) == [APISources.primary]
        self.logger.verifyMessageWasLogged(
            Strings.network.api_source_healthy_despite_failure(host: APISources.primary)
        )
    }

    func testOfferingsUseTheStaticFallbackOnceEverySourceIsUnreachable() async throws {
        let backend = self.createBackend(sources: [APISources.unreachable, APISources.otherUnreachable])

        let offerings = try await backend.offerings(appUserID: self.appUserID).get()

        expect(offerings.contents.response.offerings).toNot(beEmpty())
        expect(offerings.contents.originalSource) == .fallbackUrl
        // The fallback attempt pins its own host, so it resolves no API source.
        expect(self.apiSourceRecorder.sources) == [APISources.unreachable, APISources.otherUnreachable, nil]
    }

    func testCustomerInfoSurfacesTheErrorOnceEverySourceIsUnreachable() async throws {
        let backend = self.createBackend(sources: [APISources.unreachable, APISources.otherUnreachable])

        let result = await backend.customerInfo(appUserID: self.appUserID)

        guard case .failure(.networkError) = result else {
            fail("Expected a network error, got \(result)")
            return
        }
        expect(self.apiSourceRecorder.sources) == [APISources.unreachable, APISources.otherUnreachable]
    }

    // MARK: - Helpers

    private func createBackend(sources: [String]) -> Backend {
        return self.createBackend(sources: sources, failingRequestsTo: nil)
    }

    private func createBackend(sources: [String], failingRequestsTo failingSource: String?) -> Backend {
        return self.createBackend(
            sources: sources,
            forceServerErrorStrategy: self.apiSourceRecorder.strategy(failingRequestsTo: failingSource)
        )
    }

}

class APISourcesStoreKit1IntegrationTests: APISourcesStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

/// Runs core SDK flows against the real backend with the `usesRemoteConfigAPISources` dangerous setting
/// enabled, so eligible requests resolve their host through the remote config API sources.
class APISourcesStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {

    private let apiSourceRecorder = APISourceRecorder()

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override var usesRemoteConfigAPISources: Bool { return true }

    // A proxy pins every request to itself, bypassing API sources.
    override var proxyURL: String? { return nil }

    override func setUp() async throws {
        self.forceServerErrorStrategy = self.apiSourceRecorder.strategy(failingRequestsTo: nil)

        try await super.setUp()
    }

    func testCanGetOfferings() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) != .fallbackUrl
        expect(Set(self.apiSourceRecorder.sources(for: HTTPRequest.Path.getOfferings(appUserID: ""))))
            == [APISources.primary]
    }

    func testCanPurchaseSubscription() async throws {
        try await self.purchaseMonthlyOffering()

        expect(Set(self.apiSourceRecorder.sources(for: HTTPRequest.Path.postReceiptData))) == [APISources.primary]
    }

    func testCanLogIn() async throws {
        let (customerInfo, created) = try await self.purchases.logIn(UUID().uuidString)

        expect(created) == true
        expect(customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.logIn)) == [APISources.primary]
    }

}

class APISourceOutageStoreKit1IntegrationTests: APISourceOutageStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

/// Runs core SDK flows against the real backend while the primary API source is down, so the SDK fails over
/// to the backup source from its embedded defaults.
class APISourceOutageStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {

    private let apiSourceRecorder = APISourceRecorder()

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override var usesRemoteConfigAPISources: Bool { return true }

    // A proxy pins every request to itself, bypassing API sources.
    override var proxyURL: String? { return nil }

    override func setUp() async throws {
        self.forceServerErrorStrategy = self.apiSourceRecorder.strategy(simulatingAnOutageOf: APISources.primary)

        try await super.setUp()
    }

    func testCanGetOfferingsFromTheBackupSource() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) != .fallbackUrl
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.getOfferings(appUserID: "")).last)
            == APISources.backup
    }

    func testCanPurchaseSubscriptionThroughTheBackupSource() async throws {
        let purchase = try await self.purchaseMonthlyOffering()

        expect(purchase.customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.postReceiptData).last) == APISources.backup
    }

}

// MARK: - Helpers

private extension BaseBackendIntegrationTests {

    /// A `Backend` wired like the SDK's, with API sources enabled and fed the fixed `sources` list.
    func createBackend(sources: [String], forceServerErrorStrategy: ForceServerErrorStrategy) -> Backend {
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storeKitVersion: Self.storeKitVersion,
            apiKey: self.apiKey,
            responseVerificationMode: Self.responseVerificationMode,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                internalSettings: DangerousSettings.Internal(
                    usesRemoteConfigAPISources: true,
                    forceServerErrorStrategy: forceServerErrorStrategy
                )
            ),
            isAppBackgrounded: false,
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        )
        return Backend(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            tokenManager: TokenManager(enabled: false, storage: Keychain(access: nil)),
            operationDispatcher: .default,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            ),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: RemoteConfigSourceProvider(topicStore: FixedAPISourcesTopicStore(urls: sources)),
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default),
            subscriberDimensionsStore: SubscriberDimensionsStore(
                deviceCache: DeviceCache(systemInfo: systemInfo, userDefaults: self.userDefaults)
            )
        )
    }

}

private extension Backend {

    func customerInfo(appUserID: String) async -> Result<CustomerInfo, BackendError> {
        return await withCheckedContinuation { continuation in
            self.getCustomerInfo(appUserID: appUserID, isAppBackgrounded: false, allowComputingOffline: false) {
                continuation.resume(returning: $0)
            }
        }
    }

    func logIn(currentAppUserID: String, newAppUserID: String) async -> IdentityAPI.LogInResponse {
        return await withCheckedContinuation { continuation in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) {
                continuation.resume(returning: $0)
            }
        }
    }

    func offerings(appUserID: String) async -> Result<OfferingsFetchResult, BackendError> {
        return await withCheckedContinuation { continuation in
            self.offerings.getOfferings(appUserID: appUserID, isAppBackgrounded: false) {
                continuation.resume(returning: $0)
            }
        }
    }

    func remoteConfig(appUserID: String) async -> Result<RemoteConfigFetchResult, BackendError> {
        return await withCheckedContinuation { continuation in
            self.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart,
                               appUserID: appUserID,
                               domain: RemoteConfiguration.defaultDomain,
                               manifest: nil,
                               prefetchedBlobs: [],
                               lastRefreshTime: nil),
                isAppBackgrounded: false
            ) {
                continuation.resume(returning: $0)
            }
        }
    }

}

/// Records the API source each request attempt resolved (`nil` when it used its static host), and can fail
/// the attempts targeting one source with a real 5xx. Source health checks don't go through `HTTPClient`, so
/// they're never recorded.
private final class APISourceRecorder {

    private let attempts: Atomic<[(pathName: String, source: String?)]> = .init([])

    var sources: [String?] {
        return self.attempts.value.map(\.source)
    }

    func sources(for path: HTTPRequestPath) -> [String?] {
        return self.attempts.value.filter { $0.pathName == path.name }.map(\.source)
    }

    func strategy(failingRequestsTo failingSource: String?) -> ForceServerErrorStrategy {
        return .init { [attempts = self.attempts] request in
            let source = request.apiSourceState.source?.handle.url
            attempts.modify { $0.append((pathName: request.httpRequest.path.name, source: source)) }

            if let failingSource, source == failingSource {
                return .defaultServerError
            }
            return .performRequest
        }
    }

    /// Like `strategy(failingRequestsTo:)`, but `downSource`'s health checks also report it unhealthy, so the
    /// SDK fails over as if it were down.
    func strategy(simulatingAnOutageOf downSource: String) -> ForceServerErrorStrategy {
        let downHost = URL(string: downSource)?.host
        return .init(action: self.strategy(failingRequestsTo: downSource).action,
                     healthCheckResult: { $0.host == downHost ? false : nil })
    }

}

/// A `sources` topic store exposing `urls` as API sources in order (priority = index), in the backend
/// topic shape.
private final class FixedAPISourcesTopicStore: RemoteConfigTopicStoreType {

    private let urls: [String]

    init(urls: [String]) {
        self.urls = urls
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        guard topic == .sources else { return nil }
        return ["api": RemoteConfiguration.ConfigItem(content: [
            "sources": .array(self.urls.enumerated().map { priority, url in
                .object([
                    "url": .string(url),
                    "priority": .int(priority),
                    "weight": .int(1)
                ])
            })
        ])]
    }

}
