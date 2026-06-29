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

    private static let appUserID = "integrationTestRemoteConfigUser"
    private static let domain = RemoteConfiguration.defaultDomain

    private lazy var remoteConfigAPI = self.createRemoteConfigAPI()

    func fetchRemoteConfig(manifest: String? = nil) async throws -> RemoteConfigFetchResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.remoteConfigAPI.getRemoteConfig(
                request: .init(
                    appUserID: Self.appUserID,
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

    func remoteConfiguration(from container: RemoteConfigContainer) throws -> RemoteConfiguration {
        return try container.configElement.withPayloadBytes { bytes in
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

}

private extension BaseProductionRemoteConfigIntegrationTests {

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
            diagnosticsTracker: nil
        )

        return backend.remoteConfigAPI
    }

}

final class ProductionRemoteConfigIntegrationTests: BaseProductionRemoteConfigIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .informational(Signing.loadPublicKey())
    }

    func testCanFetchRemoteConfig() async throws {
        let result = try await self.fetchRemoteConfig()

        _ = try self.verifyContainerResponse(result)
    }

    func testReplayingManifestReturnsNoContent() async throws {
        let configuration = try self.verifyContainerResponse(
            try await self.fetchRemoteConfig()
        )

        let result = try await self.fetchRemoteConfig(manifest: configuration.manifest)

        self.verifyNoContentResponse(result)
    }

}

final class EnforcedProductionRemoteConfigIntegrationTests: BaseProductionRemoteConfigIntegrationTests {

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return .enforced(Signing.loadPublicKey())
    }

    func testVerifiesSignedResponseWhenVerificationIsEnforced() async throws {
        let result = try await self.fetchRemoteConfig()

        _ = try self.verifyContainerResponse(result)
    }

    func testVerifiesNoContentResponseWhenVerificationIsEnforced() async throws {
        let configuration = try self.verifyContainerResponse(
            try await self.fetchRemoteConfig()
        )

        let result = try await self.fetchRemoteConfig(manifest: configuration.manifest)

        self.verifyNoContentResponse(result)
    }

}
