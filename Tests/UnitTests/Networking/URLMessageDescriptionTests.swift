//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLMessageDescriptionTests.swift
//
//  Created by RevenueCat on 8/12/26.

#if DEBUG

import Nimble
import XCTest

@testable import RevenueCat

class URLRequestDescriptionTests: TestCase {

    func testDescriptionIncludesMethodAndURL() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/subscribers/appUserID"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let firstLine = request.httpDescription().components(separatedBy: "\n").first

        expect(firstLine) == "POST https://api.revenuecat.com/v1/subscribers/appUserID"
    }

    func testDescriptionDefaultsToGETWhenMethodIsNotSet() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/health"))
        let request = URLRequest(url: url)

        let firstLine = request.httpDescription().components(separatedBy: "\n").first

        expect(firstLine) == "GET https://api.revenuecat.com/v1/health"
    }

    func testDescriptionShowsPlaceholderWhenURLIsNil() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com/v1/health"))
        var request = URLRequest(url: url)
        request.url = nil

        let firstLine = request.httpDescription().components(separatedBy: "\n").first

        expect(firstLine) == "GET <none>"
    }

    func testDescriptionSortsHeadersAlphabetically() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        var request = URLRequest(url: url)
        request.setValue("value-z", forHTTPHeaderField: "X-Header-Z")
        request.setValue("value-a", forHTTPHeaderField: "A-Header")

        let lines = request.httpDescription().components(separatedBy: "\n")

        expect(lines).to(haveCount(3))
        expect(lines[1]) == "A-Header: value-a"
        expect(lines[2]) == "X-Header-Z: value-z"
    }

    func testDescriptionOmitsHeaderLinesWhenThereAreNoHeaders() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        let request = URLRequest(url: url)

        let lines = request.httpDescription().components(separatedBy: "\n")

        expect(lines).to(haveCount(1))
    }

    func testDescriptionIncludesBodyWhenValidUTF8() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        var request = URLRequest(url: url)
        request.httpBody = try XCTUnwrap("{\"key\":\"value\"}".data(using: .utf8))

        let description = request.httpDescription()

        expect(description).to(contain("{\"key\":\"value\"}"))
    }

    func testDescriptionOmitsBodyWhenNotValidUTF8() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        var request = URLRequest(url: url)
        request.httpBody = Data([0xFF, 0xFE, 0xFD])

        let description = request.httpDescription()

        expect(description.components(separatedBy: "\n")).to(haveCount(1))
    }

    func testDescriptionTruncatesBodyToMaxBodySize() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        var request = URLRequest(url: url)
        request.httpBody = try XCTUnwrap("0123456789".data(using: .utf8))

        let description = request.httpDescription(maxBodySize: 5)

        expect(description).to(contain("01234"))
        expect(description).toNot(contain("0123456789"))
    }

}

class URLResponseDescriptionTests: TestCase {

    func testHTTPResponseDescriptionIncludesStatusLineAndSortedHeaders() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["X-Header-Z": "value-z", "A-Header": "value-a"]
        ))

        let lines = response.httpDescription(with: nil).components(separatedBy: "\n")

        let expectedFirstLine = "200 \(HTTPURLResponse.localizedString(forStatusCode: 200))"
        expect(lines.first) == expectedFirstLine
        expect(lines).to(contain("A-Header: value-a"))
        expect(lines).to(contain("X-Header-Z: value-z"))

        // Headers must appear in alphabetical order.
        let headerAIndex = try XCTUnwrap(lines.firstIndex(of: "A-Header: value-a"))
        let headerXIndex = try XCTUnwrap(lines.firstIndex(of: "X-Header-Z: value-z"))
        expect(headerAIndex) < headerXIndex
    }

    func testHTTPResponseDescriptionIncludesBodyWhenPresent() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let body = try XCTUnwrap("response body".data(using: .utf8))

        let description = response.httpDescription(with: body)

        expect(description).to(contain("response body"))
    }

    func testHTTPResponseDescriptionTruncatesBodyToMaxBodySize() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let body = try XCTUnwrap("0123456789".data(using: .utf8))

        let description = response.httpDescription(with: body, maxBodySize: 5)

        expect(description).to(contain("01234"))
        expect(description).toNot(contain("0123456789"))
    }

    func testHTTPResponseDescriptionOmitsBodyWhenEmpty() throws {
        let url = try XCTUnwrap(URL(string: "https://api.revenuecat.com"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil))

        let description = response.httpDescription(with: Data())

        expect(description.components(separatedBy: "\n")).to(haveCount(1))
    }

    func testNonHTTPResponseDescriptionIncludesTypeAndURL() throws {
        let url = try XCTUnwrap(URL(string: "https://cdn.example.com/file.json"))
        let response = URLResponse(url: url, mimeType: "application/json", expectedContentLength: -1,
                                   textEncodingName: nil)

        let lines = response.httpDescription(with: nil).components(separatedBy: "\n")

        expect(lines.first) == "\(URLResponse.self)"
        expect(lines).to(contain("URL: https://cdn.example.com/file.json"))
        expect(lines).to(contain("Mime-Type: application/json"))
        expect(lines).toNot(containElementSatisfying { $0.hasPrefix("Expected-Content-Length") })
        expect(lines).toNot(containElementSatisfying { $0.hasPrefix("Text-Encoding-Name") })
    }

    func testNonHTTPResponseDescriptionIncludesExpectedContentLengthWhenPositive() throws {
        let url = try XCTUnwrap(URL(string: "https://cdn.example.com/file.json"))
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 1024, textEncodingName: nil)

        let description = response.httpDescription(with: nil)

        expect(description).to(contain("Expected-Content-Length: 1024"))
    }

}

#endif
