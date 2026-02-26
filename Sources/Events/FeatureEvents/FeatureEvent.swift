//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEvent.swift
//
//  Created by Cesar de la Vega on 6/11/24.

protocol FeatureEvent: Encodable, Sendable {

    var feature: Feature { get }
    var eventDiscriminator: String? { get }

    /// Whether this event should be stored and sent to the backend.
    /// WIP: Some PaywallEvents are not yet supported by the backend.
    /// We should implement support for these events in the backend first
    /// and then we can remove this `shouldStoreEvent` (as it will be always `true`)
    var shouldStoreEvent: Bool { get }

}

extension FeatureEvent {

    /// By default, all events should be stored.
    var shouldStoreEvent: Bool { true }

}

// MARK: - Dictionary Mapping

extension FeatureEvent {

    /// Converts this event into a dictionary suitable for hybrid SDK consumption.
    func toMap() -> [String: Any] {
        switch self {
        case let event as PaywallEvent:
            return event.paywallMap()
        case let event as CustomerCenterEvent:
            return event.customerCenterImpressionMap()
        case let event as CustomerCenterAnswerSubmittedEvent:
            return event.customerCenterAnswerSubmittedMap()
        default:
            return [
                "discriminator": "unknown",
                "type": "unknown",
                "class_name": String(describing: type(of: self))
            ]
        }
    }

}

private extension PaywallEvent {

    func paywallMap() -> [String: Any] {
        let typeName: String = {
            switch self {
            case .impression: return "paywall_impression"
            case .cancel: return "paywall_cancel"
            case .close: return "paywall_close"
            case .exitOffer: return "paywall_exit_offer"
            case .purchaseInitiated: return "paywall_purchase_initiated"
            case .purchaseError: return "paywall_purchase_error"
            }
        }()

        return [
            "discriminator": "paywalls",
            "type": typeName,
            "id": self.creationData.id.uuidString,
            "timestamp": self.creationData.date.millisecondsSince1970,
            "offering_id": self.data.offeringIdentifier,
            "paywall_revision": self.data.paywallRevision,
            "session_id": self.data.sessionIdentifier.uuidString,
            "display_mode": self.data.displayMode.identifier,
            "locale": self.data.localeIdentifier,
            "dark_mode": self.data.darkMode
        ]
    }

}

private extension CustomerCenterEvent {

    func customerCenterImpressionMap() -> [String: Any] {
        return [
            "discriminator": "customer_center",
            "type": "customer_center_impression",
            "id": self.creationData.id.uuidString,
            "timestamp": self.creationData.date.millisecondsSince1970,
            "dark_mode": self.data.darkMode,
            "locale": self.data.localeIdentifier,
            "display_mode": self.data.displayMode.identifier
        ]
    }

}

private extension CustomerCenterAnswerSubmittedEvent {

    func customerCenterAnswerSubmittedMap() -> [String: Any] {
        var result: [String: Any] = [
            "discriminator": "customer_center",
            "type": "customer_center_survey_option_chosen",
            "id": self.creationData.id.uuidString,
            "timestamp": self.creationData.date.millisecondsSince1970,
            "dark_mode": self.data.darkMode,
            "locale": self.data.localeIdentifier,
            "display_mode": self.data.displayMode.identifier,
            "survey_option_id": self.data.surveyOptionID,
            "path": self.data.path.rawValue,
            "revision_id": self.data.revisionID
        ]

        if let url = self.data.url {
            result["url"] = url.absoluteString
        }

        return result
    }

}
