//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEvent.swift
//
//  Created by Cesar de la Vega on 21/10/24.

import Foundation

// swiftlint:disable file_length missing_docs function_body_length

enum CustomerCenterEventDiscriminator: String {

    // Stored alongside events so older payloads and the EventsRequest builder
    // can decide which encoder to use without re-decoding the full event data.
    case lifecycle = "lifecycle"
    case answerSubmitted = "answer_submitted"

}

/// An event to be sent by the `RevenueCatUI` SDK.
@_spi(Internal) public enum CustomerCenterEvent: FeatureEvent, Codable, Sendable, Equatable {

    case impression(id: UUID, date: Date, ImpressionPayload)
    case answerSubmitted(id: UUID, date: Date, AnswerPayload)

    // MARK: - Factory Methods

    @_spi(Internal) public static func impression(
        id: UUID = UUID(),
        date: Date = Date(),
        locale: Locale,
        darkMode: Bool,
        isSandbox: Bool,
        displayMode: CustomerCenterPresentationMode
    ) -> CustomerCenterEvent {
        return .impression(
            id: id,
            date: date,
            ImpressionPayload(
                locale: locale,
                darkMode: darkMode,
                isSandbox: isSandbox,
                displayMode: displayMode
            )
        )
    }

    // swiftlint:disable:next function_parameter_count
    @_spi(Internal) public static func answerSubmitted(
        id: UUID = UUID(),
        date: Date = Date(),
        locale: Locale,
        darkMode: Bool,
        isSandbox: Bool,
        displayMode: CustomerCenterPresentationMode,
        path: CustomerCenterConfigData.HelpPath.PathType,
        url: URL?,
        surveyOptionID: String,
        additionalContext: String?,
        revisionID: Int
    ) -> CustomerCenterEvent {
        return .answerSubmitted(
            id: id,
            date: date,
            AnswerPayload(
                locale: locale,
                darkMode: darkMode,
                isSandbox: isSandbox,
                displayMode: displayMode,
                path: path,
                url: url,
                surveyOptionID: surveyOptionID,
                additionalContext: additionalContext,
                revisionID: revisionID
            )
        )
    }

    // MARK: - Properties

    var id: UUID {
        switch self {
        case .impression(let id, _, _): return id
        case .answerSubmitted(let id, _, _): return id
        }
    }

    var date: Date {
        switch self {
        case .impression(_, let date, _): return date
        case .answerSubmitted(_, let date, _): return date
        }
    }

    var locale: Locale {
        switch self {
        case .impression(_, _, let payload): return payload.locale
        case .answerSubmitted(_, _, let payload): return payload.locale
        }
    }

    var darkMode: Bool {
        switch self {
        case .impression(_, _, let payload): return payload.darkMode
        case .answerSubmitted(_, _, let payload): return payload.darkMode
        }
    }

    var isSandbox: Bool {
        switch self {
        case .impression(_, _, let payload): return payload.isSandbox
        case .answerSubmitted(_, _, let payload): return payload.isSandbox
        }
    }

    var displayMode: CustomerCenterPresentationMode {
        switch self {
        case .impression(_, _, let payload): return payload.displayMode
        case .answerSubmitted(_, _, let payload): return payload.displayMode
        }
    }

    @_spi(Internal) var feature: Feature { .customerCenter }

    @_spi(Internal) public var eventDiscriminator: String? {
        switch self {
        case .impression: return CustomerCenterEventDiscriminator.lifecycle.rawValue
        case .answerSubmitted: return CustomerCenterEventDiscriminator.answerSubmitted.rawValue
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case type
        case localeIdentifier
        case darkMode
        case isSandbox
        case displayMode
        case path
        case url
        case surveyOptionID = "surveyOptionId"
        case additionalContext
        case revisionID = "revisionId"
    }

    private enum EventType: String, Codable {
        case impression
        case answerSubmitted
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case impression
        case answerSubmitted
    }

    public init(from decoder: Decoder) throws {
        // Try new format first
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.allKeys.contains(.type) {
            let id = try container.decode(UUID.self, forKey: .id)
            let date = try container.decode(Date.self, forKey: .date)
            let type = try container.decode(EventType.self, forKey: .type)

            let localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
            let locale = Locale(identifier: localeIdentifier)
            let darkMode = try container.decode(Bool.self, forKey: .darkMode)
            let isSandbox = try container.decode(Bool.self, forKey: .isSandbox)
            let displayMode = try container.decode(CustomerCenterPresentationMode.self, forKey: .displayMode)

            switch type {
            case .impression:
                self = .impression(
                    id: id,
                    date: date,
                    ImpressionPayload(
                        locale: locale,
                        darkMode: darkMode,
                        isSandbox: isSandbox,
                        displayMode: displayMode
                    )
                )
            case .answerSubmitted:
                let pathRaw = try container.decode(String.self, forKey: .path)
                guard let path = CustomerCenterConfigData.HelpPath.PathType(rawValue: pathRaw) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .path,
                        in: container,
                        debugDescription: "Invalid path type: \(pathRaw)"
                    )
                }
                let url = try container.decodeIfPresent(URL.self, forKey: .url)
                let surveyOptionID = try container.decode(String.self, forKey: .surveyOptionID)
                let additionalContext = try container.decodeIfPresent(String.self, forKey: .additionalContext)
                let revisionID = try container.decode(Int.self, forKey: .revisionID)

                self = .answerSubmitted(
                    id: id,
                    date: date,
                    AnswerPayload(
                        locale: locale,
                        darkMode: darkMode,
                        isSandbox: isSandbox,
                        displayMode: displayMode,
                        path: path,
                        url: url,
                        surveyOptionID: surveyOptionID,
                        additionalContext: additionalContext,
                        revisionID: revisionID
                    )
                )
            }
            return
        }

        // Try legacy format
        let container = try decoder.container(keyedBy: LegacyCodingKeys.self)

        if container.allKeys.contains(.impression) {
            var nested = try container.nestedUnkeyedContainer(forKey: .impression)
            let id = try nested.decode(UUID.self)
            let date = try nested.decode(Date.self)
            let payload = try nested.decode(ImpressionPayload.self)
            self = .impression(id: id, date: date, payload)
        } else if container.allKeys.contains(.answerSubmitted) {
            var nested = try container.nestedUnkeyedContainer(forKey: .answerSubmitted)
            let id = try nested.decode(UUID.self)
            let date = try nested.decode(Date.self)
            let payload = try nested.decode(AnswerPayload.self)
            self = .answerSubmitted(id: id, date: date, payload)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: container.codingPath,
                      debugDescription: "Unknown CustomerCenterEvent format.")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.date, forKey: .date)

        switch self {
        case .impression(_, _, let payload):
            try container.encode(EventType.impression, forKey: .type)
            try container.encode(payload.locale.identifier, forKey: .localeIdentifier)
            try container.encode(payload.darkMode, forKey: .darkMode)
            try container.encode(payload.isSandbox, forKey: .isSandbox)
            try container.encode(payload.displayMode, forKey: .displayMode)

        case .answerSubmitted(_, _, let payload):
            try container.encode(EventType.answerSubmitted, forKey: .type)
            try container.encode(payload.locale.identifier, forKey: .localeIdentifier)
            try container.encode(payload.darkMode, forKey: .darkMode)
            try container.encode(payload.isSandbox, forKey: .isSandbox)
            try container.encode(payload.displayMode, forKey: .displayMode)
            try container.encode(payload.path.rawValue, forKey: .path)
            try container.encodeIfPresent(payload.url, forKey: .url)
            try container.encode(payload.surveyOptionID, forKey: .surveyOptionID)
            try container.encodeIfPresent(payload.additionalContext, forKey: .additionalContext)
            try container.encode(payload.revisionID, forKey: .revisionID)
        }
    }

}

// MARK: - Payloads

extension CustomerCenterEvent {

    /// The content of an impression event.
    public struct ImpressionPayload: Equatable, Codable, Sendable {

        public let locale: Locale
        public let darkMode: Bool
        public let isSandbox: Bool
        public let displayMode: CustomerCenterPresentationMode

        public init(
            locale: Locale,
            darkMode: Bool,
            isSandbox: Bool,
            displayMode: CustomerCenterPresentationMode
        ) {
            self.locale = locale
            self.darkMode = darkMode
            self.isSandbox = isSandbox
            self.displayMode = displayMode
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
            self.locale = Locale(identifier: localeIdentifier)
            self.darkMode = try container.decode(Bool.self, forKey: .darkMode)
            self.isSandbox = try container.decode(Bool.self, forKey: .isSandbox)
            self.displayMode = try container.decode(CustomerCenterPresentationMode.self, forKey: .displayMode)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.locale.identifier, forKey: .localeIdentifier)
            try container.encode(self.darkMode, forKey: .darkMode)
            try container.encode(self.isSandbox, forKey: .isSandbox)
            try container.encode(self.displayMode, forKey: .displayMode)
        }

    }
}

extension CustomerCenterEvent.ImpressionPayload {
    enum CodingKeys: String, CodingKey {
        case localeIdentifier
        case darkMode
        case isSandbox
        case displayMode
    }
}

extension CustomerCenterEvent {

    /// The content of an answer submitted event.
    public struct AnswerPayload: Equatable, Codable, Sendable {

        public let locale: Locale
        public let darkMode: Bool
        public let isSandbox: Bool
        public let displayMode: CustomerCenterPresentationMode
        public let path: CustomerCenterConfigData.HelpPath.PathType
        public let url: URL?
        public let surveyOptionID: String
        public let additionalContext: String?
        public let revisionID: Int

        public init(
            locale: Locale,
            darkMode: Bool,
            isSandbox: Bool,
            displayMode: CustomerCenterPresentationMode,
            path: CustomerCenterConfigData.HelpPath.PathType,
            url: URL?,
            surveyOptionID: String,
            additionalContext: String?,
            revisionID: Int
        ) {
            self.locale = locale
            self.darkMode = darkMode
            self.isSandbox = isSandbox
            self.displayMode = displayMode
            self.path = path
            self.url = url
            self.surveyOptionID = surveyOptionID
            self.additionalContext = additionalContext
            self.revisionID = revisionID
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
            self.locale = Locale(identifier: localeIdentifier)
            self.darkMode = try container.decode(Bool.self, forKey: .darkMode)
            self.isSandbox = try container.decode(Bool.self, forKey: .isSandbox)
            self.displayMode = try container.decode(CustomerCenterPresentationMode.self, forKey: .displayMode)
            let pathRaw = try container.decode(String.self, forKey: .path)
            guard let path = CustomerCenterConfigData.HelpPath.PathType(rawValue: pathRaw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .path,
                    in: container,
                    debugDescription: "Invalid path type: \(pathRaw)"
                )
            }
            self.path = path
            self.url = try container.decodeIfPresent(URL.self, forKey: .url)
            self.surveyOptionID = try container.decode(String.self, forKey: .surveyOptionID)
            self.additionalContext = try container.decodeIfPresent(String.self, forKey: .additionalContext)
            self.revisionID = try container.decode(Int.self, forKey: .revisionID)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.locale.identifier, forKey: .localeIdentifier)
            try container.encode(self.darkMode, forKey: .darkMode)
            try container.encode(self.isSandbox, forKey: .isSandbox)
            try container.encode(self.displayMode, forKey: .displayMode)
            try container.encode(self.path.rawValue, forKey: .path)
            try container.encodeIfPresent(self.url, forKey: .url)
            try container.encode(self.surveyOptionID, forKey: .surveyOptionID)
            try container.encodeIfPresent(self.additionalContext, forKey: .additionalContext)
            try container.encode(self.revisionID, forKey: .revisionID)
        }

    }

}

extension CustomerCenterEvent.AnswerPayload {

    enum CodingKeys: String, CodingKey {
        case localeIdentifier
        case darkMode
        case isSandbox
        case displayMode
        case path
        case url
        case surveyOptionID = "surveyOptionId"
        case additionalContext
        case revisionID = "revisionId"
    }
}
