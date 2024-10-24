//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsRequest.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// The content of a request to the events endpoints.
struct EventsRequest {

    var events: [AnyEncodable]

    init(events: [AnyEncodable]) {
        self.events = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [PaywallStoredEvent]) {
        self.init(events: events.compactMap { storedEvent in
            switch storedEvent.feature {
            case .paywalls:
                guard let event = PaywallEvent(storedEvent: storedEvent) else {
                    return nil
                }
                return AnyEncodable(event)
            }
        })
    }

}

protocol FeatureEvent: Encodable {

    var id: String? { get }
    var version: Int { get }
    var appUserID: String { get }
    var sessionID: String { get }

}

extension EventsRequest: HTTPRequestBody {}
