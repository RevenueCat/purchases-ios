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

    func testCachedOfferingsAreUsedWhenCachedOfferingsExistsAndServerErrorWith5xx() async throws {
        let networkOfferings = try await Purchases.shared.offerings()

        self.serverDown()
        await resetSingleton()

        let cachedOfferings = try await Purchases.shared.offerings()

        expect(cachedOfferings.response) == networkOfferings.response
        expect(cachedOfferings.loadedFromDiskCache) == true
    }

    func testCachedOfferingsAreUsedWhenCachedOfferingsExistsAndServerCannotBeReached() async throws {
        let networkOfferings = try await Purchases.shared.offerings()

        self.serverDown()
        await resetSingleton()

        let cachedOfferings = try await Purchases.shared.offerings()

        expect(cachedOfferings.response) == networkOfferings.response
        expect(cachedOfferings.loadedFromDiskCache) == true

    }

    func testCachedOfferingsAreNotUsedWhenCachedOfferingsExistsServerReturns4xx() async throws {
        _ = try await Purchases.shared.offerings()

        self.forceServerErrorStrategy = ForceServerErrorStrategy(
            fakeResponseWithoutPerformingRequest: { (request: HTTPClient.Request) -> (HTTPURLResponse, Data)? in
                guard case HTTPRequest.Path.getOfferings(appUserID: _) = request.httpRequest.path else {
                    return nil
                }
                return (
                    HTTPURLResponse(url: request.httpRequest.path.url!,
                                    statusCode: 401,
                                    httpVersion: nil,
                                    headerFields: nil)!,
                    Data()
                )
            },
            shouldForceServerError: { _ in true}
        )
        await resetSingleton()

        do {
            _ = try await Purchases.shared.offerings()
            XCTFail("Expected to error")
        } catch {
            expect(error).to(matchError(ErrorCode.unknownError))
        }

    }
}
