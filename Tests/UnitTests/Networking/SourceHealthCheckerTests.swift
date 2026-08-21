//
//  SourceHealthCheckerTests.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

final class SourceHealthCheckerTests: TestCase {

    private static let sourceBaseURL = URL(string: "https://api.revenuecat.com/")!
    private static let healthPath = "/v1/health/connectivity"

    private var dateProvider: MockCurrentDateProvider!
    private var checker: SourceHealthChecker!

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if os(watchOS)
        // See https://github.com/AliSoftware/OHHTTPStubs/issues/287
        try XCTSkipIf(true, "OHHTTPStubs does not currently support watchOS")
        #endif

        self.dateProvider = MockCurrentDateProvider()
        self.checker = SourceHealthChecker(dateProvider: self.dateProvider)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    func test2xxResponsesAreHealthy() {
        for statusCode in [200, 204, 299] as [Int32] {
            HTTPStubs.removeAllStubs()
            let checker = SourceHealthChecker(dateProvider: self.dateProvider)
            self.stubHealthEndpoint { HTTPStubsResponse(data: Data(), statusCode: statusCode, headers: nil) }

            expect(self.checkHealth(with: checker))
                .to(beTrue(), description: "Expected \(statusCode) to be healthy")
        }
    }

    func testNon2xxResponsesAreNotHealthy() {
        for statusCode in [301, 404, 500, 503] as [Int32] {
            HTTPStubs.removeAllStubs()
            let checker = SourceHealthChecker(dateProvider: self.dateProvider)
            self.stubHealthEndpoint { HTTPStubsResponse(data: Data(), statusCode: statusCode, headers: nil) }

            expect(self.checkHealth(with: checker))
                .to(beFalse(), description: "Expected \(statusCode) to not be healthy")
        }
    }

    func testConnectionFailureIsNotHealthy() {
        self.stubHealthEndpoint { HTTPStubsResponse(error: URLError(.cannotConnectToHost)) }

        expect(self.checkHealth()) == false
    }

    func testChecksTheHealthConnectivityPathOfTheSource() {
        let requestedPaths: Atomic<[String]> = .init([])
        stub(condition: isHost("api.revenuecat.com")) { request in
            requestedPaths.modify { $0.append(request.url?.path ?? "") }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        expect(self.checkHealth()) == true
        expect(requestedPaths.value) == [Self.healthPath]
    }

    func testBuildsTheHealthURLForABaseURLWithoutATrailingSlash() {
        let requestedPaths: Atomic<[String]> = .init([])
        stub(condition: isHost("api.revenuecat.com")) { request in
            requestedPaths.modify { $0.append(request.url?.path ?? "") }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        expect(self.checkHealth(of: URL(string: "https://api.revenuecat.com")!)) == true
        expect(requestedPaths.value) == [Self.healthPath]
    }

    func testCachesTheResultWithinItsValidityWindow() {
        let requestCount: Atomic<Int> = .init(0)
        self.stubHealthEndpoint {
            requestCount.modify { $0 += 1 }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        expect(self.checkHealth()) == true
        self.dateProvider.advance(by: 9)
        expect(self.checkHealth()) == true
        expect(requestCount.value) == 1
    }

    func testCachesUnhealthyResultsToo() {
        let requestCount: Atomic<Int> = .init(0)
        self.stubHealthEndpoint {
            requestCount.modify { $0 += 1 }
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }

        expect(self.checkHealth()) == false
        expect(self.checkHealth()) == false
        expect(requestCount.value) == 1
    }

    func testChecksAgainOnceTheCachedResultExpires() {
        let requestCount: Atomic<Int> = .init(0)
        self.stubHealthEndpoint {
            requestCount.modify { $0 += 1 }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        expect(self.checkHealth()) == true
        self.dateProvider.advance(by: 10)
        expect(self.checkHealth()) == true
        expect(requestCount.value) == 2
    }

    func testCachesResultsPerSource() {
        stub(condition: isHost("api.revenuecat.com") && isPath(Self.healthPath)) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        stub(condition: isHost("api.rc-backup.com") && isPath(Self.healthPath)) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 503, headers: nil)
        }

        expect(self.checkHealth()) == true
        expect(self.checkHealth(of: URL(string: "https://api.rc-backup.com/")!)) == false
    }

    func testConcurrentChecksForTheSameSourceShareOneRequest() {
        let requestCount: Atomic<Int> = .init(0)
        self.stubHealthEndpoint {
            requestCount.modify { $0 += 1 }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
                .responseTime(0.2)
        }

        let results: Atomic<[Bool]> = .init([])
        let group = DispatchGroup()
        for _ in 0..<2 {
            group.enter()
            self.checker.checkHealth(ofSourceBaseURL: Self.sourceBaseURL) { isHealthy in
                results.modify { $0.append(isHealthy) }
                group.leave()
            }
        }
        expect(group.wait(timeout: .now() + 5)) == .success

        expect(results.value) == [true, true]
        expect(requestCount.value) == 1
    }

    // MARK: - Helpers

    private func stubHealthEndpoint(_ response: @escaping () -> HTTPStubsResponse) {
        stub(condition: isHost("api.revenuecat.com") && isPath(Self.healthPath)) { _ in response() }
    }

    /// Blocks until the (possibly asynchronous) health check completes and returns its result.
    private func checkHealth(
        of url: URL = SourceHealthCheckerTests.sourceBaseURL,
        with checker: SourceHealthChecker? = nil
    ) -> Bool? {
        let result: Atomic<Bool?> = .init(nil)
        let group = DispatchGroup()
        group.enter()
        (checker ?? self.checker).checkHealth(ofSourceBaseURL: url) { isHealthy in
            result.value = isHealthy
            group.leave()
        }
        guard group.wait(timeout: .now() + 5) == .success else { return nil }
        return result.value
    }

}
