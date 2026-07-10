//
//  RemoteConfigBlobDownloaderTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigBlobDownloaderTests: TestCase {

    override func tearDown() {
        MockRemoteConfigBlobURLProtocol.handler = nil

        super.tearDown()
    }

    func testDataReturnsResponseBodyForSuccessfulHTTPStatus() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/blob"))
        let expectedData = "blob".asData
        MockRemoteConfigBlobURLProtocol.handler = { request in
            return (
                try Self.response(url: try XCTUnwrap(request.url), statusCode: 200),
                expectedData
            )
        }

        let data = try await self.downloader().data(from: url)

        expect(data) == expectedData
    }

    func testDataThrowsForUnsuccessfulHTTPStatus() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/blob"))
        MockRemoteConfigBlobURLProtocol.handler = { request in
            return (
                try Self.response(url: try XCTUnwrap(request.url), statusCode: 404),
                Data()
            )
        }

        do {
            _ = try await self.downloader().data(from: url)
            fail("Expected downloader to throw")
        } catch let error as URLSessionRemoteConfigBlobDownloader.Error {
            expect(error) == .unexpectedStatusCode(404)
        }
    }

    func testDataThrowsForNonOKSuccessfulHTTPStatus() async throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/blob"))
        MockRemoteConfigBlobURLProtocol.handler = { request in
            return (
                try Self.response(url: try XCTUnwrap(request.url), statusCode: 204),
                Data()
            )
        }

        do {
            _ = try await self.downloader().data(from: url)
            fail("Expected downloader to throw")
        } catch let error as URLSessionRemoteConfigBlobDownloader.Error {
            expect(error) == .unexpectedStatusCode(204)
        }
    }

    // MARK: - Per-source timeouts

    func testAsksForNoFallbackTierKeyedByBlobHost() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let manager = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
        Self.respond(statusCode: 200)

        _ = try await self.downloader(timeoutManager: manager).data(from: url)

        expect(manager.lastTimeoutHost) == "blob.example.com"
        expect(manager.lastTimeoutIsFallbackHostRequest) == false
        expect(manager.lastTimeoutEndpointSupportsFallbackURLs) == false
        expect(manager.lastTimeoutIsProxied) == false
    }

    func testAppliesComputedTimeoutToTheRequest() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let manager = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
        manager.timeoutToReturn = 7
        var capturedTimeout: TimeInterval?
        MockRemoteConfigBlobURLProtocol.handler = { request in
            capturedTimeout = request.timeoutInterval
            return (try Self.response(url: try XCTUnwrap(request.url), statusCode: 200), Data())
        }

        _ = try await self.downloader(timeoutManager: manager).data(from: url)

        expect(capturedTimeout) == 7
    }

    func testRecordsSuccessOnMainBackendForSuccessfulDownload() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let manager = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
        Self.respond(statusCode: 200)

        _ = try await self.downloader(timeoutManager: manager).data(from: url)

        expect(manager.recordedHosts) == ["blob.example.com"]
        guard case .successOnMainBackend = try XCTUnwrap(manager.recordedResults.first) else {
            fail("Expected successOnMainBackend, got \(manager.recordedResults)")
            return
        }
    }

    func testRecordsMainSourceTimedOutWhenTheRequestTimesOut() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let manager = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
        MockRemoteConfigBlobURLProtocol.handler = { _ in throw URLError(.timedOut) }

        do {
            _ = try await self.downloader(timeoutManager: manager).data(from: url)
            fail("Expected downloader to throw")
        } catch {
            expect(manager.recordedHosts) == ["blob.example.com"]
            guard case .mainSourceTimedOut = try XCTUnwrap(manager.recordedResults.first) else {
                fail("Expected mainSourceTimedOut, got \(manager.recordedResults)")
                return
            }
        }
    }

    func testRecordsOtherForNonTimeoutFailures() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let manager = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
        Self.respond(statusCode: 404)

        do {
            _ = try await self.downloader(timeoutManager: manager).data(from: url)
            fail("Expected downloader to throw")
        } catch {
            guard case .other = try XCTUnwrap(manager.recordedResults.first) else {
                fail("Expected other, got \(manager.recordedResults)")
                return
            }
        }
    }

    // MARK: - Per-source memory (shared no-fallback tier)

    func testFreshBlobSourceUsesNoFallbackBaseTimeout() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let downloader = self.downloader(dateProvider: MockCurrentDateProvider())

        let captured = try await self.captureRequestTimeout(downloader, url: url)

        expect(captured) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
    }

    func testTimedOutBlobSourceUsesReducedTimeoutOnTheNextAttempt() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let downloader = self.downloader(dateProvider: MockCurrentDateProvider())

        try await self.timeOut(downloader, url: url)
        let captured = try await self.captureRequestTimeout(downloader, url: url)

        expect(captured) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallbackReduced
    }

    func testSuccessfulBlobDownloadClearsTheSourceMemory() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let downloader = self.downloader(dateProvider: MockCurrentDateProvider())

        try await self.timeOut(downloader, url: url)
        // A success at the reduced timeout clears the host's fail-fast memory.
        Self.respond(statusCode: 200)
        _ = try await downloader.data(from: url)

        let captured = try await self.captureRequestTimeout(downloader, url: url)
        expect(captured) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
    }

    func testBlobSourceMemoryIsIsolatedPerHost() async throws {
        let hostA = try XCTUnwrap(URL(string: "https://a.example.com/blob"))
        let hostB = try XCTUnwrap(URL(string: "https://b.example.com/blob"))
        let downloader = self.downloader(dateProvider: MockCurrentDateProvider())

        try await self.timeOut(downloader, url: hostA)
        let captured = try await self.captureRequestTimeout(downloader, url: hostB)

        // Host B never timed out, so it still uses the base timeout.
        expect(captured) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
    }

    func testBlobSourceReducedTimeoutExpiresAfterResetInterval() async throws {
        let url = try XCTUnwrap(URL(string: "https://blob.example.com/blob"))
        let dateProvider = MockCurrentDateProvider()
        let downloader = self.downloader(dateProvider: dateProvider)

        try await self.timeOut(downloader, url: url)
        // Let the 10-minute per-host memory expire before the next attempt.
        dateProvider.advance(by: 601)
        let captured = try await self.captureRequestTimeout(downloader, url: url)

        expect(captured) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallback
    }

}

private extension RemoteConfigBlobDownloaderTests {

    func downloader(
        timeoutManager: HTTPRequestTimeoutManagerType = MockHTTPRequestTimeoutManager(defaultTimeout: 15)
    ) -> URLSessionRemoteConfigBlobDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockRemoteConfigBlobURLProtocol.self]
        return URLSessionRemoteConfigBlobDownloader(
            timeoutManager: timeoutManager,
            session: URLSession(configuration: configuration)
        )
    }

    /// A downloader backed by a real (shared-behaviour) timeout manager so tests can exercise the per-host tiers.
    func downloader(dateProvider: DateProvider) -> URLSessionRemoteConfigBlobDownloader {
        return self.downloader(timeoutManager: HTTPRequestTimeoutManager(dateProvider: dateProvider))
    }

    /// Stubs the mock protocol to answer every request with the given status code.
    static func respond(statusCode: Int) {
        MockRemoteConfigBlobURLProtocol.handler = { request in
            return (try Self.response(url: try XCTUnwrap(request.url), statusCode: statusCode), Data())
        }
    }

    /// Forces a timed-out attempt so the source's fail-fast memory is armed.
    func timeOut(_ downloader: URLSessionRemoteConfigBlobDownloader, url: URL) async throws {
        MockRemoteConfigBlobURLProtocol.handler = { _ in throw URLError(.timedOut) }
        do {
            _ = try await downloader.data(from: url)
            fail("Expected the attempt to time out")
        } catch {
            // Expected: the timeout is recorded for the host.
        }
    }

    /// Runs one successful attempt and returns the `timeoutInterval` the downloader set on the request.
    func captureRequestTimeout(
        _ downloader: URLSessionRemoteConfigBlobDownloader,
        url: URL
    ) async throws -> TimeInterval {
        var capturedTimeout: TimeInterval?
        MockRemoteConfigBlobURLProtocol.handler = { request in
            capturedTimeout = request.timeoutInterval
            return (try Self.response(url: try XCTUnwrap(request.url), statusCode: 200), Data())
        }
        _ = try await downloader.data(from: url)
        return try XCTUnwrap(capturedTimeout)
    }

    static func response(
        url: URL,
        statusCode: Int
    ) throws -> HTTPURLResponse {
        return try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ))
    }

}

private final class MockRemoteConfigBlobURLProtocol: URLProtocol {

    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(self.request)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        } catch {
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }

}
