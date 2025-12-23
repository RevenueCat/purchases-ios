//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventsRequest.swift
//
//  Created by RevenueCat on 1/21/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

/// The content of a request to the ad events endpoint.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AdEventsRequest {

    var events: [AnyEncodable]

    init(events: [AnyEncodable]) {
        self.events = events
    }

    init(events: [StoredAdEvent]) {
        self.init(events: events.compactMap { storedEvent in
            guard let event = AdEventRequest(storedEvent: storedEvent) else {
                return nil
            }
            return AnyEncodable(event)
        })
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEventsRequest: HTTPRequestBody {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEventsRequest {

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
        var impressionId: String?
        // For revenue events only:
        var revenueMicros: Int?
        var currency: String?
        var precision: String?
        // For failed to load events only:
        var mediatorErrorCode: Int?

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEventsRequest.AdEventRequest {

    enum EventType: String {

        case failedToLoad = "rc_ads_ad_failed_to_load"
        case loaded = "rc_ads_ad_loaded"
        case displayed = "rc_ads_ad_displayed"
        case opened = "rc_ads_ad_opened"
        case revenue = "rc_ads_ad_revenue"

    }

    init?(storedEvent: StoredAdEvent) {
        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let adEvent = try JSONDecoder.default.decode(AdEvent.self, from: jsonData)
            let creationData = adEvent.creationData
            let eventData = adEvent.eventData

            self.init(
                id: creationData.id.uuidString,
                version: Self.version,
                type: adEvent.eventType,
                appUserId: storedEvent.userID,
                appSessionId: storedEvent.appSessionID.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                networkName: eventData.networkName,
                mediatorName: eventData.mediatorName.rawValue,
                placement: eventData.placement,
                adUnitId: eventData.adUnitId,
                impressionId: adEvent.impressionIdentifier,
                revenueMicros: adEvent.revenueData?.revenueMicros,
                currency: adEvent.revenueData?.currency,
                precision: adEvent.revenueData?.precision.rawValue,
                mediatorErrorCode: adEvent.mediatorErrorCode
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

    var eventType: AdEventsRequest.AdEventRequest.EventType {
        switch self {
        case .failedToLoad: return .failedToLoad
        case .loaded: return .loaded
        case .displayed: return .displayed
        case .opened: return .opened
        case .revenue: return .revenue
        }

    }

}

// MARK: - Codable

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEventsRequest.AdEventRequest.EventType: Encodable {}
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEventsRequest.AdEventRequest: Encodable {

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
        case impressionId
        case revenueMicros
        case currency
        case precision
        case mediatorErrorCode

    }

}

#endif
