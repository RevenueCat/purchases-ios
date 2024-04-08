//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsEntry.swift
//
//  Created by Cesar de la Vega on 1/4/24.

import Foundation

struct DiagnosticsEvent: Codable, Equatable {

    let version: Int = 1
    let name: String
    let properties: [String: AnyEncodable]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case version, name, properties, timestamp
    }

}

extension DiagnosticsEvent {

    static func == (lhs: DiagnosticsEvent, rhs: DiagnosticsEvent) -> Bool {
        return lhs.version == rhs.version &&
               lhs.name == rhs.name &&
               lhs.properties == rhs.properties &&
               lhs.timestamp == rhs.timestamp
    }

}
