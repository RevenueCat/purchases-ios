//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsV2LayoutFixtures.swift
//
//  Created by RevenueCat on 5/28/26.

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI

#if !os(tvOS) && !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallsV2LayoutFixtures {

    static let iPadFormSheetSize = CGSize(width: 580, height: 778)

    static let localizationProvider = LocalizationProvider(
        locale: Locale(identifier: "en_US"),
        localizedStrings: [
            "hero_title": .string("Unlock Pro"),
            "hero_subtitle": .string("Tall hero z-layer layout regression fixture."),
            "footer_copy": .string("Subscribe for $79.99/yr"),
            "footer_cta": .string("Continue"),
            "footer_restore": .string("Restore Purchases"),
            "header_title": .string("Overlay header"),
            "header_subtitle": .string("Header overlays hero media")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    static let offering = Offering(
        identifier: "layout-fixture",
        serverDescription: "",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    static func makeRootViewModel(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig
    ) throws -> RootViewModel {
        var factory = ViewModelFactory()
        return try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        )
    }

    static func makeStickyFooterHeroRootViewModel() throws -> RootViewModel {
        let heroZLayer = PaywallComponent.StackComponent(
            components: [
                .image(.init(
                    source: .init(light: .init(
                        width: 899,
                        height: 1134,
                        original: Self.heroImageURL,
                        heic: Self.heroImageURL,
                        heicLowRes: Self.heroImageURL
                    )),
                    size: .init(width: .fill, height: .fit),
                    fitMode: .fill
                )),
                .text(.init(
                    text: "hero_title",
                    fontWeight: .bold,
                    color: .init(light: .hex("#FFFFFF")),
                    padding: .zero,
                    margin: .init(top: 24, bottom: 0, leading: 16, trailing: 16),
                    fontSize: 22,
                    horizontalAlignment: .leading
                ))
            ],
            dimension: .zlayer(.top),
            size: .init(width: .fill, height: .fit),
            spacing: 0
        )

        let bodyStack = PaywallComponent.StackComponent(
            components: [
                .stack(heroZLayer),
                .text(.init(
                    text: "hero_subtitle",
                    color: .init(light: .hex("#666666")),
                    padding: .zero,
                    margin: .init(top: 16, bottom: 24, leading: 24, trailing: 24),
                    fontSize: 14,
                    horizontalAlignment: .center
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill),
            spacing: 0,
            backgroundColor: .init(light: .hex("#FFFFFF"))
        )

        let footerStack = PaywallComponent.StackComponent(
            components: [
                .text(.init(
                    text: "footer_copy",
                    color: .init(light: .hex("#666666")),
                    padding: .zero,
                    margin: .zero,
                    fontSize: 14,
                    horizontalAlignment: .center
                )),
                .text(.init(
                    text: "footer_cta",
                    fontWeight: .semibold,
                    color: .init(light: .hex("#FFFFFF")),
                    backgroundColor: .init(light: .hex("#111111")),
                    padding: .init(top: 14, bottom: 14, leading: 16, trailing: 16),
                    margin: .zero,
                    fontSize: 16,
                    horizontalAlignment: .center
                )),
                .text(.init(
                    text: "footer_restore",
                    color: .init(light: .hex("#888888")),
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

        return try makeRootViewModel(
            componentsConfig: .init(
                stack: bodyStack,
                stickyFooter: .init(stack: footerStack),
                background: .color(.init(light: .hex("#FFFFFF")))
            )
        )
    }

    static func makeOverlayHeaderStickyFooterRootViewModel() throws -> RootViewModel {
        let stickyFooterRoot = try makeStickyFooterHeroRootViewModel()

        let headerStack = PaywallComponent.StackComponent(
            components: [
                .image(.init(
                    source: .init(light: .init(
                        width: 1024,
                        height: 400,
                        original: Self.heroImageURL,
                        heic: Self.heroImageURL,
                        heicLowRes: Self.heroImageURL
                    )),
                    size: .init(width: .fill, height: .fit),
                    fitMode: .fill
                )),
                .text(.init(
                    text: "header_title",
                    color: .init(light: .hex("#FFFFFF")),
                    padding: .zero,
                    margin: .init(top: 8, bottom: 0, leading: 16, trailing: 16),
                    fontSize: 16,
                    horizontalAlignment: .leading
                ))
            ],
            dimension: .zlayer(.top),
            size: .init(width: .fill, height: .fit),
            spacing: 0
        )

        return try makeRootViewModel(
            componentsConfig: .init(
                stack: stickyFooterRoot.stackViewModel.component,
                header: .init(stack: headerStack),
                stickyFooter: .init(stack: stickyFooterRoot.stickyFooterViewModel!.stackViewModel.component),
                background: .color(.init(light: .hex("#FFFFFF")))
            )
        )
    }

    @MainActor
    static func makeRootView(
        viewModel: RootViewModel,
        size: CGSize,
        safeAreaInsets: EdgeInsets = EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
    ) -> some View {
        RootView(viewModel: viewModel, onDismiss: {}, defaultPackage: nil)
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, safeAreaInsets)
            .environment(\.isRunningSnapshots, true)
            .frame(width: size.width, height: size.height)
    }

    private static let heroImageURL: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("paywalls-v2-layout-hero.png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let data = Data(base64Encoded: [
                "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQ",
                "z0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC"
            ].joined())!
            try? data.write(to: url, options: .atomic)
        }
        return url
    }()

}

#endif
