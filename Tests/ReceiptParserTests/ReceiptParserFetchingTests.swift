//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptParserFetchingTests.swift
//
//  Created by Nacho Soto on 1/10/23.

import Nimble
@testable import ReceiptParser
import XCTest

class ReceiptParserFetchingTests: XCTestCase {

    private let parser: PurchasesReceiptParser = .default
    private var mockFileReader: MockFileReader!
    private var mockBundle: MockBundle!

    override func setUp() {
        super.setUp()

        self.mockFileReader = .init()
        self.mockBundle = .init()
    }

    func testParseWithNoReceiptThrowsError() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch PurchasesReceiptParser.Error.failedToLoadLocalReceipt {
            // expected error
        } catch {
            fail("Unexpected error: \(error)")
        }

        expect(self.mockFileReader.invokedContentsOfURL).to(haveCount(1))
        expect(self.mockFileReader.invokedContentsOfURL.first?.value) == 1
    }

    func testParseWithNilURLThrowsError() throws {
        self.mockBundle.receiptURLResult = .nilURL

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch {
            expect(error).to(matchError(PurchasesReceiptParser.Error.receiptNotPresent))
        }
    }

    func testParsingEmptyReceiptThrowsError() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt
        self.mockFileReader.mock(url: try XCTUnwrap(self.mockBundle.appStoreReceiptURL), with: Data())

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch PurchasesReceiptParser.Error.failedToLoadLocalReceipt(MockFileReader.Error.emptyMockedData) {
            // expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testParseReceipt() throws {
        self.mockBundle.receiptURLResult = .receiptWithData

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)

        let receipt = try self.fetchAndParse()
        expect(receipt.bundleId) == "com.revenuecat.sampleapp"
        expect(receipt.applicationVersion) == "4"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.opaqueValue).toNot(beNil())
        expect(receipt.sha1Hash).toNot(beNil())
    }

}

// MARK: - Private

private extension ReceiptParserFetchingTests {

    func fetchAndParse() throws -> AppleReceipt {
        return try self.parser.fetchAndParseLocalReceipt(reader: self.mockFileReader,
                                                         bundle: self.mockBundle)
    }

}

// MARK: - MockFileReader

private final class MockFileReader: FileReader {

    enum Error: Swift.Error {
        case noMockedData
        case emptyMockedData
    }

    var mockedURLContents: [URL: Data] = [:]

    func mock(url: URL, with data: Data) {
        self.mockedURLContents[url] = data
    }

    var invokedContentsOfURL: [URL: Int] = [:]

    func contents(of url: URL) throws -> Data {
        self.invokedContentsOfURL[url, default: 0] += 1

        guard let mockedData = self.mockedURLContents[url] else { throw Error.noMockedData }

        if mockedData.isEmpty {
            throw Error.emptyMockedData
        } else {
            return mockedData
        }
    }

}
