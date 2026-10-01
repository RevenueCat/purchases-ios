//
// Created by RevenueCat on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class DataExtensionsTests: TestCase {

    func testAsString() {
        let data = Data([
            0xe3, 0x88, 0x15, 0x2d,
            0x6c, 0x67, 0xf4, 0xd5,
            0xf7, 0xa7, 0x8e, 0xdf,
            0x07, 0x39, 0x46, 0xf1,
            0x58, 0x35, 0x7f, 0x89,
            0xa1, 0xdc, 0x74, 0xdf,
            0xf8, 0x0a, 0x79, 0x67,
            0x40, 0xfd, 0x9d, 0x91
        ])

        expect(data.asString) == "e388152d6c67f4d5f7a78edf073946f158357f89a1dc74dff80a796740fd9d91"
    }

    func testAsFetchToken() {
        let storedReceiptText = Self.readFile(named: Self.receiptFilename)
        let storedReceiptData = Self.sampleReceiptData(receiptName: Self.receiptFilename)
        let fetchToken = storedReceiptData.asFetchToken

        expect(fetchToken).to(equal(storedReceiptText))
        expect(storedReceiptData.asFetchToken).to(equal(storedReceiptText))
    }

    func testStringDataAsUUID() {
        expect("sample string".asData.uuid) == UUID(uuidString: "73616D70-6C65-2073-7472-696E67000000")
    }

    func testStringDataAsHashString() {
        expect("sample string".asData.hashString) == "99ad9154f94977dd8913f3b7ea14091d00e52b8931c2bc1cfc7ea62b7c26727b"
    }

    func testDataAsHashStringHashesTheEntireData() {
        expect("a relatively long string that ends in 0".asData.hashString)
        != "a relatively long string that ends in 1".asData.hashString
    }

    func testStringDataAsSha1() {
        expect("sample string".asData.sha1.asString) == "243182b9d0b085c06005bf773212854bf7cd4694"
    }

    func testDataAsSha1HashesTheEntireData() {
        expect("a relatively long string that ends in 0".asData.sha1)
        != "a relatively long string that ends in 1".asData.sha1
    }

    func testReceiptDataAsHashString() {
        let storedReceiptData = Self.sampleReceiptData(receiptName: Self.receiptFilename)

        expect(storedReceiptData.hashString) == "d18b7c0ffe3577a9dd732840a30ac4b3655b412e69d84f07d991f48e8d3273d8"
    }

    func testRandomNonceHasCorrectSize() throws {
        expect(Data.randomNonce().count) == Data.nonceLength
    }

    func testRandomNonceIsRandom() throws {
        let random1 = Data.randomNonce()
        let random2 = Data.randomNonce()

        expect(random1) != random2
    }

    func testBase64URLEncodedInitDecodesStringWithoutPadding() throws {
        let expected = try XCTUnwrap("hello".data(using: .utf8))

        let data = try XCTUnwrap(Data(base64URLEncoded: "aGVsbG8"))

        expect(data) == expected
    }

    func testBase64URLEncodedInitAddsRequiredPadding() throws {
        let expected = try XCTUnwrap("hi".data(using: .utf8))

        let data = try XCTUnwrap(Data(base64URLEncoded: "aGk"))

        expect(data) == expected
    }

    func testBase64URLEncodedInitReplacesURLSafeCharacters() throws {
        // These three bytes base64-encode to "+/+/", which uses "-_-_" in the URL-safe alphabet.
        let expected = Data([0xFB, 0xFF, 0xBF])

        let data = try XCTUnwrap(Data(base64URLEncoded: "-_-_"))

        expect(data) == expected
    }

    func testBase64URLEncodedInitRoundTripsArbitraryData() throws {
        let original = Data((0...255).map { UInt8($0) })

        let urlSafeString = original.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let decoded = try XCTUnwrap(Data(base64URLEncoded: urlSafeString))

        expect(decoded) == original
    }

    func testBase64URLEncodedInitWithEmptyStringReturnsEmptyData() throws {
        let data = try XCTUnwrap(Data(base64URLEncoded: ""))

        expect(data) == Data()
    }

    func testBase64URLEncodedInitReturnsNilForInvalidInput() {
        expect(Data(base64URLEncoded: "not!valid base64")).to(beNil())
    }

}

extension DataExtensionsTests {

    static func sampleReceiptData(receiptName: String) -> Data {
        let receiptText = self.readFile(named: receiptName)
        guard let receiptData = Data(base64Encoded: receiptText) else {
            fatalError("Couldn't decode base64 file: \(receiptName).\(Self.fileExtension)")
        }
        return receiptData
    }

    static func readFile(named filename: String) -> String {
        guard let pathString = Bundle(for: Self.self).path(forResource: filename,
                                                           ofType: Self.fileExtension) else {
            fatalError("File \(filename).\(Self.fileExtension) not found")
        }
        do {
            return try String(contentsOfFile: pathString, encoding: .utf8)
        } catch let error {
            fatalError("Couldn't read file named \(filename).\(Self.fileExtension).\n" +
                       "Error: \(error.localizedDescription)")
        }
    }

    private static let fileExtension = "txt"

    private static let receiptFilename = "base64EncodedReceiptSampleForDataExtension"

}
