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

/// An event to be sent by the `RevenueCatUI` SDK.
public enum PaywallEvent {

    // swiftlint:disable:next type_name

    /// An identifier that represents a paywall event.
    public typealias ID = UUID

    /// An identifier that represents a paywall session.
    public typealias SessionID = UUID

    /// A `PaywallView` was displayed.
    case impression(Data)

    /// A purchase was cancelled.
    case cancel(Data)

    /// A `PaywallView` was closed.
    case close(Data)

}

extension PaywallEvent {

    /// The content of a ``PaywallEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var id: ID
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
                id: .init(),
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
            id: ID,
            offeringIdentifier: String,
            paywallRevision: Int,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            localeIdentifier: String,
            darkMode: Bool,
            date: Date
        ) {
            self.id = id
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

extension PaywallEvent {

    /// - Returns: the underlying ``PaywallEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .impression(data): return data
        case let .cancel(data): return data
        case let .close(data): return data
        }
    }

}

// MARK: - 

extension PaywallEvent.Data: Equatable, Codable, Sendable {}
extension PaywallEvent: Equatable, Codable, Sendable {}
