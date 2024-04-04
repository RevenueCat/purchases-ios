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

protocol DiagnosticsEntry: Codable, Equatable {

    var diagnosticType: String { get }
    var version: Int { get }

}

struct DiagnosticsEvent: DiagnosticsEntry {

    let version: Int = 1
    let diagnosticType: String = "event"
    let name: String
    let properties: [String: AnyEncodable]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case diagnosticType = "type"
        case name, properties, timestamp, version
    }

}

extension DiagnosticsEvent {

    static func == (lhs: DiagnosticsEvent, rhs: DiagnosticsEvent) -> Bool {
        return lhs.diagnosticType == rhs.diagnosticType &&
               lhs.name == rhs.name &&
               lhs.properties == rhs.properties &&
               lhs.timestamp == rhs.timestamp
    }

}
