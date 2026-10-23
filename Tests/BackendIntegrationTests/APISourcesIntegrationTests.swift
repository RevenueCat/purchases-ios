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

/// The API sources the SDK embeds as defaults, in failover order.
private enum APISources {

    static let primary = "https://api.revenuecat.com/"
    static let backup = "https://api.rc-backup.com/"

}

class APISourcesStoreKit1IntegrationTests: APISourcesStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

/// Runs core SDK flows against the real backend with the `usesRemoteConfigAPISources` dangerous setting
/// enabled, so eligible requests resolve their host through the remote config API sources.
class APISourcesStoreKit2IntegrationTests: BaseAPISourcesIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

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

    func testFetchesRemoteConfigFromThePrimarySource() async throws {
        try await self.waitForRemoteConfigRequest(toTarget: APISources.primary)

        expect(Set(self.apiSourceRecorder.sources(for: Self.remoteConfigPath))) == [APISources.primary]
    }

}

class APISourceOutageStoreKit1IntegrationTests: APISourceOutageStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

/// Runs core SDK flows against the real backend while the primary API source is down, so the SDK fails over
/// to the backup source.
class APISourceOutageStoreKit2IntegrationTests: BaseAPISourcesIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func createForceServerErrorStrategy() -> ForceServerErrorStrategy {
        return self.apiSourceRecorder.strategy(simulatingAnOutageOf: [APISources.primary])
    }

    func testCanGetOfferingsFromTheBackupSource() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) != .fallbackUrl
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.getOfferings(appUserID: "")).last)
            == APISources.backup
    }

    func testCanGetCustomerInfoFromTheBackupSource() async throws {
        let customerInfo = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        expect(customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.getCustomerInfo(appUserID: "")).last)
            == APISources.backup
    }

    func testCanPurchaseSubscriptionThroughTheBackupSource() async throws {
        let purchase = try await self.purchaseMonthlyOffering()

        expect(purchase.customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.postReceiptData).last) == APISources.backup
    }

    func testCanLogInThroughTheBackupSource() async throws {
        let (customerInfo, created) = try await self.purchases.logIn(UUID().uuidString)

        expect(created) == true
        expect(customerInfo.entitlements.verification) == .verified
        expect(self.apiSourceRecorder.sources(for: HTTPRequest.Path.logIn).last) == APISources.backup
    }

    func testFetchesRemoteConfigFromTheBackupSource() async throws {
        try await self.waitForRemoteConfigRequest(toTarget: APISources.backup)
    }

}

/// Runs against the real backend while the primary API source returns server errors but its health check
/// passes, so the SDK doesn't fail over to the backup source.
class APISourceServerErrorIntegrationTests: BaseAPISourcesIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func createForceServerErrorStrategy() -> ForceServerErrorStrategy {
        return self.apiSourceRecorder.strategy(failingRequestsTo: APISources.primary)
    }

    func testOfferingsUseTheStaticFallbackWithoutFailingOver() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) == .fallbackUrl
        expect(self.apiSourceRecorder.sources).toNot(contain(APISources.backup))
        self.logger.verifyMessageWasLogged(
            Strings.network.api_source_healthy_despite_failure(host: APISources.primary)
        )
    }

}

/// Runs against the real backend while every API source is down.
class APISourcesExhaustedIntegrationTests: BaseAPISourcesIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func createForceServerErrorStrategy() -> ForceServerErrorStrategy {
        return self.apiSourceRecorder.strategy(simulatingAnOutageOf: [APISources.primary, APISources.backup])
    }

    func testOfferingsUseTheStaticFallback() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) == .fallbackUrl
        expect(self.apiSourceRecorder.sources).to(contain(APISources.primary, APISources.backup))
    }

}

/// Configures `Purchases` with API sources enabled and a `ForceServerErrorStrategy` that records the API source
/// each request attempt resolved.
class BaseAPISourcesIntegrationTests: BaseStoreKitIntegrationTests {

    static let remoteConfigPath = HTTPRequest.Path.remoteConfig(domain: RemoteConfiguration.defaultDomain)

    let apiSourceRecorder = APISourceRecorder()

    override var usesRemoteConfigAPISources: Bool { return true }

    // A proxy pins every request to itself, bypassing API sources.
    override var proxyURL: String? { return nil }

    override func setUp() async throws {
        self.forceServerErrorStrategy = self.createForceServerErrorStrategy()

        try await super.setUp()
    }

    /// Subclasses override this to simulate failing API sources.
    func createForceServerErrorStrategy() -> ForceServerErrorStrategy {
        return self.apiSourceRecorder.recordingStrategy()
    }

    /// Remote config is fetched in the background on launch, so this waits for its last attempt to target `source`.
    func waitForRemoteConfigRequest(toTarget source: String) async throws {
        let recorder = self.apiSourceRecorder
        let path = Self.remoteConfigPath
        try await asyncWait(description: "Remote config was never requested from \(source)") {
            recorder.sources(for: path).last == source
        }
    }

}

/// Records the API source each request attempt resolved (`nil` when it used its default host), and can fail the
/// attempts targeting some hosts with a real 5xx. Source health checks don't go through `HTTPClient`, so they're
/// never recorded.
final class APISourceRecorder: Sendable {

    private let attempts: Atomic<[(pathName: String, source: String?)]> = .init([])

    var sources: [String?] {
        return self.attempts.value.map(\.source)
    }

    func sources(for path: HTTPRequestPath) -> [String?] {
        return self.attempts.value.filter { $0.pathName == path.name }.map(\.source)
    }

    /// Performs every request and health check.
    func recordingStrategy() -> ForceServerErrorStrategy {
        return self.strategy(failingHosts: [], healthCheckAction: { _ in .performHealthCheck })
    }

    /// Fails the requests to `source` while its health checks still run, so the SDK sees a healthy source.
    func strategy(failingRequestsTo source: String) -> ForceServerErrorStrategy {
        return self.strategy(failingHosts: Self.hosts(of: [source]), healthCheckAction: { _ in .performHealthCheck })
    }

    /// Fails the requests to `sources` and reports them unhealthy, as if they were down.
    func strategy(simulatingAnOutageOf sources: Set<String>) -> ForceServerErrorStrategy {
        let downHosts = Self.hosts(of: sources)
        return self.strategy(failingHosts: downHosts, healthCheckAction: { url in
            downHosts.contains(url.host ?? "") ? .fakeUnhealthy : .performHealthCheck
        })
    }

    private func strategy(
        failingHosts: Set<String>,
        healthCheckAction: @escaping (URL) -> ForceServerErrorStrategy.HealthCheckAction
    ) -> ForceServerErrorStrategy {
        return .init(action: { [attempts = self.attempts] request in
            let source = request.apiSourceState.source
            attempts.modify { $0.append((pathName: request.httpRequest.path.name, source: source?.handle.url)) }

            // Requests without a source, e.g. once every source is exhausted, go to the default host.
            let host = source?.url.host ?? (request.targetsFallbackHost ? nil : SystemInfo.apiBaseURL.host)
            return failingHosts.contains(host ?? "") ? .defaultServerError : .performRequest
        }, healthCheckAction: healthCheckAction)
    }

    private static func hosts(of sources: Set<String>) -> Set<String> {
        return Set(sources.compactMap { URL(string: $0)?.host })
    }

}
