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
    /// `.invalid` is a reserved TLD that never resolves, so this source is always unreachable.
    static let unreachable = "https://api.revenuecat.invalid/"

}

private extension ForceServerErrorStrategy {

    /// Fails requests that target the primary API source with a real 5xx. Source health checks don't go
    /// through `HTTPClient`, so the primary still reports itself as healthy.
    static let primaryAPISourceDown: ForceServerErrorStrategy = .init { (request: HTTPClient.Request) in
        return request.apiSourceState.source?.handle.url == APISources.primary ? .defaultServerError : .performRequest
    }

}

/// Exercises API source failover against the real backend through a `Backend` wired like the SDK's, but
/// fed a fixed `sources` list so each test decides which hosts act as primary and backup.
class APISourceFailoverBackendIntegrationTests: BaseBackendIntegrationTests {

    private let appUserID = IdentityManager.generateRandomID()

    // A proxy pins every request to itself, bypassing API sources.
    override var proxyURL: String? { return nil }

    func testRequestsStayOnTheHealthyPrimarySource() async throws {
        let backend = self.createBackend(sources: [APISources.primary, APISources.backup],
                                         forceServerErrorStrategy: nil)

        let customerInfo = try await self.customerInfo(from: backend).get()

        expect(customerInfo.entitlements.verification) == .verified
        self.logger.verifyMessageWasNotLogged("Health check for")
        self.logger.verifyMessageWasNotLogged("using next API source host")
    }

    func testFailsOverToTheBackupSourceWhenThePrimaryIsUnreachable() async throws {
        let backend = self.createBackend(sources: [APISources.unreachable, APISources.backup],
                                         forceServerErrorStrategy: nil)

        let customerInfo = try await self.customerInfo(from: backend).get()

        expect(customerInfo.entitlements.verification) == .verified
        self.logger.verifyMessageWasLogged("Health check for \(APISources.unreachable)v1/health/connectivity " +
                                           "failed to connect")
        self.logger.verifyMessageWasLogged("using next API source host \(APISources.backup)", expectedCount: 1)

        self.logger.clearMessages()

        // The source list advanced, so later requests go straight to the backup source.
        let secondCustomerInfo = try await self.customerInfo(from: backend).get()

        expect(secondCustomerInfo.entitlements.verification) == .verified
        self.logger.verifyMessageWasNotLogged("Health check for")
        self.logger.verifyMessageWasNotLogged("using next API source host")
    }

    func testBackupSourceServesVerifiedResponses() async throws {
        let backend = self.createBackend(sources: [APISources.backup], forceServerErrorStrategy: nil)

        let customerInfo = try await self.customerInfo(from: backend).get()
        expect(customerInfo.entitlements.verification) == .verified

        let logInResult = try await self.logIn(backend, newAppUserID: UUID().uuidString).get()
        expect(logInResult.info.entitlements.verification) == .verified

        let offerings = try await self.offerings(from: backend).get()
        expect(offerings.contents.response.offerings).toNot(beEmpty())
        // Offerings also support the static fallback host; make sure it wasn't what served them.
        expect(offerings.contents.originalSource) != .fallbackUrl
    }

    func testServerErrorFromAHealthySourceDoesNotFailOver() async throws {
        let backend = self.createBackend(sources: [APISources.primary, APISources.backup],
                                         forceServerErrorStrategy: .primaryAPISourceDown)

        let result = await self.customerInfo(from: backend)

        guard case let .failure(.networkError(networkError)) = result else {
            fail("Expected a network error, got \(result)")
            return
        }
        expect(networkError.isServerDown) == true
        self.logger.verifyMessageWasLogged(
            Strings.network.api_source_healthy_despite_failure(host: APISources.primary)
        )
        self.logger.verifyMessageWasNotLogged("using next API source host")
    }

    // MARK: - Helpers

    private func createBackend(sources: [String],
                               forceServerErrorStrategy: ForceServerErrorStrategy?) -> Backend {
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
                deviceCache: DeviceCache(systemInfo: systemInfo, userDefaults: .standard)
            )
        )
    }

    private func customerInfo(from backend: Backend) async -> Result<CustomerInfo, BackendError> {
        return await withCheckedContinuation { continuation in
            backend.getCustomerInfo(appUserID: self.appUserID,
                                    isAppBackgrounded: false,
                                    allowComputingOffline: false) {
                continuation.resume(returning: $0)
            }
        }
    }

    private func logIn(_ backend: Backend, newAppUserID: String) async -> IdentityAPI.LogInResponse {
        return await withCheckedContinuation { continuation in
            backend.identity.logIn(currentAppUserID: self.appUserID, newAppUserID: newAppUserID) {
                continuation.resume(returning: $0)
            }
        }
    }

    private func offerings(from backend: Backend) async -> Result<OfferingsFetchResult, BackendError> {
        return await withCheckedContinuation { continuation in
            backend.offerings.getOfferings(appUserID: self.appUserID, isAppBackgrounded: false) {
                continuation.resume(returning: $0)
            }
        }
    }

}

class APISourcesStoreKit1IntegrationTests: APISourcesStoreKit2IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

}

/// Runs core SDK flows against the real backend with the `usesRemoteConfigAPISources` dangerous setting
/// enabled, so eligible requests resolve their host through the remote config API sources.
class APISourcesStoreKit2IntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override var usesRemoteConfigAPISources: Bool { return true }

    // A proxy pins every request to itself, bypassing API sources.
    override var proxyURL: String? { return nil }

    func testCanGetOfferings() async throws {
        let offerings = try await self.purchases.offerings()

        expect(offerings.all).toNot(beEmpty())
        expect(offerings.contents.originalSource) != .fallbackUrl
    }

    func testCanPurchaseSubscription() async throws {
        try await self.purchaseMonthlyOffering()
    }

    func testCanLogIn() async throws {
        let (customerInfo, created) = try await self.purchases.logIn(UUID().uuidString)

        expect(created) == true
        expect(customerInfo.entitlements.verification) == .verified
    }

    func testRequestsGoThroughAPISources() async throws {
        self.forceServerErrorStrategy = .primaryAPISourceDown

        do {
            _ = try await self.purchases.logIn(UUID().uuidString)
            fail("Expected logIn to fail while the primary API source is down")
        } catch {}

        // Only requests that resolved an API source can log this, so the SDK isn't using the static base URL.
        self.logger.verifyMessageWasLogged(
            Strings.network.api_source_healthy_despite_failure(host: APISources.primary)
        )
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
