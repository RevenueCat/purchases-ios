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

// Remove once https://github.com/pointfreeco/swift-snapshot-testing/pull/552 is available in a release.
extension Snapshotting where Value == Any, Format == String {

    static var json: Snapshotting {
        let options: JSONSerialization.WritingOptions = [
            .prettyPrinted,
            .sortedKeys
        ]

        var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
            // swiftlint:disable:next force_try
            try! String(decoding: JSONSerialization.data(withJSONObject: data,
                                                         options: options), as: UTF8.self)
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }

}

extension Snapshotting where Value == Encodable, Format == String {

    /// Equivalent to .json, but with `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`
    static var formattedJson: Snapshotting {
        var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
            // swiftlint:disable:next force_try
            return String(decoding: try! data.asFormattedData(), as: UTF8.self)
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }

}

private extension Encodable {

    func asFormattedData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        return try encoder.encode(self)
    }

}
