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

class DecoderExtensionsDefaultValueTests: TestCase {

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

    func testThrowsForInvalidValue() throws {
        let json = "{\"e\": \"e3\"}"

        expect(try Data.decode(json))
            .to(throwError(errorType: DecodingError.self))
    }

    func testDecodesDefaultValueFromAnotherSource() throws {
        expect(try Data2.decodeEmptyData().string) == Data2.DefaultString.defaultValue
    }

}

class DecoderExtensionsIgnoreErrorsTests: TestCase {

    private struct Data: Codable, Equatable {
        @IgnoreDecodeErrors<URL?> var url: URL?

        init(url: URL) {
            self.url = url
        }
    }

    func testDecodesActualValue() throws {
        let data = Data(url: URL(string: "https://revenuecat.com")!)
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data

        self.logger.verifyMessageWasNotLogged("Couldn't decode", allowNoMessages: true)
    }

    func testIgnoresErrors() throws {
        let json = "{\"url\": 1}"
        let data = try Data.decode(json)

        expect(data.url).to(beNil())

        self.logger.verifyMessageWasLogged("Couldn't decode 'Optional<URL>' from json.",
                                           level: .debug,
                                           expectedCount: 1)
    }

    func testIgnoresMissingValue() throws {
        let data = try Data.decode("{}")

        expect(data.url).to(beNil())

        self.logger.verifyMessageWasNotLogged("Couldn't decode", allowNoMessages: true)
    }

    func testDecodesDefaultValueForInvalidValue() throws {
        struct Data: Codable, Equatable {
            enum E: String, DefaultValueProvider, Codable, Equatable {
                case e1
                case e2

                static let defaultValue: Self = .e2
            }

            @IgnoreDecodeErrors<E> var e: E
        }

        let json = "{\"e\": \"e3\"}"

        let data = try Data.decode(json)
        expect(data.e) == .e2

        self.logger.verifyMessageWasLogged("Couldn't decode 'E' from json.",
                                           level: .debug,
                                           expectedCount: 1)
    }

}

class DecoderExtensionsDefaultDecodableTests: TestCase {

    private struct Data: Codable, Equatable {
        @DefaultDecodable.True var bool1: Bool
        @DefaultDecodable.False var bool2: Bool
        @DefaultDecodable.EmptyString var string: String
        @DefaultDecodable.EmptyArray var array: [String]
        @DefaultDecodable.EmptyDictionary var dictionary: [String: Int]
        @DefaultDecodable.Now var date: Date

        init(
            bool1: Bool,
            bool2: Bool,
            string: String,
            array: [String],
            dictionary: [String: Int],
            date: Date
        ) {
            self.bool1 = bool1
            self.bool2 = bool2
            self.string = string
            self.array = array
            self.dictionary = dictionary
            self.date = date
        }
    }

    func testDecodesActualValues() throws {
        let data = Data(bool1: false,
                        bool2: true,
                        string: "test",
                        array: ["a", "b"],
                        dictionary: ["a": 1],
                        date: Date(timeIntervalSince1970: 200000))
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

    func testDecodesDateAsNow() throws {
        expect(try Data.decodeEmptyData().date).to(beCloseToNow())
    }

    func testDoesNotIgnoreErrorsIfNotArray() throws {
        let json = "{\"array\": \"this is not an array\"}"

        expect(try Data.decode(json))
            .to(throwError(errorType: DecodingError.self))
    }

    func testDoesNotIgnoreErrorsIfNotDictionary() throws {
        let json = "{\"dictionary\": \"this is not a dictionary\"}"

        expect(try Data.decode(json))
            .to(throwError(errorType: DecodingError.self))
    }

    func testDoesNotIgnoreErrorsIfPartiallyFailsToDecodeData() throws {
        struct Data: Codable, Equatable {
            struct Content: Codable, Equatable {
                let string: String
            }

            @DefaultDecodable.EmptyDictionary var dictionary: [String: Content]
        }

        let json = """
        {
            "dictionary": {
                "1\": { "invalid_key": false },
                "2\": { "string": "value" }
            }
        }
        """

        expect(try Data.decode(json))
            .to(throwError(errorType: DecodingError.self))
    }

}

class IgnoreEncodableTests: TestCase {

    private struct Data: Codable, Equatable {
        var value: Int
        @IgnoreEncodable var ignored: Int
    }

    func testValueIsNotEncoded() throws {
        let data = Data(value: 2, ignored: 2)
        let encoded = try XCTUnwrap(
            String(data: try JSONEncoder.default.encode(data), encoding: .utf8)
        )

        expect(encoded) == "{\"value\":2}"
    }

    func testValueIsDecoded() throws {
        let json = "{\"value\": 1, \"ignored\": 2}"

        expect(try Data.decode(json)) == .init(value: 1, ignored: 2)
    }

}

class DecoderExtensionsNonEmptyStringTests: TestCase {

    private struct Data: Codable, Equatable {
        @NonEmptyStringDecodable var value: String?

        init(value: String) {
            self.value = value
        }
    }

    func testDecodesActualValue() throws {
        let data = Data(value: "string")
        expect(try data.encodeAndDecode()) == data
    }

    func testDecodesNil() throws {
        let data = try Data.decode("{\"value\": null}")
        expect(data.value).to(beNil())
    }

    func testConvertsEmptyStringToNil() throws {
        let data = try Data.decode("{\"value\": \"\"}")
        expect(data.value).to(beNil())
    }

    func testConvertsSpacesToNil() throws {
        let data = try Data.decode("{\"value\": \"  \"}")
        expect(data.value).to(beNil())
    }

}

class DecoderExtensionsNonEmptyArrayTests: TestCase {

    private struct Data: Codable, Equatable {
        @EnsureNonEmptyCollectionDecodable var value: [String]

        init(value: [String]) {
            self.value = value
        }
    }

    func testDecodesOneValues() throws {
        let data = Data(value: ["1"])
        expect(try data.encodeAndDecode()) == data
    }

    func testDecodesMultipleValues() throws {
        let data = Data(value: ["1", "2"])
        expect(try data.encodeAndDecode()) == data
    }

    func testEncodesEmptyValues() throws {
        expect(try Data(value: []).encodedJSON) == "{\"value\":[]}"
    }

    func testThrowsWhenDecodingEmptyArray() throws {
        expect {
            try Data.decode("{\"value\": []}")
        }.to(throwError(EnsureNonEmptyCollectionDecodable<[String]>.Error()))
    }

}

class DecoderExtensionsNonEmptyDictionaryTests: TestCase {

    private struct Data: Codable, Equatable {
        @EnsureNonEmptyCollectionDecodable var value: [String: Int]

        init(value: [String: Int]) {
            self.value = value
        }
    }

    func testDecodesOneValues() throws {
        let data = Data(value: ["1": 1])
        expect(try data.encodeAndDecode()) == data
    }

    func testDecodesMultipleValues() throws {
        let data = Data(value: ["1": 1, "2": 2])
        expect(try data.encodeAndDecode()) == data
    }

    func testEncodesEmptyValues() throws {
        expect(try Data(value: [:]).encodedJSON) == "{\"value\":{}}"
    }

    func testThrowsWhenDecodingEmptyArray() throws {
        expect {
            try Data.decode("{\"value\": {}}")
        }.to(throwError(EnsureNonEmptyCollectionDecodable<[String: Int]>.Error()))
    }

}

// MARK: - Extensions

extension Decodable where Self: Encodable {

    func encodeAndDecode() throws -> Self {
        return try JSONDecoder.default.decode(
            jsonData: JSONEncoder.default.encode(self)
        )
    }

}

extension Decodable {

    static func decode(_ json: String) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: json.asData)
    }

    static func decodeEmptyData() throws -> Self {
        return try self.decode("{}")
    }

}
