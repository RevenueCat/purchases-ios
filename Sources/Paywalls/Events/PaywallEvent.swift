//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEvent.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation

// TODO: API tester

/// An event to be sent by the `RevenueCatUI` SDK.
public enum PaywallEvent {

    /// An identifier that represents a paywall session.
    public typealias SessionID = UUID

    /// A `PaywallView` was displayed.
    case view(Data)

    /// A purchase was cancelled.
    case cancel(Data)

    /// A `PaywallView` was closed.
    case close(Data)

}

extension PaywallEvent {

    /// The content of a ``PaywallEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var offeringIdentifier: String
        public var paywallRevision: Int
        public var sessionIdentifier: SessionID
        public var displayMode: PaywallViewMode
        public var localeIdentifier: String
        public var darkMode: Bool
        public var date: Date

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public init(
            offering: Offering,
            paywall: PaywallData,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            locale: Locale,
            darkMode: Bool
        ) {
            self.init(
                offeringIdentifier: offering.identifier,
                paywallRevision: paywall.revision,
                sessionID: sessionID,
                displayMode: displayMode,
                localeIdentifier: locale.identifier,
                darkMode: darkMode,
                date: .now
            )
        }
        // swiftlint:enable missing_docs

        init(
            offeringIdentifier: String,
            paywallRevision: Int,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            localeIdentifier: String,
            darkMode: Bool,
            date: Date
        ) {
            self.offeringIdentifier = offeringIdentifier
            self.paywallRevision = paywallRevision
            self.sessionIdentifier = sessionID
            self.displayMode = displayMode
            self.localeIdentifier = localeIdentifier
            self.darkMode = darkMode
            self.date = date
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent {

    var data: Data {
        switch self {
        case let .view(data): return data
        case let .cancel(data): return data
        case let .close(data): return data
        }
    }

}

// MARK: - Codable

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent.Data: Equatable, Codable, Sendable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent: Equatable, Codable, Sendable {}

// With purchases:

//        "session_id": "EFWEf-WEFWEF-WEFEWF_WEFWEF",
//        "paywall_revision": 1,
//        "display_mode": "fullscreen",
//        "dark_mode": false,
//        "locale_displayed": "en-US",
//        "locale_requested": "fr-FR"

/*

 {
   "events": [
     {
        "version": 1,
        "type": "paywall_view",
        "app_user_id": "josh1",
        "session_id": "EFWEf-WEFWEF-WEFEWF_WEFWEF",
        "offering_id": "main_offer",
        "paywall_revision": 1,
        "timestamp": "1234567890",
        "display_mode": "fullscreen",
        "dark_mode": false,
        "locale": "fr-FR"
    }

  ALL THESE ARE HEADERS
       "platform": "ios",
       "platform_version": "16.4.1",
       "platform_flavor": null,
       "sdk_version": "4.26.1",
       "app_version": "1.0.0",


     },
     {
       "version": 1,
       "type": "paywall_cancel",

       "platform": "ios",
       "platform_version": "16.4.1",
       "platform_flavor": null,
       "sdk_version": "4.26.1",
       "app_version": "1.0.0",

       "app_user_id": "josh1",

       "session_id": "EFWEf-WEFWEF-WEFEWF_WEFWEF",
       "offering_id": "main_offer",
       "paywall_revision": 1,
       "timestamp": "1234567890"
     },
     {
       "version": 1,
       "type": "paywall_close",

       "platform": "ios",
       "platform_version": "16.4.1",
       "platform_flavor": null,
       "sdk_version": "4.26.1",
       "app_version": "1.0.0",

       "app_user_id": "josh1",

       "session_id": "EFWEf-WEFWEF-WEFEWF_WEFWEF",
       "offering_id": "main_offer",
       "paywall_revision": 1,
       "timestamp": "1234567890"
     }
   ]
 }

 */
