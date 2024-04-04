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

extension DiagnosticsEntry {
    var version: Int { 1 }

    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(self) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}

struct DiagnosticsEvent: DiagnosticsEntry {
    
    var diagnosticType: String = "event"
    let name: String
    let properties: [String: AnyEncodable]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case diagnosticType = "type"
        case name, properties, timestamp
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

struct Counter: DiagnosticsEntry {

    var diagnosticType: String = "counter"
    let name: String
    let tags: [String: String]
    let value: Int

    enum CodingKeys: String, CodingKey {
        case diagnosticType = "type"
        case name, tags, value
    }

}

struct Histogram: DiagnosticsEntry {

    var diagnosticType: String = "histogram"
    let name: String
    let tags: [String: String]
    let values: [Double]

    enum CodingKeys: String, CodingKey {
        case diagnosticType = "type"
        case name, tags, values
    }
    
}
