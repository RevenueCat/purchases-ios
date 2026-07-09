//
//  HTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import RevenueCat

class HTTPRequestTimeoutManagerTests: TestCase {

    private var dateProvider: MockCurrentDateProvider!
    private var manager: HTTPRequestTimeoutManager!

    // Distinct from every tier constant, so tests can prove fallback-host/proxied requests use it.
    private static let flatTimeout: TimeInterval = 42

    private static let hostA = "a.example.com"
    private static let hostB = "b.example.com"

    override func setUp() {
        self.dateProvider = MockCurrentDateProvider()
        self.manager = .init(flatTimeout: Self.flatTimeout, dateProvider: self.dateProvider)
        super.setUp()
    }

    private func timeout(host: String?,
                         isFallbackHostRequest: Bool = false,
                         endpointSupportsFallbackURLs: Bool = false,
                         isProxied: Bool = false) -> TimeInterval {
        return self.manager.timeout(host: host,
                                    isFallbackHostRequest: isFallbackHostRequest,
                                    endpointSupportsFallbackURLs: endpointSupportsFallbackURLs,
                                    isProxied: isProxied)
    }

    // MARK: - Base tiers

    func testMainSourceNoFallbackUsesBaseTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: false),
            HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
        )
    }

    func testMainSourceSupportingFallbackUsesBaseTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
    }

    // MARK: - Reduced tiers after a recent timeout

    func testMainSourceNoFallbackUsesReducedTimeoutAfterTimeout() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: false),
            HTTPRequestTimeoutManager.Timeout.mainSourceNoFallbackReduced
        )
    }

    func testMainSourceSupportingFallbackUsesReducedTimeoutAfterTimeout() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    // MARK: - Flat tiers (fallback-host and proxied)

    func testFallbackHostRequestUsesFlatTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            Self.flatTimeout
        )
    }

    func testFallbackHostRequestUsesFlatTimeoutEvenAfterTimeout() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            Self.flatTimeout
        )
    }

    func testProxiedRequestUsesFlatTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            Self.flatTimeout
        )
    }

    func testProxiedRequestNeverConsultsMemory() {
        // Even after a recorded timeout on the same host, a proxied request uses the flat timeout.
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            Self.flatTimeout
        )
    }

    // MARK: - Per-host isolation

    func testTimeoutOnOneHostDoesNotAffectAnotherHost() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
        XCTAssertEqual(
            timeout(host: Self.hostB, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
    }

    func testSuccessOnOneHostDoesNotResetAnotherHost() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)
        manager.recordRequestResult(host: Self.hostB, .successOnMainBackend)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    func testSuccessOnMainBackendClearsOnlyThatHostEntry() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )

        manager.recordRequestResult(host: Self.hostA, .successOnMainBackend)
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
    }

    // MARK: - Per-host expiry

    func testPerHostEntryDoesNotExpireBeforeResetInterval() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // Advance by less than the 10-minute reset interval
        dateProvider.advance(by: 9 * 60)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    func testPerHostEntryExpiresAfterResetInterval() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // Advance past the 10-minute reset interval
        dateProvider.advance(by: 11 * 60)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
    }

    func testMultipleTimeoutsRefreshExpiryPerHost() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        dateProvider.advance(by: 5 * 60)

        // Second timeout refreshes the timestamp for this host
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        dateProvider.advance(by: 6 * 60)

        // 11 minutes since the first timeout, but only 6 since the second: still reduced
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    // MARK: - Nil host

    func testNilHostNeverUsesReducedTimeout() {
        // Recording with a nil host is a no-op
        manager.recordRequestResult(host: nil, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: nil, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
        XCTAssertEqual(
            timeout(host: nil, endpointSupportsFallbackURLs: false),
            HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
        )
    }

    // MARK: - Other result

    func testOtherResultDoesNotChangeState() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )

        manager.recordRequestResult(host: Self.hostA, .other)
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }
}
