//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallStoredEvent.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// Contains the necessary information for `PaywallEventStore`.
struct StoredFeatureEvent<T: FeatureEvent> {

    var event: T
    var userID: String

}

// MARK: - Extensions

extension StoredFeatureEvent: Equatable, Sendable {}

extension StoredFeatureEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case event
        case userID = "userId"

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol AnyStoredFeatureEventType {

    var anyEvent: any FeatureEvent { get }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StoredFeatureEvent: AnyStoredFeatureEventType {

    var anyEvent: any FeatureEvent {
        return event
    }

    func erased<ErasedType: FeatureEvent>() -> StoredFeatureEvent<ErasedType>? {
        guard let castedEvent = event as? ErasedType else { return nil }
        return StoredFeatureEvent<ErasedType>(event: castedEvent, userID: userID)
    }

}
