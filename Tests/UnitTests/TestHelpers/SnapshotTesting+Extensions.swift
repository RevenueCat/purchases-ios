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

#if swift(>=5.8) && canImport(SwiftUI)
import SwiftUI
#endif

@testable import RevenueCat

// MARK: - Overloads for Xcode Cloud support

func assertSnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
    let failure = verifySnapshot(
        matching: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )

    if let message = failure {
        XCTFail(message, file: file, line: line)
    }
}

func verifySnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) -> String? {
    let snapshotDirectory: String?

    if ProcessInfo.isXcodeCloud {
        let ciPathPrefix = "/Volumes/workspace/repository/ci_scripts/"
        let components = URL(string: file.description)!.pathComponents
        let projectIndex = components.firstIndex(of: "repository")!
        let folders = components[(projectIndex + 1)..<components.endIndex - 1].joined(separator: "/")
        let fileName = (components[components.endIndex - 1] as NSString).deletingPathExtension

        snapshotDirectory = "\(ciPathPrefix)\(folders)/__Snapshots__/\(fileName)"
    } else {
        snapshotDirectory = nil
    }

    return SnapshotTesting.verifySnapshot(
        matching: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
}

// MARK: - Snapshotting extensions

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

// MARK: - Image Snapshoting

#if !os(watchOS) && !os(macOS) && swift(>=5.8)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
extension SwiftUI.View {

    func snapshot(
        size: CGSize,
        file: StaticString = #file,
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
                file: file,
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

private let perceptualPrecision: Float = 0.97
private let timeout: DispatchTimeInterval = .seconds(5)
private let pollInterval: DispatchTimeInterval = .milliseconds(100)

// MARK: - Private

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
