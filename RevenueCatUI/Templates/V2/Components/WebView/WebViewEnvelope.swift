//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewEnvelope.swift

import Foundation

#if !os(tvOS) // For Paywalls V2

/// Wire-format envelopes for the `workflow-web-components-sdk` transport layer.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewEnvelope {

    static let channel = "rc-web-components"
    static let messageHandlerName = "rcWebComponents"
    static let receiveFunction = "__rcWebComponentsReceive"
    static let defaultProtocolVersion = 1

    static let kindConnect = "connect"
    static let kindInit = "init"
    static let kindReject = "reject"
    static let kindMessage = "message"
    static let kindRequest = "request"
    static let kindResponse = "response"
    static let kindError = "error"

    private static let envelopeKinds: Set<String> = [
        kindConnect, kindInit, kindReject, kindMessage, kindRequest, kindResponse, kindError
    ]

    enum Field {
        static let channel = "channel"
        static let protocolVersion = "protocol_version"
        static let kind = "kind"
        static let componentID = "component_id"
        static let type = "type"
        static let id = "id"
        static let payload = "payload"
        static let error = "error"
        static let responses = "responses"
        static let variables = "variables"
    }

    struct Parsed: Equatable {
        let kind: String
        let protocolVersion: Int
        let componentID: String
        let type: String?
        let id: String?
        let payload: [String: PaywallWebViewValue]?
        let error: String?
    }

    static func parse(_ dictionary: [String: Any]) -> Parsed? {
        guard dictionary[Field.channel] as? String == Self.channel else {
            return nil
        }

        guard let protocolVersionNumber = dictionary[Field.protocolVersion] as? NSNumber,
              protocolVersionNumber.doubleValue.isFinite else {
            return nil
        }
        let protocolVersion = protocolVersionNumber.intValue

        guard let kind = dictionary[Field.kind] as? String,
              Self.envelopeKinds.contains(kind) else {
            return nil
        }

        guard let componentID = dictionary[Field.componentID] as? String else {
            return nil
        }

        if dictionary.keys.contains(Field.type),
           dictionary[Field.type] as? String == nil {
            return nil
        }
        let type = dictionary[Field.type] as? String

        if dictionary.keys.contains(Field.id),
           dictionary[Field.id] as? String == nil {
            return nil
        }
        let id = dictionary[Field.id] as? String

        if dictionary.keys.contains(Field.error),
           dictionary[Field.error] as? String == nil {
            return nil
        }
        let error = dictionary[Field.error] as? String

        let payload: [String: PaywallWebViewValue]?
        if let rawPayload = dictionary[Field.payload] {
            guard let object = rawPayload as? [String: Any],
                  let converted = Self.convert(object: object) else {
                return nil
            }
            payload = converted
        } else {
            payload = nil
        }

        return Parsed(
            kind: kind,
            protocolVersion: protocolVersion,
            componentID: componentID,
            type: type,
            id: id,
            payload: payload,
            error: error
        )
    }

    static func build(
        kind: String,
        protocolVersion: Int,
        componentID: String,
        type: String? = nil,
        id: String? = nil,
        payload: [String: PaywallWebViewValue]? = nil,
        error: String? = nil
    ) -> [String: PaywallWebViewValue] {
        var envelope: [String: PaywallWebViewValue] = [
            Field.channel: .string(Self.channel),
            Field.protocolVersion: .number(Double(protocolVersion)),
            Field.kind: .string(kind),
            Field.componentID: .string(componentID)
        ]

        if let type {
            envelope[Field.type] = .string(type)
        }
        if let id {
            envelope[Field.id] = .string(id)
        }
        if let payload {
            envelope[Field.payload] = .object(payload)
        }
        if let error {
            envelope[Field.error] = .string(error)
        }

        return envelope
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
