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
import Nimble
import SnapshotTesting
import XCTest

#if canImport(SwiftUI)
import SwiftUI
#endif

@testable import RevenueCat

// MARK: - Snapshotting extensions

extension Snapshotting where Value == Encodable, Format == String {

    /// Uses a copy of the SDK's `JSONEncoder.prettyPrinted`,
    /// but with `JSONEncoder.OutputFormatting.withoutEscapingSlashes`.
    static var formattedJson: Snapshotting {
        return self.formattedJson(backwardsCompatible: false)
    }

    /// Uses a copy of the SDK's `JSONEncoder.prettyPrinted`
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

// MARK: - Image Snapshoting

#if !os(watchOS) && !os(macOS)
extension SwiftUI.View {

    func snapshot(
        size: CGSize,
        file: FileString = #filePath,
        filename: StaticString = #file, // Used to generate the snapshot file name
        line: UInt = #line
    ) {
        UIView.setAnimationsEnabled(false)

        // The tested view is `controller.view` instead of `self` to keep it in memory
        // while rendering happens
        let controller = UIHostingController(rootView: self
                .frame(width: size.width, height: size.height)
        )

        expect(
            file: file, line: line,
            controller
        ).toEventually(
            haveValidSnapshot(
                as: .image(perceptualPrecision: perceptualPrecision, size: size, traits: traits),
                named: "1", // Force each retry to end in `.1.png`
                separateOSVersions: false,
                record: true, // Always record so snapshots are saved to disk for Emerge BYOS upload
                file: filename,
                line: line
            ),
            timeout: timeout,
            pollInterval: pollInterval
        )
    }

}

// Generate snapshots with scale 1, which drastically reduces the file size.
private let traits: UITraitCollection = .init(displayScale: 1)

#endif

private let perceptualPrecision: Float = 0.93
private let timeout: NimbleTimeInterval = .seconds(3)
private let pollInterval: NimbleTimeInterval = .milliseconds(100)

// MARK: - Private

private extension Encodable {

    func asFormattedString(backwardsCompatible: Bool) throws -> String {
        let data = try self.asFormattedData(backwardsCompatible: backwardsCompatible)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "EncodingError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Provided data is not a valid UTF-8 string."]
            )
        }
        return string
    }

    func asFormattedData(backwardsCompatible: Bool) throws -> Data {
        // Copy the encoder used in the SDK to get similar results
        let sdkEncoder = JSONEncoder.prettyPrinted

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = sdkEncoder.keyEncodingStrategy
        encoder.dateEncodingStrategy = sdkEncoder.dateEncodingStrategy
        encoder.dataEncodingStrategy = sdkEncoder.dataEncodingStrategy
        encoder.nonConformingFloatEncodingStrategy = sdkEncoder.nonConformingFloatEncodingStrategy
        encoder.userInfo = sdkEncoder.userInfo
        var outputFormatting = sdkEncoder.outputFormatting
        if !backwardsCompatible {
            outputFormatting.update(with: .withoutEscapingSlashes)
        }
        encoder.outputFormatting = outputFormatting

        return try encoder.encode(self)
    }

}
