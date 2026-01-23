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

/// The type of exit offer shown.
public enum ExitOfferType: String, Codable, Sendable {

    /// An exit offer shown when the user attempts to dismiss the paywall without interacting.
    case dismiss

}

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

    /// `purchaseInitiated` and `purchaseError` events are only used locally for attribution for now.
    /// They should not be sent to the backend until the backend supports them.
    var shouldStoreEvent: Bool {
        switch self {
        case .purchaseInitiated, .purchaseError:
            return false
        case .impression, .cancel, .close, .exitOffer:
            return true
        }
    }

    /// A `PaywallView` was displayed.
    case impression(CreationData, Data)

    /// A purchase was cancelled.
    case cancel(CreationData, Data)

    /// A `PaywallView` was closed.
    case close(CreationData, Data)

    /// An exit offer is shown to the user.
    case exitOffer(CreationData, Data, ExitOfferData)

    /// A purchase was initiated from the paywall.
    case purchaseInitiated(CreationData, Data)

    /// A purchase from the paywall failed with an error.
    case purchaseError(CreationData, Data)

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

        public var paywallIdentifier: String?
        public var offeringIdentifier: String
        public var paywallRevision: Int
        public var sessionIdentifier: SessionID
        public var displayMode: PaywallViewMode
        public var localeIdentifier: String
        public var darkMode: Bool
        var packageId: String?
        var productId: String?
        var errorCode: Int?
        var errorMessage: String?

        #if !os(tvOS) // For Paywalls V2
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
                paywallIdentifier: paywallComponentsData.id,
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
                paywallIdentifier: paywall.id,
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
            paywallIdentifier: String?,
            offeringIdentifier: String,
            paywallRevision: Int,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            localeIdentifier: String,
            darkMode: Bool,
            packageId: String? = nil,
            productId: String? = nil,
            errorCode: Int? = nil,
            errorMessage: String? = nil
        ) {
            self.paywallIdentifier = paywallIdentifier
            self.offeringIdentifier = offeringIdentifier
            self.paywallRevision = paywallRevision
            self.sessionIdentifier = sessionID
            self.displayMode = displayMode
            self.localeIdentifier = localeIdentifier
            self.darkMode = darkMode
            self.packageId = packageId
            self.productId = productId
            self.errorCode = errorCode
            self.errorMessage = errorMessage
        }

    }

}

extension PaywallEvent {

    /// The data specific to an exit offer event.
    public struct ExitOfferData {

        // swiftlint:disable missing_docs
        public var exitOfferType: ExitOfferType
        public var exitOfferingIdentifier: String

        public init(
            exitOfferType: ExitOfferType,
            exitOfferingIdentifier: String
        ) {
            self.exitOfferType = exitOfferType
            self.exitOfferingIdentifier = exitOfferingIdentifier
        }
        // swiftlint:enable missing_docs

    }

}

extension PaywallEvent {

    /// - Returns: the underlying ``PaywallEvent/CreationData-swift.struct`` for this event.
    public var creationData: CreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        case let .cancel(creationData, _): return creationData
        case let .close(creationData, _): return creationData
        case let .exitOffer(creationData, _, _): return creationData
        case let .purchaseInitiated(creationData, _): return creationData
        case let .purchaseError(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ``PaywallEvent/Data-swift.struct`` for this event.
    public var data: Data {
        switch self {
        case let .impression(_, data): return data
        case let .cancel(_, data): return data
        case let .close(_, data): return data
        case let .exitOffer(_, data, _): return data
        case let .purchaseInitiated(_, data): return data
        case let .purchaseError(_, data): return data
        }
    }

    /// - Returns: the underlying ``PaywallEvent/ExitOfferData-swift.struct`` for exit offer events, nil otherwise.
    public var exitOfferData: ExitOfferData? {
        switch self {
        case .impression, .cancel, .close, .purchaseInitiated, .purchaseError: return nil
        case let .exitOffer(_, _, exitOfferData): return exitOfferData
        }
    }

}

// MARK: -

extension PaywallEvent.Data {

    /// Creates a copy of this data with purchase-related information.
    @_spi(Internal)
    public func withPurchaseInfo(
        packageId: String?,
        productId: String?,
        errorCode: Int?,
        errorMessage: String?
    ) -> PaywallEvent.Data {
        return PaywallEvent.Data(
            offeringIdentifier: self.offeringIdentifier,
            paywallRevision: self.paywallRevision,
            sessionID: self.sessionIdentifier,
            displayMode: self.displayMode,
            localeIdentifier: self.localeIdentifier,
            darkMode: self.darkMode,
            packageId: packageId,
            productId: productId,
            errorCode: errorCode,
            errorMessage: errorMessage
        )
    }

}

extension PaywallEvent.CreationData: Equatable, Codable, Sendable {}
extension PaywallEvent.Data: Equatable, Codable, Sendable {}
extension PaywallEvent.ExitOfferData: Equatable, Codable, Sendable {}
extension PaywallEvent: Equatable, Codable, Sendable {}
