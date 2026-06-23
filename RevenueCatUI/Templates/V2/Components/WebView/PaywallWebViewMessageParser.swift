//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewMessageParser.swift

import Foundation

#if !os(tvOS) // For Paywalls V2

/// Known message types in the Paywalls V2 `web_view` postMessage protocol (`protocol_version: 1`).
/// A caseless namespace (not consumer-facing) so the public ``PaywallWebViewMessage/type`` stays a
/// plain string.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallWebViewMessageType {

    static let stepLoaded = "rc:step-loaded"
    static let stepComplete = "rc:step-complete"
    static let requestVariables = "rc:request-variables"
    static let error = "rc:error"

    /// Native → web messages.
    static let variables = "rc:variables"

}

/// Validates and parses raw `web_view` message bodies into typed ``PaywallWebViewMessage`` values.
///
/// Deliberately `WebKit`-free: it accepts the already-extracted `WKScriptMessage.body` as `Any`
/// so the full validation surface is unit-testable without a live `WKWebView`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewMessageParser {

    /// Maximum size (in bytes of the serialized JSON) accepted for a single inbound message.
    static let maxPayloadBytes = 64 * 1024

    enum ParseError: Error, Equatable {
        case notAnObject
        case missingType
        case missingComponentID
        case componentIDMismatch(expected: String, received: String)
        case oversizedPayload(bytes: Int)
        case invalidResponses
        case missingError
        case invalidValue
        /// Known-but-unsupported or entirely unknown message type — dropped per v1 policy.
        case unsupportedType(String)
    }

    private enum Keys {
        static let type = "type"
        static let componentID = "component_id"
        static let responses = "responses"
        static let error = "error"
    }

    /// The identifier of the `web_view` component this parser accepts messages for.
    let expectedComponentID: String

    func parse(_ body: Any) -> Result<PaywallWebViewMessage, ParseError> {
        guard let dictionary = body as? [String: Any] else {
            return .failure(.notAnObject)
        }

        // Reject non-JSON-serializable bodies up front. `isValidJSONObject` is used before
        // `data(withJSONObject:)` because the latter raises an (uncatchable) `NSException` rather
        // than throwing a Swift error for invalid types such as `Date`.
        guard JSONSerialization.isValidJSONObject(dictionary) else {
            return .failure(.invalidValue)
        }

        // Enforce the payload size limit before allocating typed values.
        if let serialized = try? JSONSerialization.data(withJSONObject: dictionary) {
            guard serialized.count <= Self.maxPayloadBytes else {
                return .failure(.oversizedPayload(bytes: serialized.count))
            }
        }

        guard let type = dictionary[Keys.type] as? String else {
            return .failure(.missingType)
        }

        guard let componentID = dictionary[Keys.componentID] as? String else {
            return .failure(.missingComponentID)
        }

        guard componentID == self.expectedComponentID else {
            return .failure(.componentIDMismatch(expected: self.expectedComponentID, received: componentID))
        }

        return self.message(type: type, componentID: componentID, dictionary: dictionary)
    }

    private func message(
        type: String,
        componentID: String,
        dictionary: [String: Any]
    ) -> Result<PaywallWebViewMessage, ParseError> {
        switch type {
        case PaywallWebViewMessageType.stepLoaded,
             PaywallWebViewMessageType.requestVariables:
            return .success(.init(componentID: componentID, type: type))

        case PaywallWebViewMessageType.stepComplete:
            return Self.stepComplete(type: type, componentID: componentID, dictionary: dictionary)

        case PaywallWebViewMessageType.error:
            guard let errorMessage = dictionary[Keys.error] as? String else {
                return .failure(.missingError)
            }
            return .success(.init(componentID: componentID, type: type, error: errorMessage))

        default:
            // Unknown message types are dropped in v1.
            return .failure(.unsupportedType(type))
        }
    }

    private static func stepComplete(
        type: String,
        componentID: String,
        dictionary: [String: Any]
    ) -> Result<PaywallWebViewMessage, ParseError> {
        guard let rawResponses = dictionary[Keys.responses] else {
            return .success(.init(componentID: componentID, type: type))
        }
        guard let object = rawResponses as? [String: Any],
              let converted = Self.convert(object: object) else {
            return .failure(.invalidResponses)
        }
        return .success(.init(componentID: componentID, type: type, responses: converted))
    }

    private static func convert(object: [String: Any]) -> [String: PaywallWebViewValue]? {
        var result: [String: PaywallWebViewValue] = [:]
        result.reserveCapacity(object.count)
        for (key, value) in object {
            guard let converted = PaywallWebViewValue(jsonObject: value) else {
                return nil
            }
            result[key] = converted
        }
        return result
    }

}

#endif
