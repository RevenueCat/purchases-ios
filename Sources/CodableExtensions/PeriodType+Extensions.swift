//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PeriodType+Extensions.swift
//
//  Created by Juanpe Catalán on 26/8/21.

import Foundation

extension PeriodType: Decodable {

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let periodTypeString = try? container.decode(String.self) else {
            throw decoder.valueNotFoundError(expectedType: PeriodType.self,
                                             message: "Unable to extract a periodTypeString")
        }

        guard let type = Self.mapping[periodTypeString] else {
            throw CodableError.unexpectedValue(PeriodType.self, periodTypeString)
        }

        self = type
    }

    private static let mapping: [String: Self] = Self.allCases
        .dictionaryWithKeys { $0.name }

}

extension PeriodType: Encodable {

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.name)
    }

}

private extension PeriodType {

    var name: String {
        switch self {
        case .normal: return "normal"
        case .intro: return "intro"
        case .trial: return "trial"
        }
    }

}
