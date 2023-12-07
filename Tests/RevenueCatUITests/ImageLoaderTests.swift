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
        let backgroundImage = try XCTUnwrap(
            PaywallData
                .createDefault(with: [TestData.monthlyPackage], locale: .current)
                .backgroundImageURL
        )
        // We don't want the test to make an actual request loading this
        expect(backgroundImage.scheme) == "file"

        let imageData = try Data(contentsOf: backgroundImage)

        self.urlSession.response = .success((
            imageData,
            HTTPURLResponse(
                url: Self.url,
                statusCode: HTTPStatusCode.success.rawValue,
                httpVersion: nil,
                headerFields: [:]
            )!
        ))

        await self.loader.load(url: backgroundImage)

        expect(self.loader.result).to(beSuccess())
        expect(self.loader.result?.value?.pngData()) == UIImage(data: imageData)?.pngData()
        expect(self.urlSession.requestedImage) == backgroundImage
        expect(self.urlSession.cachePolicy) == .returnCacheDataElseLoad
    }

    private static let url = URL(string: "https://assets.revenuecat.com/test")!

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
