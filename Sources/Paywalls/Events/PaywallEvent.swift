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

// swiftlint:disable file_length

import Foundation

/// The type of exit offer shown.
@_spi(Internal) public enum ExitOfferType: String, Codable, Sendable {

    /// An exit offer shown when the user attempts to dismiss the paywall without interacting.
    case dismiss

}

/// The type for the paywall component interactions.
@_spi(Internal) public enum ComponentInteractionType: String, Codable, Sendable, Hashable {

    /// Tab control button selection.
    /// For precise navigation analytics, prefer the explicit origin / destination fields when present.
    case tab
    /// Tab control toggle (`component_value` is `"on"` or `"off"`); wire value is `"switch"`.
    case toggleSwitch = "switch"
    /// Carousel page change.
    /// For precise navigation analytics, prefer the explicit origin / destination fields when present.
    case carousel
    /// Non-purchase button (`component_value` is the action discriminator).
    case button
    /// Tappable link in paywall text / markdown (`component_url` is set).
    case text
    /// User selected a subscription package / plan (for example, a package row tap).
    case package
    /// Package-selection bottom sheet lifecycle (`component_value` is `open` / `close`), not a package row tap.
    case packageSelectionSheet = "package_selection_sheet"
    /// Purchase button of any type was tapped
    case purchaseButton = "purchase_button"

}

/// An event to be sent by the `RevenueCatUI` SDK.
@_spi(Internal) public enum PaywallEvent: FeatureEvent {

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
        case .impression, .cancel, .close, .exitOffer, .componentInteraction:
            return true
        }
    }

    var isPriorityEvent: Bool {
        switch self {
        case .impression:
            return true
        case .cancel, .close, .exitOffer, .componentInteraction, .purchaseInitiated, .purchaseError:
            return false
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

    /// User interacted with a paywall control (tabs, carousel, non-purchase button, etc.).
    case componentInteraction(CreationData, Data, ComponentInteractionData)

}

extension PaywallEvent {

    /// The creation data of a ``PaywallEvent``.
    @_spi(Internal) public struct CreationData {

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
    @_spi(Internal) public struct Data {

        // swiftlint:disable missing_docs

        public var paywallIdentifier: String?
        public var offeringIdentifier: String
        public var paywallRevision: Int
        public var sessionIdentifier: SessionID
        public var displayMode: PaywallViewMode
        public var localeIdentifier: String
        public var darkMode: Bool
        @_spi(Internal) public var source: PaywallSource?
        var packageId: String?
        var productId: String?
        var errorCode: Int?
        var errorMessage: String?

        #if !os(tvOS) // For Paywalls V2
        @_spi(Internal)
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
                darkMode: darkMode,
                source: nil
            )
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        @_spi(Internal) public init(
            offering: Offering,
            paywallComponentsData: PaywallComponentsData,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            locale: Locale,
            darkMode: Bool,
            source: PaywallSource?
        ) {
            self.init(
                paywallIdentifier: paywallComponentsData.id,
                offeringIdentifier: offering.identifier,
                paywallRevision: paywallComponentsData.revision,
                sessionID: sessionID,
                displayMode: displayMode,
                localeIdentifier: locale.identifier,
                darkMode: darkMode,
                source: source
            )
        }
        #endif

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        @available(*, deprecated, message: "This initializer will be removed in a future version.")
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
                darkMode: darkMode,
                source: nil
            )
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        @_spi(Internal) public init(
            offering: Offering,
            paywall: PaywallData,
            sessionID: SessionID,
            displayMode: PaywallViewMode,
            locale: Locale,
            darkMode: Bool,
            source: PaywallSource?
        ) {
            self.init(
                paywallIdentifier: paywall.id,
                offeringIdentifier: offering.identifier,
                paywallRevision: paywall.revision,
                sessionID: sessionID,
                displayMode: displayMode,
                localeIdentifier: locale.identifier,
                darkMode: darkMode,
                source: source
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
            source: PaywallSource?,
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
            self.source = source
            self.packageId = packageId
            self.productId = productId
            self.errorCode = errorCode
            self.errorMessage = errorMessage
        }

    }

}

extension PaywallEvent {

    /// The data specific to an exit offer event.
    @_spi(Internal) public struct ExitOfferData {

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

    /// Data for a ``PaywallEvent/componentInteraction(_:_:_:)`` event.
    /// For navigable controls like tab buttons and carousel page changes, prefer the explicit
    /// origin / destination fields over `componentValue` when they are available.
    @_spi(Internal) public struct ComponentInteractionData {

        // swiftlint:disable missing_docs
        public var componentType: ComponentInteractionType
        public var componentName: String?
        /// Compatibility field describing the interaction.
        /// For navigable controls, prefer the explicit origin / destination fields when they are present.
        public var componentValue: String
        /// Destination URL for URL-based controls (e.g. terms, privacy, generic links), when applicable.
        public var componentURL: URL?
        /// 0-based index for the source context before a user-initiated navigation interaction.
        public var originIndex: Int?
        /// 0-based index for the destination context after a user-initiated navigation interaction.
        public var destinationIndex: Int?
        /// Optional source context name from the paywall JSON (for example, the previous tab or carousel page).
        public var originContextName: String?
        /// Optional destination context name from the paywall JSON (for example, the selected tab or carousel page).
        public var destinationContextName: String?
        /// 0-based default index configured for the navigable component, when applicable.
        public var defaultIndex: Int?
        /// RevenueCat package identifier before a plan-selection interaction, when applicable.
        public var originPackageIdentifier: String?
        /// RevenueCat package identifier after a plan-selection interaction, when applicable.
        public var destinationPackageIdentifier: String?
        /// RevenueCat package identifier for the configured default plan in the current scope (offering or tab),
        /// when applicable.
        public var defaultPackageIdentifier: String?
        /// Store product identifier before a plan-selection interaction, when applicable.
        public var originProductIdentifier: String?
        /// Store product identifier after a plan-selection interaction, when applicable.
        public var destinationProductIdentifier: String?
        /// Store product identifier for the configured default plan in the current scope, when applicable.
        public var defaultProductIdentifier: String?
        /// Package identifier for the paywall package-selection sheet lifecycle
        /// (`component_value` is `open` / `close`).
        public var currentPackageIdentifier: String?
        /// Root paywall package identifier after the package-selection sheet dismisses (e.g. after revert to default).
        public var resultingPackageIdentifier: String?
        /// Store product identifier paired with ``currentPackageIdentifier`` for sheet lifecycle events.
        public var currentProductIdentifier: String?
        /// Store product identifier paired with ``resultingPackageIdentifier`` for sheet lifecycle events.
        public var resultingProductIdentifier: String?

        public init(
            componentType: ComponentInteractionType,
            componentName: String? = nil,
            componentValue: String,
            componentURL: URL? = nil,
            originIndex: Int? = nil,
            destinationIndex: Int? = nil,
            originContextName: String? = nil,
            destinationContextName: String? = nil,
            defaultIndex: Int? = nil,
            originPackageIdentifier: String? = nil,
            destinationPackageIdentifier: String? = nil,
            defaultPackageIdentifier: String? = nil,
            originProductIdentifier: String? = nil,
            destinationProductIdentifier: String? = nil,
            defaultProductIdentifier: String? = nil,
            currentPackageIdentifier: String? = nil,
            resultingPackageIdentifier: String? = nil,
            currentProductIdentifier: String? = nil,
            resultingProductIdentifier: String? = nil
        ) {
            self.componentType = componentType
            self.componentName = componentName
            self.componentValue = componentValue
            self.componentURL = componentURL
            self.originIndex = originIndex
            self.destinationIndex = destinationIndex
            self.originContextName = originContextName
            self.destinationContextName = destinationContextName
            self.defaultIndex = defaultIndex
            self.originPackageIdentifier = originPackageIdentifier
            self.destinationPackageIdentifier = destinationPackageIdentifier
            self.defaultPackageIdentifier = defaultPackageIdentifier
            self.originProductIdentifier = originProductIdentifier
            self.destinationProductIdentifier = destinationProductIdentifier
            self.defaultProductIdentifier = defaultProductIdentifier
            self.currentPackageIdentifier = currentPackageIdentifier
            self.resultingPackageIdentifier = resultingPackageIdentifier
            self.currentProductIdentifier = currentProductIdentifier
            self.resultingProductIdentifier = resultingProductIdentifier
        }
        // swiftlint:enable missing_docs

    }

}

extension PaywallEvent {

    /// - Returns: the underlying ``PaywallEvent/CreationData-swift.struct`` for this event.
    @_spi(Internal) public var creationData: CreationData {
        switch self {
        case let .impression(creationData, _): return creationData
        case let .cancel(creationData, _): return creationData
        case let .close(creationData, _): return creationData
        case let .exitOffer(creationData, _, _): return creationData
        case let .purchaseInitiated(creationData, _): return creationData
        case let .purchaseError(creationData, _): return creationData
        case let .componentInteraction(creationData, _, _): return creationData
        }
    }

    /// - Returns: the underlying ``PaywallEvent/Data-swift.struct`` for this event.
    @_spi(Internal) public var data: Data {
        switch self {
        case let .impression(_, data): return data
        case let .cancel(_, data): return data
        case let .close(_, data): return data
        case let .exitOffer(_, data, _): return data
        case let .purchaseInitiated(_, data): return data
        case let .purchaseError(_, data): return data
        case let .componentInteraction(_, data, _): return data
        }
    }

    /// - Returns: the underlying ``PaywallEvent/ExitOfferData-swift.struct`` for exit offer events, nil otherwise.
    @_spi(Internal) public var exitOfferData: ExitOfferData? {
        switch self {
        case .impression, .cancel, .close, .purchaseInitiated, .purchaseError, .componentInteraction: return nil
        case let .exitOffer(_, _, exitOfferData): return exitOfferData
        }
    }

    /// - Returns: control interaction payload for ``PaywallEvent/componentInteraction(_:_:_:)``, nil for other events.
    @_spi(Internal) public var componentInteractionData: ComponentInteractionData? {
        switch self {
        case .impression, .cancel, .close, .exitOffer, .purchaseInitiated, .purchaseError: return nil
        case let .componentInteraction(_, _, interactionData): return interactionData
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
            paywallIdentifier: self.paywallIdentifier,
            offeringIdentifier: self.offeringIdentifier,
            paywallRevision: self.paywallRevision,
            sessionID: self.sessionIdentifier,
            displayMode: self.displayMode,
            localeIdentifier: self.localeIdentifier,
            darkMode: self.darkMode,
            source: self.source,
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
extension PaywallEvent.ComponentInteractionData: Equatable, Codable, Sendable {}
extension PaywallEvent: Equatable, Codable, Sendable {}
