//
//  WorkflowComponentsIntegrationTests.swift
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
final class WorkflowComponentsIntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    private let remoteConfigFake = RemoteConfigKillSwitchFake()

    override func setUp() async throws {
        self.forceServerErrorStrategy = ForceServerErrorStrategy { [remoteConfigFake] request in
            remoteConfigFake.action(for: request)
        }

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

    func action(for request: HTTPClient.Request) -> ForceServerErrorStrategy.Action {
        guard case HTTPRequest.Path.remoteConfig = request.httpRequest.path else {
            return .performRequest
        }

        if self.disableRemoteConfig {
            return self.fakeResponse(
                statusCode: 400,
                data: Data(#"{"code":7000,"message":"remote config disabled for test"}"#.utf8),
                request: request
            )
        } else {
            return self.fakeResponse(statusCode: 204, data: Data(), request: request)
        }
    }

    private func fakeResponse(
        statusCode: Int,
        data: Data,
        request: HTTPClient.Request
    ) -> ForceServerErrorStrategy.Action {
        guard let url = request.httpRequest.path.url,
              let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: nil,
                                             headerFields: nil) else {
            return .performRequest
        }

        return .fakeResponse(response, data)
    }

}
