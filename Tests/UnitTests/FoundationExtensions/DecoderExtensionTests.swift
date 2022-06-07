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

    func testDecodesDefaultValueForInvalidValue() throws {
        let json = "{\"e\": \"e3\"}"
        let data = try Data.decode(json)

        expect(data.e) == Data.E.defaultValue
    }

    func testDecodesDefaultValueFromAnotherSource() throws {
        expect(try Data2.decodeEmptyData().string) == Data2.DefaultString.defaultValue
    }

}

class DecoderExtensionsIgnoreErrorsTests: TestCase {

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
        let json = "{\"url\": \"not a! valid url@\"}"
        let data = try Data.decode(json)

        expect(data.url).to(beNil())
    }

}

class DecoderExtensionsLossyCollectionTests: TestCase {

    private struct Data: Codable, Equatable {
        struct Content: Codable, Equatable {
            let string: String
        }

        @LossyArray var list: [Int]
        @LossyDictionary var map1: [String: Content]
        @LossyArrayDictionary var map2: [String: [Content]]

        init(list: [Int], map1: [String: Content], map2: [String: [Content]]) {
            self.list = list
            self.map1 = map1
            self.map2 = map2
        }
    }

    func testDecodesActualValues() throws {
        let data = Data(list: [1, 2, 3],
                        map1: ["1": .init(string: "test1"), "2": .init(string: "test2")],
                        map2: ["1": [.init(string: "a"), .init(string: "b")]])
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data
    }

    func testDictionaryKeysAreSnakeCase() throws {
        let keys: Set<String> = [
            "snake_case",
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.monthly_4.99.no_intro",
            "pro.1"
        ]

        let data = Data(list: [],
                        map1: keys.dictionaryWithValues { .init(string: $0) },
                        map2: [:])
        let decodedData = try data.encodeAndDecode()

        expect(Set(decodedData.map1.keys)) == keys
        expect(decodedData) == data

        for key in keys {
            expect(decodedData.map1[key]?.string) == key
        }
    }

    func testIgnoresArrayErrors() throws {
        let json = "{\"list\": [\"not a number\"], \"map1\": {}, \"map2\": {}}"
        let data = try Data.decode(json)

        expect(data.list) == []
    }

    func testKeepsValidArrayMembers() throws {
        let json = "{\"list\": [1, \"not a number\", 3], \"map1\": {}, \"map2\": {}}"
        let data = try Data.decode(json)

        expect(data.list) == [1, 3]
    }

    func testInvalidArrayTypeFailsToDecode() throws {
        let json = "{\"list\": \"not an array\", \"map1\": {}, \"map2\": {}}"
        expect { try Data.decode(json) }.to(throwError())
    }

    func testKeepsValidDictionaryValues() throws {
        // swiftlint:disable:next line_length
        let json = "{\"list\": [], \"map1\": {\"1\": \"not a dictionary\", \"2\": {\"string\": \"test\"}}, \"map2\": {}}"
        let data = try Data.decode(json)

        expect(data.map1) == ["2": .init(string: "test")]
    }

    func testInvalidDictionaryTypeFailsToDecode() throws {
        let json = "{\"list\": [], \"map1\": \"not a dictionary\", \"map2\": {}}"
        expect { try Data.decode(json) }.to(throwError())
    }

    func testIgnoresNestedErrors() throws {
        // swiftlint:disable:next line_length
        let json = "{\"list\": [], \"map1\": {}, \"map2\": {\"1\": \"not a dictionary\", \"2\": {\"string\": \"not an array\"}, \"3\": [{\"string\": \"test\"}, \"not an object\"]}}"
        let data = try Data.decode(json)

        expect(data.map2) == ["3": [.init(string: "test")]]
    }

    func testArrayDictionaryKeysAreSnakeCase() throws {
        let keys: Set<String> = [
            "snake_case",
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.monthly_4.99.no_intro",
            "pro.1"
        ]

        let data = Data(list: [],
                        map1: [:],
                        map2: keys.dictionaryWithValues { [.init(string: $0)] })
        let decodedData = try data.encodeAndDecode()

        expect(decodedData) == data
        expect(Set(decodedData.map2.keys)) == keys

        for key in keys {
            expect(decodedData.map2[key]) == [.init(string: key)]
        }
    }

}

class DecoderExtensionsDefaultDecodableTests: TestCase {

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

    func testDecodesEmptyArrayForIncorrectType() throws {
        let json = "{\"array\": \"this is not an array\"}"
        let data = try Data.decode(json)

        expect(data.array) == []
    }

    func testDecodesEmptyDictionaryForIncorrectType() throws {
        let json = "{\"dictionary\": \"this is not a dictionary\"}"
        let data = try Data.decode(json)

        expect(data.dictionary) == [:]
    }

    func testDecodesEmptyDictionaryIfPartiallyFailsToDecodeData() throws {
        struct Content: Codable, Equatable {
            let string: String
        }

        struct Data: Codable, Equatable {
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
        let data = try Data.decode(json)

        expect(data.dictionary) == [:]
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

 class DecoderExtensionsLossyAndDefaultCompositionTests: TestCase {

     private struct Data: Codable, Equatable {
         @DefaultDecodable.EmptyArray @LossyArray var list: [Int]
         @DefaultDecodable.EmptyDictionary @LossyDictionary var map1: [String: Int]
         @DefaultDecodable.EmptyDictionary @LossyArrayDictionary var map2: [String: [Int]]

         init(list: [Int], map1: [String: Int], map2: [String: [Int]]) {
             self.list = list
             self.map1 = map1
             self.map2 = map2
         }
     }

     func testDecodesActualValues() throws {
         let data = Data(list: [1, 2, 3],
                         map1: ["1": 1, "2": 2],
                         map2: ["1": [1, 2]])
         let decodedData = try data.encodeAndDecode()

         expect(decodedData) == data
     }

     func testIgnoresListErrors() throws {
         let json = "{\"list\": [\"not a number\"], \"map1\": {}, \"map2\": {}}"
         let data = try Data.decode(json)

         expect(data.list) == []
     }

     func testKeepsValidListMembers() throws {
         let json = "{\"list\": [1, \"not a number\", 3], \"map1\": {}, \"map2\": {}}"
         let data = try Data.decode(json)

         expect(data.list) == [1, 3]
     }

     func testKeepsValidMapValues() throws {
         let json = "{\"list\": [], \"map1\": {\"1\": \"not a number\", \"2\": 2}, \"map2\": {}}"
         let data = try Data.decode(json)

         expect(data.map1) == ["2": 2]
     }

     func testInvalidArrayBecomesEmpty() throws {
         let json = "{\"list\": \"not an array\", \"map1\": {}, \"map2\": {}}"
         let data = try Data.decode(json)

         expect(data.list) == []
     }

     func testInvalidDictionaryTypeFailsToDecode() throws {
         let json = "{\"list\": [], \"map1\": \"not a dictionary\", \"map2\": {}}"
         let data = try Data.decode(json)

         expect(data.map1) == [:]
     }

     func testIgnoresNestedErrors() throws {
         // swiftlint:disable:next line_length
         let json = "{\"list\": [], \"map1\": {}, \"map2\": {\"1\": \"not a dictionary\", \"2\": {\"string\": \"not an array\"}, \"3\": [3, \"not a number\"]}}"
         let data = try Data.decode(json)

         expect(data.map2) == ["3": [3]]
     }

 }

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
