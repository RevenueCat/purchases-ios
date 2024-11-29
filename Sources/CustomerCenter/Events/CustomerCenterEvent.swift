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

    var creationData: CustomerCenterEvent.CreationData { get }
    var data: EventData { get }

}

extension CustomerCenterEvent: CustomerCenterEventType {
    public typealias EventData = Data
}
extension CustomerCenterSurveyOptionChosenEvent: CustomerCenterEventType {
    public typealias EventData = Data
}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterEvent: FeatureEvent {

    // swiftlint:disable type_name

    var feature: Feature {
        return .customerCenter
    }

    var eventDiscriminator: String? {
        switch self {
        case .impression: return "impression"
        }
    }

    /// The Customer Center was displayed.
    case impression(CreationData, Data)

}

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterSurveyOptionChosenEvent: FeatureEvent {

    // swiftlint:disable type_name

    var feature: Feature {
        return .customerCenter
    }

    var eventDiscriminator: String? {
        switch self {
        case .surveyOptionChosen: return "survey_option_chosen"
        }
    }

    /// A feedback survey was completed with a particular option.
    case surveyOptionChosen(CreationData, Data)

}

extension CustomerCenterEvent {

    /// The creation data of a ``CustomerCenterEvent``.
    public struct CreationData {

        // swiftlint:disable missing_docs
        public var id: ID
        public var date: Date

        public init(
            id: ID = .init(),
            date: Date = .init()
        ) {
            self.id = id
            self.date = date
        }

    }

    /// The content of a ``CustomerCenterEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
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
        // swiftlint:enable missing_docs

    }

}

extension CustomerCenterSurveyOptionChosenEvent {

    public typealias CreationData = CustomerCenterEvent.CreationData

    public struct Data {

        public var localeIdentifier: String
        public var darkMode: Bool
        public var isSandbox: Bool
        public var displayMode: CustomerCenterPresentationMode
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
            self.localeIdentifier = locale.identifier
            self.darkMode = darkMode
            self.isSandbox = isSandbox
            self.displayMode = displayMode
            self.pathID = pathID
            self.surveyOptionID = surveyOptionID
            self.surveyOptionTitleKey = surveyOptionTitleKey
            self.additionalContext = additionalContext
            self.revisionID = revisionID
        }

    }

}

extension CustomerCenterEvent {

    /// - Returns: the underlying ``CustomerCenterEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
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

    /// - Returns: the underlying ``CustomerCenterSurveyOptionChosenEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
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

extension CustomerCenterEvent.CreationData: Equatable, Codable, Sendable {}
extension CustomerCenterEvent.Data: Equatable, Codable, Sendable {}
extension CustomerCenterEvent: Equatable, Codable, Sendable {}

extension CustomerCenterSurveyOptionChosenEvent.Data: Equatable, Codable, Sendable {

    private enum CodingKeys: String, CodingKey {

        case localeIdentifier = "localeIdentifier"
        case darkMode = "darkMode"
        case isSandbox = "isSandbox"
        case displayMode = "displayMode"
        case pathID = "pathId"
        case surveyOptionID = "surveyOptionId"
        case surveyOptionTitleKey = "surveyOptionTitleKey"
        case additionalContext = "additionalContext"
        case revisionID = "revisionId"

    }

}
extension CustomerCenterSurveyOptionChosenEvent: Equatable, Codable, Sendable {}
