//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseOwnershipType+Extensions.swift
//
//  Created by Juanpe Catalán on 26/8/21.

import Foundation

extension PurchaseOwnershipType: Decodable {

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        guard !container.decodeNil() else {
            self = .unknown
            return
        }

        guard let purchaseOwnershipTypeString = try? container.decode(String.self) else {
            throw decoder.valueNotFoundError(expectedType: PurchaseOwnershipType.self,
                                             message: "Unable to extract an purchaseOwnershipTypeString")
        }

        if let type = Self.mapping[purchaseOwnershipTypeString] {
            self = type
        } else {
            Logger.error(Strings.codable.unexpectedValueError(type: PurchaseOwnershipType.self,
                                                              value: purchaseOwnershipTypeString))
            self = .unknown
        }
    }

    private static let mapping: [String: Self] = Self.allCases
        .reduce(into: [:]) { result, type in
            if let name = type.name { result[name] = type }
        }

}

extension PurchaseOwnershipType: Encodable {

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.name)
    }

}

private extension PurchaseOwnershipType {

    var name: String? {
        switch self {
        case .purchased: return "PURCHASED"
        case .familyShared: return "FAMILY_SHARED"
        case .unknown: return nil
        }
    }

}
