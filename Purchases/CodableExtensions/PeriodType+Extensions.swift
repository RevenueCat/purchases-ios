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

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let periodTypeString = try? container.decode(String.self) else {
            throw CodableError.valueNotFound(PeriodType.self)
        }

        switch periodTypeString {
        case "normal":
            self = .normal
        case "intro":
            self = .intro
        case "trial":
            self = .trial
        default:
            throw CodableError.unexpectedValue(PeriodType.self)
        }
    }

}
