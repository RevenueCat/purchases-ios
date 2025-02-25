//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageType.swift
//
//  Created by Nacho Soto on 5/26/22.

import Foundation

///
/// Enumeration of all possible ``Package`` types, as configured on the package.
///
/// #### Related Articles
/// - ``Package``
/// -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
///
@objc(RCPackageType) public enum PackageType: Int {

    /// A package that was defined with an unknown identifier.
    case unknown = -2,
    /// A package that was defined with a custom identifier.
    custom,
    /// A package configured with the predefined lifetime identifier.
    lifetime,
    /// A package configured with the predefined annual identifier.
    annual,
    /// A package configured with the predefined six month identifier.
    sixMonth,
    /// A package configured with the predefined three month identifier.
    threeMonth,
    /// A package configured with the predefined two month identifier.
    twoMonth,
    /// A package configured with the predefined monthly identifier.
    monthly,
    /// A package configured with the predefined weekly identifier.
    weekly
}

extension PackageType: CaseIterable {}

extension PackageType: Sendable {}

extension PackageType: CustomDebugStringConvertible {

    /// A textual description of the type suitable for debugging.
    public var debugDescription: String {
        let className = String(describing: PackageType.self)

        switch self {
        case .unknown: return "\(className).unknown"
        case .custom: return "\(className).custom"
        default: return "\(className).\(self.description ?? "")"
        }
    }

}

extension PackageType: Codable {

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let description = self.description {
            try container.encode(description)
        } else {
            try container.encodeNil()
        }
    }

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        do {
            self = Package.packageType(from: try decoder.singleValueContainer().decode(String.self))
        } catch {
            ErrorUtils.logDecodingError(error, type: Self.self)
            self = .unknown
        }
    }

}

extension PackageType {

    var description: String? {
        switch self {
        case .unknown: return nil
        case .custom: return nil
        case .lifetime: return "$rc_lifetime"
        case .annual: return "$rc_annual"
        case .sixMonth: return "$rc_six_month"
        case .threeMonth: return "$rc_three_month"
        case .twoMonth: return "$rc_two_month"
        case .monthly: return "$rc_monthly"
        case .weekly: return "$rc_weekly"
        }
    }

    // swiftlint:disable force_unwrapping
    static let typesByDescription: [String: PackageType] = PackageType
        .allCases
        .filter { $0.description != nil }
        .dictionaryWithKeys { $0.description! }
    // swiftlint:enable force_unwrapping

}
