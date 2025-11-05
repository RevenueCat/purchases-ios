//
//  CachedOfferingsUsageIntegrationTest.swift
//  BackendIntegrationTests
//
//  Created by Antonio Pallares on 4/11/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class CachedOfferingsUsageIntegrationTest: BaseStoreKitIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    private var allServerDown: Bool = false

    override var forceServerErrorStrategy: ForceServerErrorStrategy? {
        return .init { [weak self] _ in
            return self?.allServerDown == true
        }
    }

    func testCachedOfferingsAreUsedWhenCachedOfferingsAndServerErrorWith5xx() async throws {
        let networkOfferings = try await Purchases.shared.offerings()

        self.allServerDown = true
        await resetSingleton()

        let cachedOfferings = try await Purchases.shared.offerings()

        expect(cachedOfferings.response) == networkOfferings.response

        // TODO: assert cachedOfferings comes from cache
    }

}
