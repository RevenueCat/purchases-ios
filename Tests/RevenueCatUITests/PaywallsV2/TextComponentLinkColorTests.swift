//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentLinkColorTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(tvOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentLinkColorTests: BaseSnapshotTest {

    /// Markdown links must use the paywall's text color, not the system tint (blue).
    func testMarkdownLinkUsesPaywallTextColor() throws {
        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["text_key": .string("Read our [Terms](https://revenuecat.com)")]
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: PaywallComponent.TextComponent(
                text: "text_key",
                color: .init(light: .hex("#FF0000"))
            )
        )

        TextComponentView(viewModel: viewModel)
            .previewRequiredPaywallsV2Properties()
            .snapshot(size: CGSize(width: 300, height: 60))
    }

}

#endif
