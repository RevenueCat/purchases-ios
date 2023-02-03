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

    /// Equivalent to `.json`, but with `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`
    /// and `JSONEncoder.OutputFormatting.withoutEscapingSlashes` if available.
    static var formattedJson: Snapshotting {
        return self.formattedJson(backwardsCompatible: false)
    }

    /// Equivalent to `.formattedJson`, but not using `JSONEncoder.OutputFormatting.withoutEscapingSlashes`
    /// so its output is equivalent regardless of iOS version.
    static var backwardsCompatibleFormattedJson: Snapshotting {
        return self.formattedJson(backwardsCompatible: true)
    }

    private static func formattedJson(backwardsCompatible: Bool) -> Snapshotting {
        var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
            // swiftlint:disable:next force_try
            return try! data.asFormattedString(backwardsCompatible: backwardsCompatible)
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }

}

private extension Encodable {

    func asFormattedString(backwardsCompatible: Bool) throws -> String {
        return String(decoding: try self.asFormattedData(backwardsCompatible: backwardsCompatible),
                      as: UTF8.self)
    }

    func asFormattedData(backwardsCompatible: Bool) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = backwardsCompatible
            ? backwardsCompatibleOutputFormatting
            : outputFormatting

        return try encoder.encode(self)
    }

}

private let backwardsCompatibleOutputFormatting: JSONEncoder.OutputFormatting = {
    return [
        .prettyPrinted,
        .sortedKeys
    ]
}()

private let outputFormatting: JSONEncoder.OutputFormatting = {
    var result = backwardsCompatibleOutputFormatting

    if #available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *) {
        result.update(with: .withoutEscapingSlashes)
    }

    return result
}()
