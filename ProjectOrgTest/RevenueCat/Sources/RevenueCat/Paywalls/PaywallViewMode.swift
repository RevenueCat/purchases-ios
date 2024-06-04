//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewMode.swift
//
//  Created by Nacho Soto on 7/21/23.

import Foundation

/// The mode for how a paywall is rendered.
public enum PaywallViewMode {

    /// Paywall is displayed full-screen, with as much information as available.
    case fullScreen

    /// Paywall can be displayed as an overlay on top of your own content.
    /// Multi-package templates will display the package selection.
    @available(watchOS, unavailable)
    case footer

    /// Paywall can be displayed as an overlay on top of your own content.
    /// Multi-package templates will include a button to make the package selection visible.
    @available(watchOS, unavailable)
    case condensedFooter

    /// The default ``PaywallViewMode``: ``PaywallViewMode/fullScreen``.
    public static let `default`: Self = .fullScreen

}

extension PaywallViewMode {

    /// Whether this mode is ``PaywallViewMode/fullScreen``.
    public var isFullScreen: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

}

extension PaywallViewMode {

    var identifier: String {
        switch self {
        case .fullScreen: return "full_screen"
        case .footer: return "footer"
        case .condensedFooter: return "condensed_footer"
        }
    }

}

// MARK: - Extensions

extension PaywallViewMode: CaseIterable {

    // swiftlint:disable:next missing_docs
    public static var allCases: [PaywallViewMode] {
        #if os(watchOS)
        return [.fullScreen]
        #else
        return [
            .fullScreen,
            .footer,
            .condensedFooter
        ]
        #endif
    }

}

extension PaywallViewMode: Sendable {}
extension PaywallViewMode: Hashable {}

extension PaywallViewMode: Codable {

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.identifier)
    }

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let identifier = try decoder.singleValueContainer().decode(String.self)

        self = try Self.modesByIdentifier[identifier]
            .orThrow(CodableError.unexpectedValue(Self.self, identifier))
    }

    private static let modesByIdentifier: [String: Self] = Set(Self.allCases)
        .dictionaryWithKeys(\.identifier)

}
