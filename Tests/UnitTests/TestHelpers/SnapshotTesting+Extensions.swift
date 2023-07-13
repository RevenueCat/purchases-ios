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
import SwiftUI

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

// MARK: - Image Snapshoting

#if !os(watchOS) && swift(>=5.8)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
extension SwiftUI.View {

    func snapshot(
        size: CGSize,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Add test view to the hierarchy to make sure async rendering takes place.
        // The tested view is `controller.view` instead of `self` to keep it in memory
        // while rendering happens
        let controller = UIViewController()
        let window = UIWindow()
        window.rootViewController = controller

        controller.view.addSubview(
            self
                .frame(width: size.width, height: size.height)
                .asUIView(container: controller, size: size)
        )
        controller.view.backgroundColor = .white

        expect(
            file: file, line: line,
            controller.view
        ).toEventually(
            haveValidSnapshot(
                as: .image(size: size),
                named: "1", // Force each retry to end in `.1.png`
                file: file,
                line: line
            ),
            timeout: timeout,
            pollInterval: pollInterval
        )
    }

}
#endif

private let timeout: DispatchTimeInterval = .seconds(1)
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

// MARK: - SwiftUIContainerView

#if !os(watchOS)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
@available(watchOS, unavailable)
private final class SwiftUIContainerView<V: SwiftUI.View>: UIView {

    private let controller: UIHostingController<V>

    init(container: UIViewController, view: V, size: CGSize) {
        self.controller = UIHostingController(rootView: view)
        self.controller.view.backgroundColor = nil

        super.init(frame: .init(origin: .zero, size: size))

        container.addChild(self.controller)
        self.addSubview(self.controller.view)
        self.controller.didMove(toParent: container)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.controller.view.frame = self.bounds
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension SwiftUI.View {

    func asUIView(container: UIViewController, size: CGSize) -> SwiftUIContainerView<Self> {
        return SwiftUIContainerView(container: container, view: self, size: size)
    }

}

#endif
