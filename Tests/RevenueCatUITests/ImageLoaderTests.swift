//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageLoaderTests.swift
//
//  Created by Nacho Soto on 12/7/23.

import Nimble
@testable import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@MainActor
class ImageLoaderTests: TestCase {

    private var urlSession: MockURLSession!
    private var loader: ImageLoader!

    override func setUp() {
        super.setUp()

        self.continueAfterFailure = false

        self.urlSession = .init()
        self.loader = .init(urlSession: self.urlSession)
    }

    func testInitialState() {
        expect(self.loader.result).to(beNil())
    }

    func testResponseError() async {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        self.urlSession.response = .failure(error)

        await self.loader.load(url: Self.url)

        expect(self.loader.result).to(beFailure())
        expect(self.loader.result?.error) == .responseError(error)
    }

    func testNotFound() async {
        self.urlSession.response = .success((
            Data(),
            HTTPURLResponse(
                url: Self.url,
                statusCode: HTTPStatusCode.notFoundError.rawValue,
                httpVersion: nil,
                headerFields: [:]
            )!
        ))

        await self.loader.load(url: Self.url)

        expect(self.loader.result).to(beFailure())
        expect(self.loader.result?.error) == .badResponse(URLError(.badServerResponse))
    }

    func testInvalidImage() async {
        self.urlSession.response = .success((
            Data(),
            HTTPURLResponse(
                url: Self.url,
                statusCode: HTTPStatusCode.success.rawValue,
                httpVersion: nil,
                headerFields: [:]
            )!
        ))

        await self.loader.load(url: Self.url)

        expect(self.loader.result).to(beFailure())
        expect(self.loader.result?.error) == .invalidImage
    }

    func testValidImage() async throws {
        let response = try Self.createValidResponse()
        self.urlSession.response = .success(response)

        await self.loader.load(url: Self.url)

        expect(self.loader.result).to(beSuccess())
        expect(self.loader.result?.value?.pngData()) == UIImage(data: response.0)?.pngData()
        expect(self.urlSession.requestedImage) == Self.url
        expect(self.urlSession.cachePolicy) == .returnCacheDataElseLoad
    }

    func testLoadingImageResetsPreviousResult() async throws {
        let session = MockAsyncURLSession()
        self.loader = .init(urlSession: session)

        func returnImage() async throws {
            let resultSet = self.expectation(description: "Result set")
            resultSet.assertForOverFulfill = false

            let cancellable = self.loader.$result
                .filter { $0 != nil }
                .sink { _ in resultSet.fulfill() }
            defer { cancellable.cancel() }

            let completionSet = self.expectation(that: \.completionSet, on: session, willEqual: true)
            await self.fulfillment(of: [completionSet], timeout: 1)

            session.completion!(.success(try Self.createValidResponse()))
            await self.fulfillment(of: [resultSet], timeout: 1)
        }

        // 1. Request image
        Task {
            await self.loader.load(url: Self.url)
        }

        // 2. Return image
        try await returnImage()

        // 3. Verify result
        expect(self.loader.result).to(beSuccess())

        // 4. Request new image
        let newImageRequested = self.expectation(description: "Image request")
        Task {
            newImageRequested.fulfill()
            await self.loader.load(url: Self.url)
        }

        // 5. Verify image is reset
        await self.fulfillment(of: [newImageRequested], timeout: 1)
        expect(self.loader.result).to(beNil())

        // 6. Return image
        try await returnImage()

        // 7. Verify new image is loaded
        expect(self.loader.result).to(beSuccess())
    }

    private static let url = URL(string: "https://assets.revenuecat.com/test")!
    private static let url2 = URL(string: "https://assets.revenuecat.com/test2")!

    private static func createValidResponse() throws -> (Data, URLResponse) {
        let backgroundImage = try XCTUnwrap(
            PaywallData
                .createDefault(with: [TestData.monthlyPackage], locale: .current)
                .backgroundImageURL
        )
        // We don't want the test to make an actual request loading this
        expect(backgroundImage.scheme) == "file"

        let imageData = try Data(contentsOf: backgroundImage)

        return (
            imageData,
            HTTPURLResponse(
                url: Self.url,
                statusCode: HTTPStatusCode.success.rawValue,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private final class MockURLSession: URLSessionType {

    var requestedImage: URL?
    var cachePolicy: URLRequest.CachePolicy?

    var response: Result<(Data, URLResponse), Error> = .failure(
        NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)
    )

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.requestedImage = request.url
        self.cachePolicy = request.cachePolicy

        return try self.response.get()
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private final class MockAsyncURLSession: NSObject, URLSessionType {

    var completion: (@Sendable (Result<(Data, URLResponse), Error>) -> Void)?

    @objc
    dynamic var completionSet = false

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        defer {
            self.completion = nil
            self.completionSet = false
        }

        self.completionSet = false
        self.completion = nil

        return try await withCheckedContinuation { continuation in
            self.completion = { value in
                continuation.resume(returning: value)
            }
            self.completionSet = true
        }
        .get()
    }

}
