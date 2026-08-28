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

    override func setUp() async throws {
        self.forceServerErrorStrategy = ForceServerErrorStrategy { request in
            guard case HTTPRequest.Path.remoteConfig = request.httpRequest.path,
                  let url = request.httpRequest.path.url(preferIAMPath: false),
                  let response = HTTPURLResponse(url: url,
                                                 statusCode: 204,
                                                 httpVersion: nil,
                                                 headerFields: nil) else {
                return .performRequest
            }

            return .fakeResponse(response, Data())
        }

        try await super.setUp()
    }

    func testOfferingsSkipPaywallComponentsWhenRemoteConfigIsUnavailable() async throws {
        let current = try await self.currentOffering

        expect(current.identifier) == "default"
        expect(current.hasPaywall) == true
        expect(current.internalPaywallComponents).to(beNil())
    }

}
