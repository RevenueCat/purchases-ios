//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderTextBodyHeroSafeAreaPreview.swift
//
//  Created by RevenueCat on 4/10/26.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum HeaderTextBodyHeroSafeAreaPreview {

    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    static let previewDisplayName = "Paywall pw3aa70e16bb844eb7: header text + body hero safe area"
    static let previewTitle = "Header text starts below the top inset"
    static let previewSubtitle = "Verifies a text-only header with a body hero placed immediately beneath it."

    static let offering = Offering(
        identifier: "preview",
        serverDescription: "",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    static let localizationProvider: LocalizationProvider = .init(
        locale: Locale(identifier: "en_US"),
        localizedStrings: [
            "header_label": .string("Text"),
            "hero_label": .string("Hero image area"),
            "paywall_title": .string("Unlock Your Smartest Study Routine"),
            "paywall_subtitle": .string("Header + hero image paywall used to verify top safe-area rendering."),
            "footer_copy": .string("Subscribe to Pro for just $7.99/yr"),
            "footer_cta": .string("Continue"),
            "footer_restore": .string("Restore Purchases")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    static let headerStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "header_label",
                color: .init(light: .hex("#FF3B30")),
                padding: .zero,
                margin: .zero,
                fontSize: 14,
                horizontalAlignment: .leading
            ))
        ],
        dimension: .vertical(.leading, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 0,
        padding: .init(top: 0, bottom: 8, leading: 12, trailing: 12)
    )

    static let heroBlock = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "hero_label",
                fontWeight: .semibold,
                color: .init(light: .hex("#FFFFFF")),
                padding: .zero,
                margin: .zero,
                fontSize: 16,
                horizontalAlignment: .center
            ))
        ],
        dimension: .vertical(.center, .center),
        size: .init(width: .fill, height: .fixed(300)),
        spacing: 0,
        backgroundColor: .init(light: .hex("#1F2A44"))
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
            .stack(Self.heroBlock),
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
            fatalError("Invalid preview configuration for pw3aa70e16bb844eb7: \(error)")
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
struct HeaderTextBodyHeroSafeAreaPreview_Previews: PreviewProvider {

    static var previews: some View {
        HeaderTextBodyHeroSafeAreaPreview.preview()
    }

}

#endif

#endif
