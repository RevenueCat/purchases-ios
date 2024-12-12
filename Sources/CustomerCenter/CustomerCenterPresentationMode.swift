//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPresentationMode.swift
//
//  Created by Cesar de la Vega on 27/11/24.

import Foundation

/// Presentation options to use with the [presentCustomerCenter](x-source-tag://presentCustomerCenter) View modifiers.
public enum CustomerCenterPresentationMode {

    /// Customer Center presented using SwiftUI's `.sheet`.
    case sheet

    /// Customer Center presented using SwiftUI's `.fullScreenCover`.
    case fullScreen

}

extension CustomerCenterPresentationMode {

    // swiftlint:disable:next missing_docs
    public static let `default`: Self = .sheet

}

extension CustomerCenterPresentationMode {

    var identifier: String {
        switch self {
        case .fullScreen: return "full_screen"
        case .sheet: return "sheet"
        }
    }

}

// MARK: - Extensions

extension CustomerCenterPresentationMode: CaseIterable {

    // swiftlint:disable:next missing_docs
    public static var allCases: [CustomerCenterPresentationMode] {
        return [
            .fullScreen,
            .sheet
        ]
    }

}

extension CustomerCenterPresentationMode: Equatable, Sendable {}

extension CustomerCenterPresentationMode: Codable {

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
