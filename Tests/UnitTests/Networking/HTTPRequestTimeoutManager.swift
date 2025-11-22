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

    private static let defaultTimeout: TimeInterval = 60

    override func setUp() {
        self.dateProvider = MockCurrentDateProvider()
        self.manager = .init(defaultTimeout: Self.defaultTimeout, dateProvider: self.dateProvider)
        super.setUp()
    }

    /// Tests that initially the default timeout for a main backend request support fallback is returned
    /// when the request supports a fallback
    func testDefaultTimeoutForPathWithFallback() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )
    }

    /// Initially the default timeout should be returned for a request that is a fallback request
    func testDefaultTimeoutForPathWithFallbackForFallbackRequest() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: true),
            Self.defaultTimeout
        )
    }

    /// For a path that does not support fallbacks the default timeout should be used initially
    func testDefaultTimeoutForPathWithoutFallback() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: false),
            Self.defaultTimeout
        )
    }

    /// For a path that does not support fallbacks but is a fallback request the default
    /// timeout should be used initially
    func testDefaultTimeoutForPathWithoutFallbackForFallbackRequest() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: true),
            Self.defaultTimeout
        )
    }

    /// For a request to a path on the main backend that supports fallbacks, after a succesful request
    /// to the main backend (within the reset timeout interval) should use the reduced timeout
    func testTimeoutForPathWithFallbackAfterFailedRequestToMainBackend() {
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)

        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }

    /// For a request to a path on the main backend that supports fallbacks, after a succesful request
    /// to the main backend after the reset timeout interval has elapsed
    /// should use the default timeout for a main backend request that supports fallbacks
    func testTimeoutForPathWithFallbackAfterFailedRequestToMainBackendShouldExpire() {
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)

        // expire time is 10m
        dateProvider.advance(by: 2)

        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // expire time is 10m
        dateProvider.advance(by: 11 * 60)

        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )
    }

    /// After a succesful request on the main backend the last timeout request date should be reset
    func testSuccessOnMainBackendResetsTimeoutState() {
        // Record timeout first
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Record success - should reset timeout state
        manager.recordRequestResult(.successOnMainBackend)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )
    }

    /// Receving a `.other` After a timeout on the main backend should not change the state
    func testOtherResultDoesNotChangeTimeoutState() {
        // Record timeout first
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Record .other - should not change state
        manager.recordRequestResult(.other)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }

    /// Ensures that the timeout does not reset before the `timeoutResetInterval`
    func testTimeoutDoesNotResetBeforeResetInterval() {
        // Record timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Advance time by less than reset interval (9 seconds, reset interval is 10)
        dateProvider.advance(by: 9)

        // Timeout should still be reduced
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }

    /// Ensures that the timeout does not reset if no timeout has occurred
    func testTimeoutDoesNotResetIfNoTimeoutHasOccurred() {
        // No timeout recorded
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )

        // Advance time by more than reset interval
        dateProvider.advance(by: 11)

        // Should still be default since no timeout occurred
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )
    }

    /// Ensures that regardless of multiple calls going out after each other the state
    /// is always up to date
    func testMultipleTimeoutsUpdateTimeoutStateCorrectly() {
        // First timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Advance time by 5 seconds
        dateProvider.advance(by: 5)

        // Second timeout - should update timestamp
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Advance time by 5 seconds more (10 seconds total from first timeout, but only 5 from second)
        dateProvider.advance(by: 5)

        // Should still be reduced because last timeout was only 5 seconds ago
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }

    /// Ensures that a succes on the main backend after a timeout resets the timeout
    /// right away
    func testSuccessOnMainBackendResetsTimeoutEvenIfTimeoutOccurredRecently() {
        // Record timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )

        // Advance time by only 1 second
        dateProvider.advance(by: 1)

        // Record success - should reset immediately regardless of time
        manager.recordRequestResult(.successOnMainBackend)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.mainBackendRequestSupportingFallback.rawValue
        )
    }

    /// Ensures that multiple follow up requests all use the reduced timeout
    /// after a timeout on the main backend when the request supports a fallback
    func testTimeoutStatePersistsAcrossMultipleGetTimeoutCalls() {
        // Record timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)

        // Multiple calls should all return reduced timeout
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }

    /// Ensures that fallback endpoints always use the default timeout even
    /// after recording a timeout
    func testFallbackRequestsAlwaysUseDefaultTimeoutRegardlessOfTimeoutState() {
        // Record timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)

        // Fallback requests should always use default timeout
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: true),
            Self.defaultTimeout
        )

        // Even after success, fallback should still use default timeout
        manager.recordRequestResult(.successOnMainBackend)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: true),
            Self.defaultTimeout
        )
    }

    /// Ensures that endpoints without fallback support always use the default timeout
    /// even after recording a timeout
    func testEndpointsWithoutFallbackSupportAlwaysUseDefaultTimeout() {
        // Initially
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: false),
            Self.defaultTimeout
        )

        // Even after recording timeout
        manager.recordRequestResult(.timeoutOnMainBackendForFallbackSupportedEndpoint)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: false),
            Self.defaultTimeout
        )

        // After success
        manager.recordRequestResult(.successOnMainBackend)
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: false),
            Self.defaultTimeout
        )
    }

    enum Mockpath: HTTPRequestPath {
        case withFallback
        case withoutFallback

        static var serverHostURL: URL { URL(string: "https://api.revenuecat.com")! }

        var authenticated: Bool { true }

        var shouldSendEtag: Bool { true }

        var supportsSignatureVerification: Bool { false }

        var needsNonceForSigning: Bool { false }

        var name: String { "Test" }

        var relativePath: String { "/v1/test" }

        var fallbackUrls: [URL] {
            switch self {
            case .withFallback:
                return [
                    Self.serverHostURL.appendingPathComponent("/fallback")
                ]
            case .withoutFallback:
                return []
            }
        }
    }
}
