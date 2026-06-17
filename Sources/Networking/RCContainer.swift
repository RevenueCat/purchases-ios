//
//  RCContainer.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

struct RCContainer {

    let flags: UInt8
    let config: Element
    let contentElements: [String: Element]

    init(data: Data) throws {
        var parser = Parser(data: data)
        let parsed = try parser.parse()
        let elements = parsed.elements
        guard let config = elements.first else {
            throw Parser.FormatError.missingConfigElement
        }

        self.flags = parsed.flags
        self.config = config
        self.contentElements = Dictionary(
            elements.dropFirst().map { ($0.checksum, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

}
