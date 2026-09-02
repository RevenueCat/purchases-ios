//
//  Value+JSON.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Production JSON → `Value` parser. Converts the predicate JSON extracted
/// from the SDK artifact into the engine's typed `Value` tree. Used by
/// `RulesEngine.evaluate`; failures surface as `RulesEngine.EvaluationError.parse`.
extension RulesEngine.Value {

    /// Parse a JSON string into a `Value`. `JSONSerialization` returns
    /// numbers as `NSNumber`, so we use `CFNumber` type metadata to
    /// distinguish booleans from ints from doubles — without that, a JSON
    /// `true` and a JSON `1` both round-trip to `NSNumber` and lose their
    /// type intent.
    static func fromJSONString(_ input: String) throws -> RulesEngine.Value {
        guard let data = input.data(using: .utf8) else {
            throw RulesEngine.EvaluationError.parse(message: "non-UTF8 input")
        }
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw RulesEngine.EvaluationError.parse(message: error.localizedDescription)
        }
        return try Self.fromJSONObject(json)
    }

    /// Recursively convert a value produced by `JSONSerialization` (the
    /// `Any` is one of `NSNull`, `NSNumber`, `String`, `[Any]`, or
    /// `[String: Any]`). Throws `RulesEngine.EvaluationError.parse` if it
    /// encounters anything else.
    static func fromJSONObject(_ object: Any) throws -> RulesEngine.Value {
        if object is NSNull {
            return .null
        }
        if let number = object as? NSNumber {
            switch number.jsonNumberKind {
            case .boolean:
                return .bool(number.boolValue)
            case .integer:
                return .int(number.int64Value)
            case .floatingPoint:
                return .float(number.doubleValue)
            }
        }
        if let string = object as? String {
            return .string(string)
        }
        if let array = object as? [Any] {
            return .array(try array.map(Self.fromJSONObject))
        }
        if let dict = object as? [String: Any] {
            var result: [String: RulesEngine.Value] = [:]
            result.reserveCapacity(dict.count)
            for (key, value) in dict {
                result[key] = try Self.fromJSONObject(value)
            }
            return .object(result)
        }
        throw RulesEngine.EvaluationError.parse(
            message: "unexpected JSONSerialization output of type \(type(of: object))"
        )
    }
}
