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

}

private extension RemoteConfigBlobDownloaderTests {

    func downloader() -> URLSessionRemoteConfigBlobDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockRemoteConfigBlobURLProtocol.self]
        return URLSessionRemoteConfigBlobDownloader(session: URLSession(configuration: configuration))
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
