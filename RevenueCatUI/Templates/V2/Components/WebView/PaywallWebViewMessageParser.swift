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
    static let resize = "resize"

    /// Native → web messages.
    static let variables = "rc:variables"

}

/// Validates and parses transport envelopes into typed ``PaywallWebViewMessage`` values.
///
/// Deliberately `WebKit`-free so the full validation surface is unit-testable without a live
/// `WKWebView`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewMessageParser {

    /// Maximum size (in bytes of the serialized JSON) accepted for a single inbound frame.
    static let maxPayloadBytes = 64 * 1024

    enum ParseError: Error, Equatable {
        case notAnObject
        case invalidEnvelope
        case missingType
        case componentIDMismatch(expected: String, received: String)
        case oversizedPayload(bytes: Int)
        case invalidResponses
        case missingError
        case invalidValue
        case missingRequestID
        /// Known-but-unsupported or entirely unknown message type — dropped per v1 policy.
        case unsupportedType(String)
    }

    struct ParsedAppMessage {
        let message: PaywallWebViewMessage
        /// Set when the inbound frame is a transport `request` that expects a `response`.
        let requestID: String?
        let requestType: String?
    }

    private static let stepCompleteReservedPayloadKeys: Set<String> = [
        WebViewEnvelope.Field.channel,
        WebViewEnvelope.Field.protocolVersion,
        WebViewEnvelope.Field.kind,
        WebViewEnvelope.Field.type,
        WebViewEnvelope.Field.componentID,
        WebViewEnvelope.Field.id,
        WebViewEnvelope.Field.error,
        WebViewEnvelope.Field.variables
    ]

    /// The identifier of the `web_view` component this parser accepts messages for.
    let expectedComponentID: String

    func parseEnvelope(_ body: Any) -> Result<ParsedAppMessage, ParseError> {
        guard let dictionary = Self.dictionary(from: body) else {
            return .failure(.notAnObject)
        }

        guard JSONSerialization.isValidJSONObject(dictionary) else {
            return .failure(.invalidValue)
        }

        if let serialized = try? JSONSerialization.data(withJSONObject: dictionary) {
            guard serialized.count <= Self.maxPayloadBytes else {
                return .failure(.oversizedPayload(bytes: serialized.count))
            }
        }

        guard let envelope = WebViewEnvelope.parse(dictionary) else {
            return .failure(.invalidEnvelope)
        }

        switch envelope.kind {
        case WebViewEnvelope.kindMessage, WebViewEnvelope.kindRequest:
            return self.parseAppMessage(envelope: envelope)

        default:
            return .failure(.invalidEnvelope)
        }
    }

    private func parseAppMessage(
        envelope: WebViewEnvelope.Parsed
    ) -> Result<ParsedAppMessage, ParseError> {
        guard envelope.componentID == self.expectedComponentID else {
            return .failure(.componentIDMismatch(
                expected: self.expectedComponentID,
                received: envelope.componentID
            ))
        }

        guard let type = envelope.type, !type.isEmpty else {
            return .failure(.missingType)
        }

        if envelope.kind == WebViewEnvelope.kindRequest, envelope.id == nil {
            return .failure(.missingRequestID)
        }

        let messageResult = self.message(
            type: type,
            componentID: envelope.componentID,
            envelope: envelope
        )

        switch messageResult {
        case .success(let message):
            let requestID = envelope.kind == WebViewEnvelope.kindRequest ? envelope.id : nil
            return .success(ParsedAppMessage(
                message: message,
                requestID: requestID,
                requestType: type
            ))

        case .failure(let error):
            return .failure(error)
        }
    }

    private func message(
        type: String,
        componentID: String,
        envelope: WebViewEnvelope.Parsed
    ) -> Result<PaywallWebViewMessage, ParseError> {
        switch type {
        case PaywallWebViewMessageType.stepLoaded,
             PaywallWebViewMessageType.requestVariables,
             PaywallWebViewMessageType.resize:
            return .success(.init(componentID: componentID, type: type))

        case PaywallWebViewMessageType.stepComplete:
            return Self.stepComplete(type: type, componentID: componentID, envelope: envelope)

        case PaywallWebViewMessageType.error:
            guard let errorMessage = Self.errorMessage(from: envelope) else {
                return .failure(.missingError)
            }
            return .success(.init(componentID: componentID, type: type, error: errorMessage))

        default:
            return .failure(.unsupportedType(type))
        }
    }

    private static func stepComplete(
        type: String,
        componentID: String,
        envelope: WebViewEnvelope.Parsed
    ) -> Result<PaywallWebViewMessage, ParseError> {
        guard let payload = envelope.payload, !payload.isEmpty else {
            return .success(.init(componentID: componentID, type: type))
        }

        if let responsesObject = payload[WebViewEnvelope.Field.responses]?.objectValue {
            return .success(.init(componentID: componentID, type: type, responses: responsesObject))
        }

        if payload.keys.contains(where: { Self.stepCompleteReservedPayloadKeys.contains($0) }) {
            return .failure(.invalidResponses)
        }

        return .success(.init(componentID: componentID, type: type, responses: payload))
    }

    private static func errorMessage(from envelope: WebViewEnvelope.Parsed) -> String? {
        if let payloadError = envelope.payload?[WebViewEnvelope.Field.error]?.stringValue {
            return payloadError
        }
        return envelope.error
    }

    private static func dictionary(from body: Any) -> [String: Any]? {
        if let dictionary = body as? [String: Any] {
            return dictionary
        }

        if let jsonString = body as? String,
           let data = jsonString.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return object
        }

        return nil
    }

}

#endif
