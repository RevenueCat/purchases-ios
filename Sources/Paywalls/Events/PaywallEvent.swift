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
public enum PaywallEvent: FeatureEvent {

    // swiftlint:disable type_name

    /// An identifier that represents a paywall event.
    public typealias ID = UUID

    // swiftlint:enable type_name

    /// An identifier that represents a paywall session.
    public typealias SessionID = UUID

    var feature: Feature {
        return .paywalls
    }

    var eventDiscriminator: String? {
        return nil
    }

    /// A `PaywallView` was displayed.
    case impression(CreationData, Data)

    /// A purchase was cancelled.
    case cancel(CreationData, Data)

    /// A `PaywallView` was closed.
    case close(CreationData, Data)

}

extension PaywallEvent {

    /// The creation data of a ``PaywallEvent``.
    public struct CreationData {

        // swiftlint:disable missing_docs
        public var id: ID
        public var date: Date

        public init(
            id: ID = .init(),
            date: Date = .init()
        ) {
            self.id = id
            self.date = date
        }
        // swiftlint:enable missing_docs

    }

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

        #if !os(macOS) && !os(tvOS) // For Paywalls V2
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public init(
            offering: Offering,
            paywallComponentsData: PaywallComponentsData,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            locale: Locale,
            darkMode: Bool
        ) {
            self.init(
                offeringIdentifier: offering.identifier,
                paywallRevision: paywallComponentsData.revision,
                sessionID: sessionID,
                displayMode: displayMode,
                localeIdentifier: locale.identifier,
                darkMode: darkMode
            )
        }
        #endif

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
                darkMode: darkMode
            )
        }
        // swiftlint:enable missing_docs

        init(
            offeringIdentifier: String,
            paywallRevision: Int,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            localeIdentifier: String,
            darkMode: Bool
        ) {
            self.offeringIdentifier = offeringIdentifier
            self.paywallRevision = paywallRevision
            self.sessionIdentifier = sessionID
            self.displayMode = displayMode
            self.localeIdentifier = localeIdentifier
            self.darkMode = darkMode
        }

    }

}

extension PaywallEvent {

    /// - Returns: the underlying ``PaywallEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        case let .cancel(creationData, _): return creationData
        case let .close(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``PaywallEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .impression(_, data): return data
        case let .cancel(_, data): return data
        case let .close(_, data): return data
        }
    }

}

// MARK: - 

extension PaywallEvent.CreationData: Equatable, Codable, Sendable {}
extension PaywallEvent.Data: Equatable, Codable, Sendable {}
extension PaywallEvent: Equatable, Codable, Sendable {}
