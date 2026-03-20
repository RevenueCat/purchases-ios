//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallEvent.swift
//
//  Created by Rick van der Linden.

import Foundation

/// An event tracked for custom paywalls.
enum CustomPaywallEvent: FeatureEvent {

    var feature: Feature { .customPaywalls }

    var eventDiscriminator: String? { nil }

    var isPriorityEvent: Bool { true }

    /// A custom paywall was shown.
    case impression(CreationData, Data)

}

extension CustomPaywallEvent {

    /// - Returns: the underlying ``CustomPaywallEvent/CreationData-swift.struct`` for this event.
    var creationData: CreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``CustomPaywallEvent/Data-swift.struct`` for this event.
    var data: Data {
        switch self {
        case let .impression(_, data): return data
        }
    }

}

extension CustomPaywallEvent {

    /// The creation data of a ``CustomPaywallEvent``.
    struct CreationData {

        var id: UUID
        var date: Date

        init(
            id: UUID = .init(),
            date: Date = .init()
        ) {
            self.id = id
            self.date = date
        }

    }

    /// The content of a ``CustomPaywallEvent``.
    struct Data {

        var paywallId: String?
        var offeringId: String?

        init(paywallId: String?, offeringId: String? = nil) {
            self.paywallId = paywallId
            self.offeringId = offeringId
        }

    }

}

// MARK: -

extension CustomPaywallEvent.CreationData: Equatable, Codable, Sendable {}
extension CustomPaywallEvent.Data: Equatable, Codable, Sendable {}
extension CustomPaywallEvent: Equatable, Codable, Sendable {}
