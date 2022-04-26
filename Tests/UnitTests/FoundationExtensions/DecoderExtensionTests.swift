//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DecoderExtensionTests.swift
//
//  Created by Nacho Soto on 4/26/22.

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable type_name identifier_name nesting

class DecoderExtensionsDefaultValueTests: XCTestCase {

    private struct Data: Codable, Equatable {
        enum E: String, DefaultValueProvider, Codable, Equatable {
            case e1
            case e2

            static let defaultValue: Self = .e2
        }

        @DefaultValue<E> var e: E

        init(e: E) {
            self.e = e
        }
    }

    private struct Data2: Codable, Equatable {
        enum DefaultString: DefaultValueProvider {
            static var defaultValue: String = "default"
        }

        @DefaultValue<DefaultString> var string: String

        init(string: String) {
            self.string = string
        }
    }

    func testDecodesActualValue() throws {
        let data = Data(e: .e1)
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data
    }

    func testDecodesDefaultValueIfMissing() throws {
        expect(try Data.decodeEmptyData().e) == Data.E.defaultValue
    }

    func testDecodesDefaultValueForInvalidValue() throws {
        let json = "{\"e\": \"e3\"}".data(using: .utf8)!
        let data: Data = try JSONDecoder.default.decode(jsonData: json)

        expect(data.e) == Data.E.defaultValue
    }

    func testDecodesDefaultValueFromAnotherSource() throws {
        expect(try Data2.decodeEmptyData().string) == Data2.DefaultString.defaultValue
    }

}

class DecoderExtensionsIgnoreErrorsTests: XCTestCase {

    private struct Data: Codable, Equatable {
        @IgnoreDecodeErrors var url: URL?

        init(url: URL) {
            self.url = url
        }
    }

    func testDecodesActualValue() throws {
        let data = Data(url: URL(string: "https://revenuecat.com")!)
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data
    }

    func testIgnoresErrors() throws {
        let json = "{\"url\": \"not a! valid url@\"}".data(using: .utf8)!
        let data: Data = try JSONDecoder.default.decode(jsonData: json)

        expect(data.url).to(beNil())
    }

}

class DecoderExtensionsDefaultDecodableTests: XCTestCase {

    private struct Data: Codable, Equatable {
        @DefaultDecodable.True var bool1: Bool
        @DefaultDecodable.False var bool2: Bool
        @DefaultDecodable.EmptyString var string: String
        @DefaultDecodable.EmptyArray var array: [String]
        @DefaultDecodable.EmptyDictionary var dictionary: [String: Int]

        init(
            bool1: Bool,
            bool2: Bool,
            string: String,
            array: [String],
            dictionary: [String: Int]
        ) {
            self.bool1 = bool1
            self.bool2 = bool2
            self.string = string
            self.array = array
            self.dictionary = dictionary
        }
    }

    func testDecodesActualValues() throws {
        let data = Data(bool1: false, bool2: true, string: "test", array: ["a", "b"], dictionary: ["a": 1])
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data
    }

    func testDecodesDefaultTrue() throws {
        expect(try Data.decodeEmptyData().bool1) == true
    }

    func testDecodesDefaultFalse() throws {
        expect(try Data.decodeEmptyData().bool2) == false
    }

    func testDecodesDefaultString() throws {
        expect(try Data.decodeEmptyData().string) == ""
    }

    func testDecodesDefaultArray() throws {
        expect(try Data.decodeEmptyData().array) == []
    }

    func testDecodesDefaultDictionary() throws {
        expect(try Data.decodeEmptyData().dictionary) == [:]
    }

}

private extension Decodable where Self: Encodable {

    func encodeAndDecode() throws -> Self {
        return try JSONDecoder.default.decode(
            jsonData: JSONEncoder.default.encode(self)
        )
    }

}

private extension Decodable {

    static func decodeEmptyData() throws -> Self {
        let json = "{}".data(using: .utf8)!
        return try JSONDecoder.default.decode(jsonData: json)
    }

}
