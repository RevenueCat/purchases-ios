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

/// A protocol that represents a customer center event.
public protocol CustomerCenterEventType {}

extension CustomerCenterEventType {

    var feature: Feature { .customerCenter }

}

enum CustomerCenterEventDiscriminator: String {

    case lifecycle = "lifecycle"
    case answerSubmitted = "answer_submitted"

}

/// Data that represents a customer center event creation.
public struct CustomerCenterEventCreationData {

    let id: UUID
    let date: Date

    // swiftlint:disable:next missing_docs
    public init(
        id: UUID = .init(),
        date: Date = .init()
    ) {
        self.id = id
        self.date = date
    }

}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterEvent: FeatureEvent, CustomerCenterEventType {

    var eventDiscriminator: String? { CustomerCenterEventDiscriminator.lifecycle.rawValue }

    /// The Customer Center was displayed.
    case impression(CustomerCenterEventCreationData, Data)

}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterAnswerSubmittedEvent: FeatureEvent, CustomerCenterEventType {

    var eventDiscriminator: String? { CustomerCenterEventDiscriminator.answerSubmitted.rawValue }

    /// A feedback survey was completed with a particular option.
    case answerSubmitted(CustomerCenterEventCreationData, Data)

}

extension CustomerCenterEvent {

    /// The content of a ``CustomerCenterEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var localeIdentifier: String { base.localeIdentifier }
        public var darkMode: Bool { base.darkMode }
        public var isSandbox: Bool { base.isSandbox }
        public var displayMode: CustomerCenterPresentationMode { base.displayMode }

        private let base: CustomerCenterBaseData

        public init(
            locale: Locale,
            darkMode: Bool,
            isSandbox: Bool,
            displayMode: CustomerCenterPresentationMode
        ) {
            self.base = CustomerCenterBaseData(
                locale: locale,
                darkMode: darkMode,
                isSandbox: isSandbox,
                displayMode: displayMode
            )
        }
        // swiftlint:enable missing_docs

    }

}

extension CustomerCenterAnswerSubmittedEvent {

    /// The content of a ``CustomerCenterAnswerSubmittedEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var localeIdentifier: String { base.localeIdentifier }
        public var darkMode: Bool { base.darkMode }
        public var isSandbox: Bool { base.isSandbox }
        public var displayMode: CustomerCenterPresentationMode { base.displayMode }
        public let path: CustomerCenterConfigData.HelpPath.PathType
        public let url: URL?
        public let surveyOptionID: String
        public let additionalContext: String?
        public let revisionID: Int

        private let base: CustomerCenterBaseData

        public init(
            locale: Locale,
            darkMode: Bool,
            isSandbox: Bool,
            displayMode: CustomerCenterPresentationMode,
            path: CustomerCenterConfigData.HelpPath.PathType,
            url: URL?,
            surveyOptionID: String,
            additionalContext: String? = nil,
            revisionID: Int
        ) {
            self.base = CustomerCenterBaseData(
                locale: locale,
                darkMode: darkMode,
                isSandbox: isSandbox,
                displayMode: displayMode
            )
            self.path = path
            self.url = url
            self.surveyOptionID = surveyOptionID
            self.additionalContext = additionalContext
            self.revisionID = revisionID
        }
        // swiftlint:enable missing_docs

    }

}

extension CustomerCenterEvent {

    /// - Returns: the underlying ``CustomerCenterEventCreationData-swift.struct`` for this event.
    public var creationData: CustomerCenterEventCreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``CustomerCenterEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .impression(_, data): return data
        }
    }

}

extension CustomerCenterAnswerSubmittedEvent {

    /// - Returns: the underlying ``CustomerCenterEventCreationData-swift.struct`` for this event.
    public var creationData: CustomerCenterEventCreationData {
        switch self {
        case let .answerSubmitted(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``CustomerCenterAnswerSubmittedEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .answerSubmitted(_, surveyData): return surveyData
        }
    }

}

private struct CustomerCenterBaseData {

    // swiftlint:disable missing_docs
    public let localeIdentifier: String
    public let darkMode: Bool
    public let isSandbox: Bool
    public let displayMode: CustomerCenterPresentationMode

    public init(
        locale: Locale,
        darkMode: Bool,
        isSandbox: Bool,
        displayMode: CustomerCenterPresentationMode
    ) {
        self.localeIdentifier = locale.identifier
        self.darkMode = darkMode
        self.isSandbox = isSandbox
        self.displayMode = displayMode
    }
    // swiftlint:enable missing_docs

}

// MARK: -

extension CustomerCenterEventCreationData: Equatable, Codable, Sendable {}
extension CustomerCenterEvent.Data: Equatable, Codable, Sendable {}
extension CustomerCenterEvent: Equatable, Codable, Sendable {}

extension CustomerCenterBaseData: Equatable, Codable, Sendable {}

extension CustomerCenterAnswerSubmittedEvent.Data: Equatable, Codable, Sendable {

    // These keys are used for `StoredEvent` only
    private enum CodingKeys: String, CodingKey {

        case base
        case path
        case url
        case surveyOptionID = "surveyOptionId"
        case additionalContext = "additionalContext"
        case revisionID = "revisionId"

    }

}

extension CustomerCenterAnswerSubmittedEvent: Equatable, Codable, Sendable {}
