//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEvent.swift
//
//  Created by Cesar de la Vega on 21/10/24.

import Foundation

/// An event to be sent by the `RevenueCatUI` SDK.
public enum CustomerCenterEvent {

    // swiftlint:disable type_name

    /// An identifier that represents a paywall event.
    public typealias ID = UUID

    // swiftlint:enable type_name

    /// An identifier that represents a paywall session.
    public typealias SessionID = UUID

    /// A `PaywallView` was displayed.
    case impression(CreationData, Data)

}

extension CustomerCenterEvent {

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

    }

}

extension CustomerCenterEvent {

    /// The content of a ``PaywallEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var sessionIdentifier: SessionID

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public init(
            sessionID: SessionID
        ) {
            self.sessionIdentifier = sessionID
        }
        // swiftlint:enable missing_docs

    }

}

extension CustomerCenterEvent {

    /// - Returns: the underlying ``PaywallEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``PaywallEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .impression(_, data): return data
        }
    }

}

extension CustomerCenterEvent.CreationData: Equatable, Codable, Sendable {}
extension CustomerCenterEvent.Data: Equatable, Codable, Sendable {}
extension CustomerCenterEvent: Equatable, Codable, Sendable {}
