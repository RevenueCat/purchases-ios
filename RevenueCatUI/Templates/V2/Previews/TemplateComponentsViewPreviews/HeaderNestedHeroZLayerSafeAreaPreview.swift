//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderNestedHeroZLayerSafeAreaPreview.swift
//
//  Created by RevenueCat on 4/10/26.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum HeaderNestedHeroZLayerSafeAreaPreview {

    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    static let previewDisplayName =
        "Paywall pw6328703e14874ca2: header stays above nested hero text"
    static let previewTitle = "Header stays above nested hero text"
    static let previewSubtitle =
        "Verifies safe-area propagation through a root vertical stack with a nested hero zlayer."

    static let heroImageURL = Self.makeLocalPreviewImageURL(
        filename: "paywall-pw6328703e14874ca2-hero.png",
        base64: [
            "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGNgYPjP",
            "wMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
        ].joined()
    )

    static let offering = Offering(
        identifier: "preview",
        serverDescription: "",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    static let localizationProvider: LocalizationProvider = .init(
        locale: Locale(identifier: "en_US"),
        localizedStrings: [
            "header_label_primary": .string("Text 2"),
            "header_label_secondary": .string("Header marker"),
            "hero_overlay_label": .string("Text"),
            "paywall_title": .string("Unlock Your Smartest Study Routine"),
            "paywall_subtitle": .string("Nested hero zlayer preview used to verify header safe-area propagation."),
            "footer_copy": .string("Subscribe to Pro for just $79.99/yr"),
            "footer_cta": .string("Continue"),
            "footer_restore": .string("Restore Purchases")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    static func makeLocalPreviewImageURL(
        filename: String,
        base64: String
    ) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: url.path) {
            guard let data = Data(base64Encoded: base64) else {
                fatalError("Invalid base64 preview image for pw6328703e14874ca2")
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                fatalError("Failed to write pw6328703e14874ca2 preview image: \(error)")
            }
        }

        return url
    }

    static let headerStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "header_label_primary",
                color: .init(light: .hex("#FF3B30")),
                padding: .zero,
                margin: .zero,
                fontSize: 14,
                horizontalAlignment: .leading
            )),
            .text(.init(
                text: "header_label_secondary",
                color: .init(light: .hex("#FF3B30")),
                padding: .zero,
                margin: .zero,
                fontSize: 14,
                horizontalAlignment: .leading
            ))
        ],
        dimension: .vertical(.leading, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 4,
        padding: .init(top: 0, bottom: 8, leading: 12, trailing: 12)
    )

    static let heroZLayerStack = PaywallComponent.StackComponent(
        components: [
            .image(.init(
                source: .init(light: .init(
                    width: 1024,
                    height: 1024,
                    original: Self.heroImageURL,
                    heic: Self.heroImageURL,
                    heicLowRes: Self.heroImageURL
                )),
                size: .init(width: .fill, height: .fixed(300)),
                fitMode: .fill
            )),
            .text(.init(
                text: "hero_overlay_label",
                color: .init(light: .hex("#62FC03")),
                padding: .zero,
                margin: .init(top: 8, bottom: 0, leading: 12, trailing: 0),
                fontSize: 14,
                horizontalAlignment: .leading
            ))
        ],
        dimension: .zlayer(.topLeading),
        size: .init(width: .fill, height: .fit),
        spacing: 0
    )

    static let contentBlock = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "paywall_title",
                fontWeight: .black,
                color: .init(light: .hex("#272727")),
                padding: .zero,
                margin: .zero,
                fontSize: 24,
                horizontalAlignment: .center
            )),
            .text(.init(
                text: "paywall_subtitle",
                color: .init(light: .hex("#666666")),
                padding: .zero,
                margin: .zero,
                fontSize: 14,
                horizontalAlignment: .center
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 12,
        backgroundColor: .init(light: .hex("#FFFFFF")),
        padding: .init(top: 28, bottom: 28, leading: 24, trailing: 24)
    )

    static let bodyStack = PaywallComponent.StackComponent(
        components: [
            .stack(Self.heroZLayerStack),
            .stack(Self.contentBlock)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 0,
        backgroundColor: .init(light: .hex("#FFFFFF"))
    )

    static let footerStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "footer_copy",
                color: .init(light: .hex("#666666")),
                padding: .zero,
                margin: .zero,
                fontSize: 14,
                horizontalAlignment: .center
            )),
            .stack(.init(
                components: [
                    .text(.init(
                        text: "footer_cta",
                        fontWeight: .semibold,
                        color: .init(light: .hex("#0C0C0C")),
                        padding: .zero,
                        margin: .zero,
                        fontSize: 16,
                        horizontalAlignment: .center
                    ))
                ],
                dimension: .vertical(.center, .center),
                size: .init(width: .fill, height: .fit),
                spacing: 0,
                backgroundColor: .init(light: .hex("#9DF3D8")),
                padding: .init(top: 14, bottom: 14, leading: 16, trailing: 16)
            )),
            .text(.init(
                text: "footer_restore",
                fontWeight: .semibold,
                color: .init(light: .hex("#8A8A8A")),
                padding: .zero,
                margin: .zero,
                fontSize: 13,
                horizontalAlignment: .center
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 12,
        backgroundColor: .init(light: .hex("#FFFFFF")),
        padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16)
    )

    static let rootViewModel: RootViewModel = {
        var factory = ViewModelFactory()

        do {
            return try factory.toRootViewModel(
                componentsConfig: .init(
                    stack: Self.bodyStack,
                    header: .init(stack: Self.headerStack),
                    stickyFooter: .init(stack: Self.footerStack),
                    background: .color(.init(light: .hex("#FFFFFF")))
                ),
                offering: Self.offering,
                localizationProvider: Self.localizationProvider,
                uiConfigProvider: Self.uiConfigProvider,
                colorScheme: .light
            )
        } catch {
            fatalError("Invalid preview configuration for pw6328703e14874ca2: \(error)")
        }
    }()

    static func preview() -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(Self.previewTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)

                Text(Self.previewSubtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            RootView(
                viewModel: Self.rootViewModel,
                onDismiss: {},
                defaultPackage: nil
            )
            .frame(width: 393, height: 852)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .frame(width: 425, height: 936)
        .background(Color.white)
        .previewRequiredPaywallsV2Properties()
        .environment(\.safeAreaInsets, Self.safeAreaInsets)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: 425, height: 936))
        .previewDisplayName(Self.previewDisplayName)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HeaderNestedHeroZLayerSafeAreaPreview_Previews: PreviewProvider {

    static var previews: some View {
        HeaderNestedHeroZLayerSafeAreaPreview.preview()
    }

}

#endif

#endif
