//
//  ProductionRemoteConfigIntegrationTests.swift
//  BackendIntegrationTests
//
//  Created by Rick van der Linden on 29/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @testable import RevenueCat
#endif

// swiftlint:disable type_name

@MainActor
class BaseProductionRemoteConfigIntegrationTests: BaseBackendIntegrationTests {

    private static let domain = RemoteConfiguration.defaultDomain

    private lazy var remoteConfigAPI = self.createRemoteConfigAPI()
    private lazy var appUserID = self.createAppUserID()

    func fetchRemoteConfig(
        fetchContext: RemoteConfigFetchContext,
        manifest: String? = nil
    ) async throws -> RemoteConfigFetchResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.remoteConfigAPI.getRemoteConfig(
                request: .init(
                    fetchContext: fetchContext,
                    appUserID: self.appUserID,
                    domain: Self.domain,
                    manifest: manifest,
                    prefetchedBlobs: []
                ),
                isAppBackgrounded: false
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchRemoteConfigFallback() async throws -> RemoteConfigFallbackFetchResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.remoteConfigAPI.getRemoteConfigFallback(
                domain: Self.domain,
                isAppBackgrounded: false
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func remoteConfiguration(from container: RemoteConfigContainer) throws -> RemoteConfiguration {
        return try container.configElement.withDecodedPayloadBytes { bytes in
            try JSONDecoder.default.decode(
                RemoteConfiguration.self,
                from: Data(bytes)
            )
        }
    }

    func verifyRemoteConfiguration(_ configuration: RemoteConfiguration) {
        expect(configuration.domain) == Self.domain
        expect(configuration.manifest).toNot(beEmpty())
    }

    func verifyContainerResponse(_ result: RemoteConfigFetchResult) throws -> RemoteConfiguration {
        expect(result.verificationResult) == .verified

        let container = try XCTUnwrap(result.container)
        let configuration = try self.remoteConfiguration(from: container)
        self.verifyRemoteConfiguration(configuration)

        return configuration
    }

    func verifyNoContentResponse(_ result: RemoteConfigFetchResult) {
        expect(result.verificationResult) == .verified
        expect(result.container).to(beNil())
    }

    func verifyRemoteConfigFallbackResponse(_ result: RemoteConfigFallbackFetchResult) throws {
        expect(result.verificationResult) == .verified

        self.verifyRemoteConfiguration(result.configuration)
    }

    func createRemoteConfigManager(storageRootURL: URL) throws -> RemoteConfigManager {
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: storageRootURL)
        let cacheBasePath = "\(RemoteConfigDiskCache.basePath)-\(UUID().uuidString)"
        let synchronizedCache = SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: cacheBasePath,
            directoryType: directoryType
        )
        let cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: directoryType))
            .appendingPathComponent(cacheBasePath, isDirectory: true)
        let diskCache = RemoteConfigDiskCache(cache: synchronizedCache)
        let blobStore = RemoteConfigBlobStore(
            fileManager: .default,
            directoryURL: cacheDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        )
        let sourceProvider = RemoteConfigSourceProvider(topicStore: diskCache)
        let blobFetcher = RemoteConfigBlobFetcher(
            blobStore: blobStore,
            sourceProvider: sourceProvider
        )

        return RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: diskCache,
            blobStore: blobStore,
            blobFetcher: blobFetcher,
            currentUserProvider: ProductionRemoteConfigCurrentUserProvider(appUserID: self.appUserID)
        )
    }

}

private extension BaseProductionRemoteConfigIntegrationTests {

    func createAppUserID() -> String {
        let rawIdentifier = "\(type(of: self)).\(self.name)"
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitizedIdentifier = rawIdentifier.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "-"
        }

        return "integrationTestRemoteConfigUser-\(String(sanitizedIdentifier))"
    }

    func createRemoteConfigAPI() -> RemoteConfigAPI {
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storeKitVersion: Self.storeKitVersion,
            apiKey: self.apiKey,
            responseVerificationMode: Self.responseVerificationMode,
            dangerousSettings: DangerousSettings(),
            isAppBackgrounded: false,
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        )
        let backend = Backend(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            operationDispatcher: .default,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            ),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil
        )

        return backend.remoteConfigAPI
    }

}

final class ProductionRemoteConfigIntegrationTests: BaseProductionRemoteConfigIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .informational(Signing.loadPublicKey())
    }

    func testCanFetchRemoteConfig() async throws {
        let result = try await self.fetchRemoteConfig(fetchContext: .appStart)

        _ = try self.verifyContainerResponse(result)
    }

    func testReplayingManifestReturnsNoContent() async throws {
        let configuration = try self.verifyContainerResponse(
            try await self.fetchRemoteConfig(fetchContext: .appStart)
        )

        // A `.read` context lets the backend honor the refresh-interval fast path and return no content,
        // whereas `.appStart` would force a full resolve and return the config again.
        let result = try await self.fetchRemoteConfig(fetchContext: .read, manifest: configuration.manifest)

        self.verifyNoContentResponse(result)
    }

    func testCanFetchRemoteConfigFromFallbackURL() async throws {
        let result = try await self.fetchRemoteConfigFallback()

        try self.verifyRemoteConfigFallbackResponse(result)
    }

    func testFetchesProductEntitlementMappingThroughRemoteConfig() async throws {
        let storageRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProductionRemoteConfigIntegrationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: storageRootURL) }

        let manager = try self.createRemoteConfigManager(storageRootURL: storageRootURL)
        defer { manager.close() }

        let provider = ProductEntitlementMappingTopicProvider(manager: manager)
        let response = await provider.getProductEntitlementMapping()
        let mapping = try XCTUnwrap(response)

        expect(mapping.products["com.revenuecat.monthly_4.99.1_week_intro"]?.entitlements) == ["premium"]
        expect(mapping.products["lifetime"]?.entitlements) == ["premium"]
        expect(mapping.products["com.revenuecat.intro_test.monthly.1_week_intro"]?.entitlements ?? []).to(beEmpty())
        expect(mapping.products["consumable.10_coins"]?.entitlements ?? []).to(beEmpty())
    }

}

final class EnforcedProductionRemoteConfigIntegrationTests: BaseProductionRemoteConfigIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    func testVerifiesSignedResponseWhenVerificationIsEnforced() async throws {
        let result = try await self.fetchRemoteConfig(fetchContext: .appStart)

        _ = try self.verifyContainerResponse(result)
    }

    func testVerifiesNoContentResponseWhenVerificationIsEnforced() async throws {
        let configuration = try self.verifyContainerResponse(
            try await self.fetchRemoteConfig(fetchContext: .appStart)
        )

        // A `.read` context lets the backend honor the refresh-interval fast path and return no content,
        // whereas `.appStart` would force a full resolve and return the config again.
        let result = try await self.fetchRemoteConfig(fetchContext: .read, manifest: configuration.manifest)

        self.verifyNoContentResponse(result)
    }

    func testVerifiesFallbackResponseWhenVerificationIsEnforced() async throws {
        let result = try await self.fetchRemoteConfigFallback()

        try self.verifyRemoteConfigFallbackResponse(result)
    }

}

private struct ProductionRemoteConfigCurrentUserProvider: CurrentUserProvider {

    let appUserID: String

    var currentAppUserID: String { self.appUserID }
    var currentUserIsAnonymous: Bool { false }

}
