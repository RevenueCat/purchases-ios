//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentViewLoadingTests.swift
//
//  Created by RevenueCat on 5/12/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(tvOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewLoadingTests: BaseSnapshotTest {

    private static let snapshotSize = CGSize(width: 300, height: 60)

    func testTextIsRedactedWhileLoading() throws {
        try Self.makeTextComponentView(text: "Hello, world", isLoading: true)
            .snapshot(size: Self.snapshotSize)
    }

    func testTextIsVisibleWhenLoaded() throws {
        try Self.makeTextComponentView(text: "Hello, world", isLoading: false)
            .snapshot(size: Self.snapshotSize)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TextComponentViewLoadingTests {

    static func makeTextComponentView(text: String, isLoading: Bool) throws -> some View {
        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["text_key": .string(text)]
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: PaywallComponent.TextComponent(
                text: "text_key",
                color: .init(light: .hex("#000000"))
            )
        )
        return TextComponentView(viewModel: viewModel)
            .previewRequiredPaywallsV2Properties()
            .environment(\.isPaywallLoading, isLoading)
    }

}

#endif
