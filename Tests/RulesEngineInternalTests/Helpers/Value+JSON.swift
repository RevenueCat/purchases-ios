//
//  Value+JSON.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

/// Test-only convenience for converting a JSON literal into a `Value`. Lets
/// the tests express predicates the same way they appear in rule artifacts
/// instead of building the tree by hand.
///
/// Production code never goes through this path: native callers will
/// construct `Value` trees from their own JSON parser when wiring this
/// engine to the SDK. Mirroring the Rust evaluator's `cfg(test)` JSON
/// helper, this lives in the test target only.
extension Value {

    /// Parse a JSON string into a `Value`. `JSONSerialization` returns
    /// numbers as `NSNumber`, so we use `CFNumber` type metadata to
    /// distinguish booleans from ints from doubles — without that, a JSON
    /// `true` and a JSON `1` both round-trip to `NSNumber` and lose their
    /// type intent.
    static func fromJSONString(_ input: String) throws -> Value {
        guard let data = input.data(using: .utf8) else {
            throw RuleError.parse(message: "non-UTF8 input")
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return try Value.fromJSONObject(json)
        } catch let error as RuleError {
            throw error
        } catch {
            throw RuleError.parse(message: error.localizedDescription)
        }
    }

    /// Recursively convert a value produced by `JSONSerialization` (the
    /// `Any` is one of `NSNull`, `NSNumber`, `String`, `[Any]`, or
    /// `[String: Any]`). Throws `RuleError.parse` if it encounters anything
    /// else — better to fail loudly than to silently coerce unknown
    /// Foundation types (`Date`, `NSValue`, …) to `.null`.
    static func fromJSONObject(_ object: Any) throws -> Value {
        if object is NSNull {
            return .null
        }
        if let number = object as? NSNumber {
            // CoreFoundation booleans (`kCFBooleanTrue` / `kCFBooleanFalse`)
            // are bridged to NSNumber but carry the boolean type ID, so
            // `CFGetTypeID` is the only reliable way to tell them apart from
            // a JSON integer of value 0 or 1.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            // `objCType` reports the NSNumber storage type using Objective-C
            // type encodings. See:
            // swiftlint:disable:next line_length
            // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
            // JSONSerialization typically uses 'q' for whole numbers and 'd'
            // for fractional ones — that's how we keep `100` → .int(100) and
            // `100.0` → .float(100.0).
            let type = String(cString: number.objCType)
            switch type {
            case "c", "i", "s", "l", "q", "C", "I", "S", "L", "Q":
                return .int(number.int64Value)
            default:
                return .float(number.doubleValue)
            }
        }
        if let string = object as? String {
            return .string(string)
        }
        if let array = object as? [Any] {
            return .array(try array.map(Value.fromJSONObject))
        }
        if let dict = object as? [String: Any] {
            var result: [String: Value] = [:]
            result.reserveCapacity(dict.count)
            for (key, value) in dict {
                result[key] = try Value.fromJSONObject(value)
            }
            return .object(result)
        }
        throw RuleError.parse(
            message: "unexpected JSONSerialization output of type \(type(of: object))"
        )
    }
}
