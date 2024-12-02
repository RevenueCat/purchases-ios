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

public protocol CustomerCenterEventType {

    /// An identifier that represents a customer center event.
    typealias ID = UUID

    // swiftlint:enable type_name

    /// An identifier that represents a paywall session.
    typealias SessionID = UUID

    associatedtype EventData

    var creationData: CustomerCenterEventCreationData { get }
    var data: EventData { get }

}

extension CustomerCenterEventType {

    var feature: Feature { .customerCenter }

}

public struct CustomerCenterEventCreationData {

    public var id: UUID
    public var date: Date

    public init(
        id: UUID = .init(),
        date: Date = .init()
    ) {
        self.id = id
        self.date = date
    }

}

public struct CustomerCenterBaseData {

    public var localeIdentifier: String
    public var darkMode: Bool
    public var isSandbox: Bool
    public var displayMode: CustomerCenterPresentationMode

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

}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterEvent: FeatureEvent, CustomerCenterEventType {

    // swiftlint:disable type_name

    var eventDiscriminator: String? { "impression" }

    /// The Customer Center was displayed.
    case impression(CustomerCenterEventCreationData, Data)

}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterSurveyOptionChosenEvent: FeatureEvent, CustomerCenterEventType {

    // swiftlint:disable type_name

    var eventDiscriminator: String? { "survey_option_chosen" }

    /// A feedback survey was completed with a particular option.
    case surveyOptionChosen(CustomerCenterEventCreationData, Data)

}

extension CustomerCenterEvent {

    /// The content of a ``CustomerCenterEvent``.
    public struct Data {

        public let base: CustomerCenterBaseData

        // swiftlint:disable missing_docs
        public var localeIdentifier: String { base.localeIdentifier }
        public var darkMode: Bool { base.darkMode }
        public var isSandbox: Bool { base.isSandbox }
        public var displayMode: CustomerCenterPresentationMode { base.displayMode }

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

extension CustomerCenterSurveyOptionChosenEvent {

    public struct Data {

        private let base: CustomerCenterBaseData
        public var localeIdentifier: String { base.localeIdentifier }
        public var darkMode: Bool { base.darkMode }
        public var isSandbox: Bool { base.isSandbox }
        public var displayMode: CustomerCenterPresentationMode { base.displayMode }
        public var pathID: String
        public var surveyOptionID: String
        public var surveyOptionTitleKey: String
        public var additionalContext: String?
        public var revisionID: Int

        public init(
            locale: Locale,
            darkMode: Bool,
            isSandbox: Bool,
            displayMode: CustomerCenterPresentationMode,
            pathID: String,
            surveyOptionID: String,
            surveyOptionTitleKey: String,
            additionalContext: String? = nil,
            revisionID: Int
        ) {
            self.base = CustomerCenterBaseData(
                locale: locale,
                darkMode: darkMode,
                isSandbox: isSandbox,
                displayMode: displayMode
            )
            self.pathID = pathID
            self.surveyOptionID = surveyOptionID
            self.surveyOptionTitleKey = surveyOptionTitleKey
            self.additionalContext = additionalContext
            self.revisionID = revisionID
        }

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

extension CustomerCenterSurveyOptionChosenEvent {

    /// - Returns: the underlying ``CustomerCenterEventCreationData-swift.struct`` for this event.
    public var creationData: CustomerCenterEventCreationData {
        switch self {
        case let .surveyOptionChosen(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``CustomerCenterSurveyOptionChosenEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .surveyOptionChosen(_, surveyData): return surveyData
        }
    }

}

// MARK: -

extension CustomerCenterEventCreationData: Equatable, Codable, Sendable {}
extension CustomerCenterEvent.Data: Equatable, Codable, Sendable {}
extension CustomerCenterEvent: Equatable, Codable, Sendable {}

extension CustomerCenterBaseData: Equatable, Codable, Sendable {

    private enum CodingKeys: String, CodingKey {

        case localeIdentifier = "localeIdentifier"
        case darkMode = "darkMode"
        case isSandbox = "isSandbox"
        case displayMode = "displayMode"
    }

}

extension CustomerCenterSurveyOptionChosenEvent.Data: Equatable, Codable, Sendable {

    private enum CodingKeys: String, CodingKey {

        case base
        case pathID = "pathId"
        case surveyOptionID = "surveyOptionId"
        case surveyOptionTitleKey = "surveyOptionTitleKey"
        case additionalContext = "additionalContext"
        case revisionID = "revisionId"

    }

}
extension CustomerCenterSurveyOptionChosenEvent: Equatable, Codable, Sendable {}
