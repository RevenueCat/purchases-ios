//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureFeatureEventsRequest+Paywall.swift
//
//  Created by Cesar de la Vega on 24/10/24.

import Foundation

extension FeatureEventsRequest {

    struct PaywallEvent {

        let id: String?
        let version: Int
        var type: EventType
        var appUserID: String
        var sessionID: String
        var offeringID: String
        var paywallRevision: Int
        var timestamp: UInt64
        var displayMode: PaywallViewMode
        var darkMode: Bool
        var localeIdentifier: String
        var exitOfferType: ExitOfferType?
        var exitOfferingID: String?
        var packageId: String?
        var productId: String?
        var errorCode: Int?
        var errorMessage: String?

    }

}

extension FeatureEventsRequest.PaywallEvent {

    enum EventType: String {

        case impression = "paywall_impression"
        case cancel = "paywall_cancel"
        case close = "paywall_close"
        case exitOffer = "paywall_exit_offer"
        case purchaseInitiated = "paywall_purchase_initiated"
        case purchaseError = "paywall_purchase_error"

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredFeatureEvent) {
        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let paywallEvent = try JSONDecoder.default.decode(PaywallEvent.self, from: jsonData)
            let creationData = paywallEvent.creationData
            let data = paywallEvent.data
            let exitOfferData = paywallEvent.exitOfferData

            self.init(
                id: creationData.id.uuidString,
                version: Self.version,
                type: paywallEvent.eventType,
                appUserID: storedEvent.userID,
                sessionID: data.sessionIdentifier.uuidString,
                offeringID: data.offeringIdentifier,
                paywallRevision: data.paywallRevision,
                timestamp: creationData.date.millisecondsSince1970,
                displayMode: data.displayMode,
                darkMode: data.darkMode,
                localeIdentifier: data.localeIdentifier,
                exitOfferType: exitOfferData?.exitOfferType,
                exitOfferingID: exitOfferData?.exitOfferingIdentifier,
                packageId: data.packageId,
                productId: data.productId,
                errorCode: data.errorCode,
                errorMessage: data.errorMessage
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let version: Int = 1

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEvent {

    var eventType: FeatureEventsRequest.PaywallEvent.EventType {
        switch self {
        case .impression: return .impression
        case .cancel: return .cancel
        case .close: return .close
        case .exitOffer: return .exitOffer
        case .purchaseInitiated: return .purchaseInitiated
        case .purchaseError: return .purchaseError
        }

    }

}

// MARK: - Codable

extension FeatureEventsRequest.PaywallEvent.EventType: Encodable {}
extension FeatureEventsRequest.PaywallEvent: Encodable {

    /// When sending this to the backend `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase` is used
    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"
        case offeringID = "offeringId"
        case paywallRevision
        case timestamp
        case displayMode
        case darkMode
        case localeIdentifier = "locale"
        case exitOfferType
        case exitOfferingID = "exitOfferingId"
        case packageId = "packageId"
        case productId = "productId"
        case errorCode
        case errorMessage

    }

}
