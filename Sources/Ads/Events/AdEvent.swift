//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEvent.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

/// An event to be sent for RC Ads tracking.
public enum AdEvent: FeatureEvent {

    // swiftlint:disable type_name

    /// An identifier that represents an ad event.
    public typealias ID = UUID

    // swiftlint:enable type_name

    /// An identifier that represents an ad session.
    public typealias SessionID = UUID

    var feature: Feature {
        return .ads
    }

    var eventDiscriminator: String? {
        return nil
    }

    /// An ad impression was displayed.
    case displayed(CreationData, Data)

    /// An ad was opened/clicked.
    case opened(CreationData, Data)

    /// An ad impression generated revenue.
    case revenue(CreationData, RevenueData)

}

extension AdEvent {

    /// The creation data of an ``AdEvent``.
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

extension AdEvent {

    /// The content of an ``AdEvent``.
    public struct Data {

        // swiftlint:disable missing_docs
        public var networkName: String
        public var mediatorName: String
        public var placement: String?
        public var adUnitId: String
        public var adInstanceId: String
        public var sessionIdentifier: SessionID

        public init(
            networkName: String,
            mediatorName: String,
            placement: String?,
            adUnitId: String,
            adInstanceId: String,
            sessionIdentifier: SessionID
        ) {
            self.networkName = networkName
            self.mediatorName = mediatorName
            self.placement = placement
            self.adUnitId = adUnitId
            self.adInstanceId = adInstanceId
            self.sessionIdentifier = sessionIdentifier
        }
        // swiftlint:enable missing_docs

    }

    /// The content of a revenue ``AdEvent``.
    public struct RevenueData {

        // swiftlint:disable missing_docs
        public var networkName: String
        public var mediatorName: String
        public var placement: String?
        public var adUnitId: String
        public var adInstanceId: String
        public var sessionIdentifier: SessionID
        public var revenueMicros: Int
        public var currency: String
        public var precision: Precision

        public init(
            networkName: String,
            mediatorName: String,
            placement: String?,
            adUnitId: String,
            adInstanceId: String,
            sessionIdentifier: SessionID,
            revenueMicros: Int,
            currency: String,
            precision: Precision
        ) {
            self.networkName = networkName
            self.mediatorName = mediatorName
            self.placement = placement
            self.adUnitId = adUnitId
            self.adInstanceId = adInstanceId
            self.sessionIdentifier = sessionIdentifier
            self.revenueMicros = revenueMicros
            self.currency = currency
            self.precision = precision
        }
        // swiftlint:enable missing_docs

    }

}

extension AdEvent.RevenueData {

    /// Enum representing the level of accuracy for reported revenue values.
    public enum Precision: String {

        /// Revenue value is exact and confirmed
        case exact

        /// Revenue value is defined by the publisher
        case publisherDefined = "publisher_defined"

        /// Revenue value is an estimate
        case estimated

        /// Revenue value accuracy cannot be determined
        case unknown

    }

}

extension AdEvent {

    /// - Returns: the underlying ``AdEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
        switch self {
        case let .displayed(creationData, _): return creationData
        case let .opened(creationData, _): return creationData
        case let .revenue(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``AdEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .displayed(_, data):
            return data
        case let .opened(_, data):
            return data
        case let .revenue(_, revenueData):
            return Data(
                networkName: revenueData.networkName,
                mediatorName: revenueData.mediatorName,
                placement: revenueData.placement,
                adUnitId: revenueData.adUnitId,
                adInstanceId: revenueData.adInstanceId,
                sessionIdentifier: revenueData.sessionIdentifier
            )
        }
    }

    /// - Returns: the underlying ``AdEvent/RevenueData-swift.struct`` for revenue events.
    public var revenueData: RevenueData? {
        switch self {
        case .displayed, .opened:
            return nil
        case let .revenue(_, revenueData):
            return revenueData
        }
    }

}

// MARK: -

extension AdEvent.CreationData: Equatable, Codable, Sendable {}
extension AdEvent.Data: Equatable, Codable, Sendable {}
extension AdEvent.RevenueData: Equatable, Codable, Sendable {}
extension AdEvent.RevenueData.Precision: Codable, Sendable {}
extension AdEvent: Equatable, Codable, Sendable {}
