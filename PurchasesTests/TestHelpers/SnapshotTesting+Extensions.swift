//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SnapshotTesting+Extensions.swift
//
//  Created by Nacho Soto on 3/4/22.

import Foundation
import SnapshotTesting

@testable import RevenueCat

extension Snapshotting where Value == Encodable, Format == String {

    /// Equivalent to .json, but with `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`
    static var formattedJson: Snapshotting {
        var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
            // swiftlint:disable:next force_try
            return try! data.asFormattedString()
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }

}

private extension Encodable {

    func asFormattedString() throws -> String {
        return String(decoding: try self.asFormattedData(), as: UTF8.self)
    }

    func asFormattedData() throws -> Data {
        var formatting: JSONEncoder.OutputFormatting {
            var result: JSONEncoder.OutputFormatting = [
                .prettyPrinted,
                .sortedKeys
            ]

            if #available(iOS 13.0, *) {
                result.insert(.withoutEscapingSlashes)
            }

            return result
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = formatting

        return try encoder.encode(self)
    }

}
