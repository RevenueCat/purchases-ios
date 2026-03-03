//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallImpressionEvent.swift
//
//  Created by Rick van der Linden.

import Foundation

/// An event tracked when a custom paywall is shown.
struct CustomPaywallImpressionEvent: FeatureEvent {

    var feature: Feature { .customPaywallImpression }

    var eventDiscriminator: String? { nil }

    var creationData: CreationData
    var data: Data

    init(creationData: CreationData = .init(), data: Data) {
        self.creationData = creationData
        self.data = data
    }

}

extension CustomPaywallImpressionEvent {

    /// The creation data of a ``CustomPaywallImpressionEvent``.
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

    /// The content of a ``CustomPaywallImpressionEvent``.
    struct Data {

        var paywallId: String?

        init(paywallId: String?) {
            self.paywallId = paywallId
        }

    }

}

// MARK: -

extension CustomPaywallImpressionEvent.CreationData: Equatable, Codable, Sendable {}
extension CustomPaywallImpressionEvent.Data: Equatable, Codable, Sendable {}
extension CustomPaywallImpressionEvent: Equatable, Codable, Sendable {}

// MARK: - Params

/// Parameters for tracking a custom paywall impression.
struct CustomPaywallImpressionParams {

    /// An optional identifier for the custom paywall being shown.
    let paywallId: String?

    init(paywallId: String? = nil) {
        self.paywallId = paywallId
    }

}

extension CustomPaywallImpressionParams: Sendable {}
