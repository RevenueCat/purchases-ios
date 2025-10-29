//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsRequest+Ad.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

extension EventsRequest {

    struct AdEventRequest {

        let id: String?
        let version: Int
        var type: AdEventRequest.EventType
        var appUserId: String
        var appSessionId: String
        var timestamp: UInt64
        var networkName: String
        var mediatorName: String
        var placement: String?
        var adUnitId: String
        var adInstanceId: String
        // For revenue events only:
        var revenueMicros: Int?
        var currency: String?
        var precision: String?

    }

}

extension EventsRequest.AdEventRequest {

    enum EventType: String {

        case displayed = "rc_ads_ad_displayed"
        case opened = "rc_ads_ad_opened"
        case revenue = "rc_ads_ad_revenue"

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredEvent) {
        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let adEvent = try JSONDecoder.default.decode(AdEvent.self, from: jsonData)
            let creationData = adEvent.creationData
            let eventData = adEvent.eventData

            guard let appSessionID = storedEvent.appSessionID else {
                Logger.error(Strings.paywalls.event_missing_app_session_id)
                return nil
            }

            self.init(
                id: creationData.id.uuidString,
                version: Self.version,
                type: adEvent.eventType,
                appUserId: storedEvent.userID,
                appSessionId: appSessionID.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                networkName: eventData.networkName,
                mediatorName: eventData.mediatorName.rawValue,
                placement: eventData.placement,
                adUnitId: eventData.adUnitId,
                adInstanceId: eventData.adInstanceId,
                revenueMicros: adEvent.revenueData?.revenueMicros,
                currency: adEvent.revenueData?.currency,
                precision: adEvent.revenueData?.precision.rawValue
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let version: Int = 1

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension AdEvent {

    var eventType: EventsRequest.AdEventRequest.EventType {
        switch self {
        case .displayed: return .displayed
        case .opened: return .opened
        case .revenue: return .revenue
        }

    }

}

// MARK: - Codable

extension EventsRequest.AdEventRequest.EventType: Encodable {}
extension EventsRequest.AdEventRequest: Encodable {

    /// When sending this to the backend `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase` is used
    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserId
        case appSessionId
        case timestamp = "timestampMs"
        case networkName
        case mediatorName
        case placement
        case adUnitId
        case adInstanceId
        case revenueMicros
        case currency
        case precision

    }

}

#endif
