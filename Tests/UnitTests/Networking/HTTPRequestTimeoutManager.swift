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
    
    private var dateProvider: MockDateProvider!
    private var manager: HTTPRequestTimeoutManager!
    
    override func setUp() {
        self.dateProvider = MockDateProvider()
        self.manager = .init(dateProvider: self.dateProvider)
        super.setUp()
    }
 
    func testDefaultTimeoutForPathWithFallback() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.default.rawValue
        )
    }
    
    func testDefaultTimeoutForPathWithFallbackForFallbackRequest() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: true),
            HTTPRequestTimeoutManager.Timeout.default.rawValue
        )
    }
    
    func testDefaultTimeoutForPathWithoutFallback() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.default.rawValue
        )
    }
    
    func testDefaultTimeoutForPathWithoutFallbackForFallbackRequest() {
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withoutFallback, isFallback: true),
            HTTPRequestTimeoutManager.Timeout.default.rawValue
        )
    }
    
    func testTimeoutForPathWithFallbackAfterFailedRequestToMainBackend() {
        manager.recordRequestResult(.timeoutOnMainBackendSupportingFallback)
        
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
    }
    
    func testTimeoutForPathWithFallbackAfterFailedRequestToMainBackendShouldExpire() {
        manager.recordRequestResult(.timeoutOnMainBackendSupportingFallback)
        
        // expire time is 10s
        dateProvider.advance(by: 2)
        
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.reduced.rawValue
        )
        
        // expire time is 10s
        dateProvider.advance(by: 11)
        
        XCTAssertEqual(
            manager.timeout(for: Mockpath.withFallback, isFallback: false),
            HTTPRequestTimeoutManager.Timeout.defaultForMainBackendRequestSupportingFallback.rawValue
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
    
    class MockDateProvider: DateProvider, @unchecked Sendable {
        private var date = Date(timeIntervalSince1970: 0)
        
        func advance(by timeInterval: TimeInterval) {
            date = date.advanced(by: timeInterval)
        }
        
        override func now() -> Date {
            date
        }
    }
}
