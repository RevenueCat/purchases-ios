//
//  ProductionWorkflowsPaywallComponentsIntegrationTests.swift
//  BackendIntegrationTests
//
//  Created by Rick van der Linden on 7/15/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @testable import RevenueCat
#endif

@MainActor
final class ProductionWorkflowsPaywallComponentsIntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }
    override class var useWorkflows: Bool { true }

    private let remoteConfigFake = RemoteConfigKillSwitchFake()

    override func setUp() async throws {
        self.forceServerErrorStrategy = ForceServerErrorStrategy(
            fakeResponseWithoutPerformingRequest: { [remoteConfigFake] request in
                remoteConfigFake.response(for: request)
            },
            shouldForceServerError: { _ in false }
        )

        try await super.setUp()
    }

    func testOfferingsSkipPaywallComponentsUntilRemoteConfigKillSwitch() async throws {
        let phase1Current = try await self.currentOffering
        expect(phase1Current.identifier) == "default"
        expect(phase1Current.hasPaywall) == true
        expect(phase1Current.paywallComponents).to(beNil())

        self.remoteConfigFake.disableRemoteConfig = true
        _ = try? await self.purchases.logIn("integration-test-workflows-\(UUID().uuidString)")

        let phase2Current = try await self.currentOfferingWithComponents()
        expect(phase2Current.identifier) == "default"
        expect(phase2Current.hasPaywall) == true
        expect(phase2Current.paywallComponents).toNot(beNil())
        expect(phase2Current.paywallComponents?.data).toNot(beNil())
    }

    private func currentOfferingWithComponents() async throws -> Offering {
        for _ in 0..<20 {
            let current = try await self.currentOffering
            if current.paywallComponents != nil {
                return current
            }

            try await Task.sleep(nanoseconds: 100_000_000)
        }

        return try await self.currentOffering
    }

}

private final class RemoteConfigKillSwitchFake: @unchecked Sendable {

    var disableRemoteConfig = false

    func response(for request: HTTPClient.Request) -> (HTTPURLResponse, Data)? {
        guard case HTTPRequest.Path.remoteConfig = request.httpRequest.path else {
            return nil
        }

        if self.disableRemoteConfig {
            return (
                HTTPURLResponse(url: request.httpRequest.path.url!,
                                statusCode: 400,
                                httpVersion: nil,
                                headerFields: nil)!,
                Data(#"{"code":7000,"message":"remote config disabled for test"}"#.utf8)
            )
        } else {
            return (
                HTTPURLResponse(url: request.httpRequest.path.url!,
                                statusCode: 204,
                                httpVersion: nil,
                                headerFields: nil)!,
                Data()
            )
        }
    }

}
