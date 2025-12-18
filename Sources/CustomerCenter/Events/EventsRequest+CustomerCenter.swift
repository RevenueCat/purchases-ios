//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Untitled.swift
//
//  Created by Cesar de la Vega on 21/10/24.

import Foundation

extension EventsRequest {

    struct TypeContainer: Decodable {

        let type: String

    }

    enum CustomerCenterEventType: String {

        case impression = "customer_center_impression"
        case answerSubmitted = "customer_center_survey_option_chosen"

    }

    class CustomerCenterEventBaseRequest {

        let id: String?
        let version: Int
        var type: CustomerCenterEventType
        var appUserID: String
        var appSessionID: String
        var timestamp: UInt64
        var darkMode: Bool
        var locale: String
        var isSandbox: Bool
        var displayMode: CustomerCenterPresentationMode
        // We don't support revisions in the backend yet so hardcoding to 1 for now
        let revisionId: Int = 1

        init(id: String?,
             version: Int,
             type: CustomerCenterEventType,
             appUserID: String,
             appSessionID: String,
             timestamp: UInt64,
             darkMode: Bool,
             locale: String,
             isSandbox: Bool,
             displayMode: CustomerCenterPresentationMode) {
            self.id = id
            self.version = version
            self.type = type
            self.appUserID = appUserID
            self.appSessionID = appSessionID
            self.timestamp = timestamp
            self.darkMode = darkMode
            self.locale = locale
            self.isSandbox = isSandbox
            self.displayMode = displayMode
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        static func createBase(from storedEvent: StoredEvent) -> CustomerCenterEventBaseRequest? {
            guard let appSessionID = storedEvent.appSessionID else {
                Logger.error(Strings.paywalls.event_missing_app_session_id)
                return nil
            }

            guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
                Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
                return nil
            }
            guard let customerCenterEvent = try? JSONDecoder.default.decode(CustomerCenterEvent.self,
                                                                            from: jsonData) else {
                Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
                return nil
            }

            let creationData = customerCenterEvent.creationData
            let data = customerCenterEvent.data

            return CustomerCenterEventBaseRequest(
                id: creationData.id.uuidString,
                version: version,
                type: customerCenterEvent.eventType,
                appUserID: storedEvent.userID,
                appSessionID: appSessionID.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                darkMode: data.darkMode,
                locale: data.localeIdentifier,
                isSandbox: data.isSandbox,
                displayMode: data.displayMode
            )
        }

        private static let version: Int = 1
    }

    // swiftlint:disable:next type_name
    final class CustomerCenterAnswerSubmittedEventRequest {

        let id: String?
        let version: Int
        var type: CustomerCenterEventType
        var appUserID: String
        var appSessionID: String
        var timestamp: UInt64
        var darkMode: Bool
        var locale: String
        var isSandbox: Bool
        var displayMode: CustomerCenterPresentationMode
        var path: String
        var url: String?
        var surveyOptionID: String
        var additionalContext: String?
        var revisionId: Int

        init(id: String?,
             version: Int,
             appUserID: String,
             appSessionID: String,
             timestamp: UInt64,
             darkMode: Bool,
             locale: String,
             isSandbox: Bool,
             displayMode: CustomerCenterPresentationMode,
             path: CustomerCenterConfigData.HelpPath.PathType,
             url: URL?,
             surveyOptionID: String,
             additionalContext: String?,
             revisionId: Int) {
            self.id = id
            self.version = version
            self.type = .answerSubmitted
            self.appUserID = appUserID
            self.appSessionID = appSessionID
            self.timestamp = timestamp
            self.darkMode = darkMode
            self.locale = locale
            self.isSandbox = isSandbox
            self.displayMode = displayMode
            self.path = path.rawValue
            self.url = url?.absoluteString
            self.surveyOptionID = surveyOptionID
            self.additionalContext = additionalContext
            self.revisionId = revisionId
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        static func create(from storedEvent: StoredEvent) -> CustomerCenterAnswerSubmittedEventRequest? {
            guard let appSessionID = storedEvent.appSessionID else {
                Logger.error(Strings.paywalls.event_missing_app_session_id)
                return nil
            }

            guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
                Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
                return nil
            }
            guard let customerCenterEvent = try? JSONDecoder.default.decode(CustomerCenterAnswerSubmittedEvent.self,
                                                                            from: jsonData) else {
                Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
                return nil
            }

            let creationData = customerCenterEvent.creationData
            let data = customerCenterEvent.data

            return CustomerCenterAnswerSubmittedEventRequest(
                id: creationData.id.uuidString,
                version: version,
                appUserID: storedEvent.userID,
                appSessionID: appSessionID.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                darkMode: data.darkMode,
                locale: data.localeIdentifier,
                isSandbox: data.isSandbox,
                displayMode: data.displayMode,
                path: data.path,
                url: data.url,
                surveyOptionID: data.surveyOptionID,
                additionalContext: data.additionalContext,
                revisionId: data.revisionID
            )
        }

        private static let version: Int = 1

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterEvent {

    var eventType: EventsRequest.CustomerCenterEventType {
        switch self {
        case .impression: return .impression
        }

    }

}

// MARK: - Codable

extension EventsRequest.CustomerCenterEventType: Encodable {}
extension EventsRequest.CustomerCenterEventBaseRequest: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case appSessionID = "appSessionId"
        case timestamp
        case darkMode = "darkMode"
        case locale
        case isSandbox = "isSandbox"
        case displayMode = "displayMode"
        case revisionId = "revisionId"

    }

}

extension EventsRequest.CustomerCenterAnswerSubmittedEventRequest: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case appSessionID = "appSessionId"
        case timestamp
        case darkMode
        case locale
        case isSandbox = "isSandbox"
        case displayMode = "displayMode"
        case path
        case url
        case surveyOptionID = "surveyOptionId"
        case additionalContext = "additionalContext"
        case revisionId = "revisionId"

    }

}
