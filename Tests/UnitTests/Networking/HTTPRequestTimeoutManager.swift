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

    // A custom `networkTimeout` distinct from every built-in tier constant (2, 5, 15, 30), so tests
    // can prove the developer-provided value replaces the built-in base/flat tiers.
    private static let customTimeout: TimeInterval = 42

    private var customDateProvider: MockCurrentDateProvider!
    private var customManager: HTTPRequestTimeoutManager!

    private static let hostA = "a.example.com"
    private static let hostB = "b.example.com"

    override func setUp() {
        self.dateProvider = MockCurrentDateProvider()
        self.manager = .init(networkTimeout: .default, dateProvider: self.dateProvider)

        self.customDateProvider = MockCurrentDateProvider()
        self.customManager = .init(networkTimeout: .custom(Self.customTimeout),
                                   dateProvider: self.customDateProvider)

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

    private func customTimeout(host: String?,
                               isFallbackHostRequest: Bool = false,
                               endpointSupportsFallbackURLs: Bool = false,
                               isProxied: Bool = false) -> TimeInterval {
        return self.customManager.timeout(host: host,
                                          isFallbackHostRequest: isFallbackHostRequest,
                                          endpointSupportsFallbackURLs: endpointSupportsFallbackURLs,
                                          isProxied: isProxied)
    }

    // MARK: - Base tiers (default)

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

    // MARK: - Reduced tiers after a recent timeout (default)

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

    // MARK: - Flat tiers (fallback-host and proxied, default)

    func testFallbackHostRequestUsesFlatTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.flat
        )
    }

    func testFallbackHostRequestUsesFlatTimeoutEvenAfterTimeout() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.flat
        )
    }

    func testProxiedRequestUsesFlatTimeout() {
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            HTTPRequestTimeoutManager.Timeout.flat
        )
    }

    func testProxiedRequestNeverConsultsMemory() {
        // Even after a recorded timeout on the same host, a proxied request uses the flat timeout.
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            HTTPRequestTimeoutManager.Timeout.flat
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

    func testMultipleHostsRetainIndependentReducedState() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)
        manager.recordRequestResult(host: Self.hostB, .mainSourceTimedOut)

        // Both hosts are reduced at the same time, each resolving to its own endpoint tier.
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: false),
            HTTPRequestTimeoutManager.Timeout.mainSourceNoFallbackReduced
        )
        XCTAssertEqual(
            timeout(host: Self.hostB, endpointSupportsFallbackURLs: true),
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

    func testPerHostExpiryIsIndependent() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        dateProvider.advance(by: 5 * 60)
        manager.recordRequestResult(host: Self.hostB, .mainSourceTimedOut)

        // 6 more minutes: host A is 11 minutes old (expired), host B is 6 minutes old (still valid).
        dateProvider.advance(by: 6 * 60)

        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )
        XCTAssertEqual(
            timeout(host: Self.hostB, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    func testHostBecomesReducedAgainAfterEntryExpiresAndTimesOutAgain() {
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // Let the entry expire: back to base.
        dateProvider.advance(by: 11 * 60)
        XCTAssertEqual(
            timeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallback
        )

        // A fresh timeout re-arms the reduced tier.
        manager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)
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

    // MARK: - Custom networkTimeout base tiers

    func testCustomMainSourceSupportingFallbackUsesCustomBaseTimeout() {
        // Base tier for a fallback-supporting endpoint becomes the developer-provided timeout.
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
    }

    func testCustomMainSourceNoFallbackUsesCustomBaseTimeout() {
        // Base tier for an endpoint without fallback support becomes the developer-provided timeout.
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: false),
            Self.customTimeout
        )
    }

    // MARK: - Custom networkTimeout reduced tiers (unchanged by the custom value)

    func testCustomMainSourceSupportingFallbackUsesFixedReducedTimeoutAfterTimeout() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // The reduced fail-fast tier stays fixed even with a custom timeout.
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
    }

    func testCustomMainSourceNoFallbackUsesFixedReducedTimeoutAfterTimeout() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // The reduced fail-fast tier stays fixed even with a custom timeout.
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: false),
            HTTPRequestTimeoutManager.Timeout.mainSourceNoFallbackReduced
        )
    }

    // MARK: - Custom networkTimeout flat tiers (fallback-host and proxied)

    func testCustomFallbackHostRequestUsesCustomTimeout() {
        XCTAssertEqual(
            customTimeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
    }

    func testCustomFallbackHostRequestUsesCustomTimeoutEvenAfterTimeout() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            customTimeout(host: Self.hostA, isFallbackHostRequest: true, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
    }

    func testCustomProxiedRequestUsesCustomTimeout() {
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            Self.customTimeout
        )
    }

    func testCustomProxiedRequestNeverConsultsMemory() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true, isProxied: true),
            Self.customTimeout
        )
    }

    // MARK: - Custom networkTimeout nil host

    func testCustomNilHostNeverUsesReducedTimeout() {
        customManager.recordRequestResult(host: nil, .mainSourceTimedOut)

        XCTAssertEqual(
            customTimeout(host: nil, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
        XCTAssertEqual(
            customTimeout(host: nil, endpointSupportsFallbackURLs: false),
            Self.customTimeout
        )
    }

    // MARK: - Custom networkTimeout per-host memory

    func testCustomTimeoutOnOneHostDoesNotAffectAnotherHost() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // Host A recently timed out: reduced fail-fast tier (fixed).
        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            HTTPRequestTimeoutManager.Timeout.mainSourceSupportingFallbackReduced
        )
        // Host B is untouched: custom base timeout.
        XCTAssertEqual(
            customTimeout(host: Self.hostB, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
    }

    func testCustomPerHostEntryExpiresBackToCustomBaseTimeout() {
        customManager.recordRequestResult(host: Self.hostA, .mainSourceTimedOut)

        // Advance past the 10-minute reset interval: the entry expires and the base tier returns.
        customDateProvider.advance(by: 11 * 60)

        XCTAssertEqual(
            customTimeout(host: Self.hostA, endpointSupportsFallbackURLs: true),
            Self.customTimeout
        )
    }
}
