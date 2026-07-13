//
//  Value+Decodable.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

// Test-only `Decodable` conformance for `Value`. Production `Value` stays
// free of any `Codable` dependency; this lives in the test target so the
// fixture harness can decode predicates and variables straight into the
// engine's value model. The decode order (bool → integer → double → string
// → array → object) mirrors JSON's value space; integral floats such as
// `1.0` may decode as the integer case, which is harmless here because the
// engine bridges int/float in equality, comparison, and arithmetic.
extension Value: Decodable {

    /// Decodes a single JSON value into the engine's `Value` model, trying
    /// each JSON shape in turn (null, bool, integer, double, string, array,
    /// object).
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int64.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .float(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([Value].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: Value].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unsupported JSON value for Value"
                )
            )
        }
    }
}
