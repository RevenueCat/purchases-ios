//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootViewScrollLayoutPreview.swift
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if DEBUG && !os(tvOS) && !os(watchOS) && !os(macOS)
#if swift(>=5.9)

/// Bounded root and child scroll regressions captured automatically by Emerge.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private enum RootViewScrollLayoutPreview {

    static let size = CGSize(width: 580, height: 778)

    static let localizationProvider = LocalizationProvider(
        locale: Locale(identifier: "en_US"),
        localizedStrings: [
            "hero_title": .string("Unlock Pro"),
            "hero_subtitle": .string("Tall hero on root z-layer layout."),
            "footer_copy": .string("Subscribe for $79.99/yr"),
            "footer_cta": .string("Continue"),
            "footer_restore": .string("Restore Purchases"),
            "small_body_title": .string("Unlock everything")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    private static let fixtureBackground: PaywallComponent.Background = .color(.init(light: .hex("#FDFDFD")))

    static let offering = Offering(
        identifier: "scroll-layout-preview",
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

    /// Root stack is a z-layer (not a vertical stack wrapping a z-layer) with tall hero + sticky footer.
    static func makeStickyFooterRootZLayerViewModel(
        overflow: PaywallComponent.StackComponent.Overflow? = nil,
        footerIsZLayer: Bool = false,
        rootChangesToZLayerByWidthRule: Bool = false
    ) throws -> RootViewModel {
        let rootZLayer = PaywallComponent.StackComponent(
            components: [
                .image(.init(
                    source: .init(light: .init(
                        width: 899,
                        height: 1134,
                        original: Self.heroImageURL,
                        heic: Self.heroImageURL,
                        heicLowRes: Self.heroImageURL
                    )),
                    size: .init(width: .fill, height: .fit(nil)),
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
                )),
                .text(.init(
                    text: "hero_subtitle",
                    color: .init(light: .hex("#666666")),
                    padding: .zero,
                    margin: .init(top: 16, bottom: 24, leading: 24, trailing: 24),
                    fontSize: 14,
                    horizontalAlignment: .center
                ))
            ],
            dimension: rootChangesToZLayerByWidthRule ? .vertical(.center, .start) : .zlayer(.top),
            size: .init(width: .fill, height: .fit(nil)),
            spacing: 0,
            backgroundColor: .init(light: .hex("#FFFFFF")),
            overflow: overflow,
            overrides: rootChangesToZLayerByWidthRule ? [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 500)],
                properties: .init(dimension: .zlayer(.top))
            )] : nil
        )

        return try makeRootViewModel(
            componentsConfig: .init(
                stack: rootZLayer,
                stickyFooter: .init(stack: footerIsZLayer ? .init(
                    components: [.stack(standardOpaqueFooterStack())],
                    dimension: .zlayer(.center),
                    size: .init(width: .fill, height: .fit(nil))
                ) : standardOpaqueFooterStack()),
                background: .color(.init(light: .hex("#FFFFFF")))
            )
        )
    }

    /// The root does not scroll, but its bounded child must still expose the bottom of its content.
    static func makeNonScrollingRootWithZLayerChildViewModel(
        childOverflow: PaywallComponent.StackComponent.Overflow? = .scroll
    ) throws -> RootViewModel {
        let content = PaywallComponent.StackComponent(
            components: [
                .stack(.init(
                    components: [],
                    size: .init(width: .fill, height: .fixed(600)),
                    backgroundColor: .init(light: .hex("#E3F2FD"))
                )),
                .text(.init(
                    text: "small_body_title",
                    color: .init(light: .hex("#272727")),
                    backgroundColor: .init(light: .hex("#FFE082")),
                    size: .init(width: .fill, height: .fixed(60)),
                    fontSize: 22
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fit(nil)),
            overflow: .default
        )
        let child = PaywallComponent.StackComponent(
            components: [.stack(content)],
            dimension: .zlayer(.top),
            size: .init(width: .fill, height: .fill),
            overflow: childOverflow
        )
        let root = PaywallComponent.StackComponent(
            components: [.stack(child)],
            dimension: .zlayer(.top),
            size: .init(width: .fill, height: .fixed(300)),
            overflow: .default
        )

        return try makeRootViewModel(
            componentsConfig: .init(stack: root, stickyFooter: nil, background: fixtureBackground)
        )
    }

    /// Matches scroll_test_1's unfolded window rule and both columns' scrolling overrides.
    static func makeCenteredColumnsViewModel(tallFitOffer: Bool = false) throws -> RootViewModel {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .windowHeight(operator: .greaterThanOrEqual, value: 600),
            .windowHeight(operator: .lessThan, value: 700),
            .windowAspectRatio(operator: .greaterThanOrEqual, value: 1)
        ]
        let scrollOverride = PaywallComponent.ComponentOverride(
            extendedConditions: conditions,
            properties: PaywallComponent.PartialStackComponent(overflow: .scroll)
        )
        let story = PaywallComponent.StackComponent(
            components: [.stack(.init(
                components: [],
                size: .init(width: .fill, height: .fixed(1000)),
                backgroundColor: .init(light: .hex("#E3F2FD"))
            ))],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill),
            overrides: [scrollOverride]
        )
        let offerBody: [PaywallComponent] = tallFitOffer ? [.stack(.init(
            components: [],
            size: .init(width: .fill, height: .fixed(900)),
            backgroundColor: .init(light: .hex("#FFE0B2"))
        ))] : []
        let offer = PaywallComponent.StackComponent(
            components: offerBody + [.text(.init(
                text: "small_body_title",
                color: .init(light: .hex("#272727")),
                backgroundColor: .init(light: .hex("#FFE082")),
                size: .init(width: .fill, height: .fixed(100)),
                fontSize: 22
            ))],
            dimension: .vertical(.center, .center),
            size: .init(width: .fill, height: .fit(nil)),
            overrides: [scrollOverride]
        )
        let root = PaywallComponent.StackComponent(
            components: [.stack(story), .stack(offer)],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill),
            spacing: 32,
            padding: .init(top: 16, bottom: 24, leading: 0, trailing: 0),
            overrides: [.init(
                extendedConditions: conditions,
                properties: .init(dimension: .horizontal(.center, .start), overflow: .default)
            )]
        )
        return try makeRootViewModel(
            componentsConfig: .init(stack: root, stickyFooter: nil, background: fixtureBackground)
        )
    }

    private static func footerCTAText() -> PaywallComponent {
        .text(.init(
            text: "footer_cta",
            fontWeight: .semibold,
            color: .init(light: .hex("#FFFFFF")),
            backgroundColor: .init(light: .hex("#111111")),
            padding: .init(top: 14, bottom: 14, leading: 16, trailing: 16),
            margin: .zero,
            fontSize: 16,
            horizontalAlignment: .center
        ))
    }

    private static func standardOpaqueFooterStack() -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(
            components: [
                .text(.init(
                    text: "footer_copy",
                    color: .init(light: .hex("#666666")),
                    padding: .zero,
                    margin: .zero,
                    fontSize: 14,
                    horizontalAlignment: .center
                )),
                footerCTAText(),
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
            size: .init(width: .fill, height: .fit(nil)),
            spacing: 12,
            backgroundColor: .init(light: .hex("#FFFFFF")),
            padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16)
        )
    }

    private static let heroImageURL: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("root-scroll-preview-hero.png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let data = Data(base64Encoded: [
                "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQ",
                "z0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC"
            ].joined())!
            try? data.write(to: url, options: .atomic)
        }
        return url
    }()

    @MainActor
    static func preview(
        overflow: PaywallComponent.StackComponent.Overflow? = nil,
        footerIsZLayer: Bool = false,
        rootChangesToZLayerByWidthRule: Bool = false,
        childOverflow: PaywallComponent.StackComponent.Overflow? = .scroll,
        includesChild: Bool = false,
        scrollToBottom: Bool = true,
        includesCenteredColumns: Bool = false,
        tallFitOffer: Bool = false
    ) -> some View {
        let size = includesCenteredColumns ? CGSize(width: 800, height: 650) : Self.size
        let viewModel: RootViewModel
        do {
            if includesCenteredColumns {
                viewModel = try makeCenteredColumnsViewModel(tallFitOffer: tallFitOffer)
            } else {
                viewModel = try includesChild
                    ? makeNonScrollingRootWithZLayerChildViewModel(childOverflow: childOverflow)
                    : makeStickyFooterRootZLayerViewModel(
                        overflow: overflow,
                        footerIsZLayer: footerIsZLayer,
                        rootChangesToZLayerByWidthRule: rootChangesToZLayerByWidthRule
                    )
            }
        } catch {
            fatalError("Invalid root scroll preview configuration: \(error)")
        }

        return RootView(viewModel: viewModel, onDismiss: {}, defaultPackage: nil)
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: .producing(eligibility: .eligible)
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0))
            .environment(\.isRunningSnapshots, true)
            .environment(\.colorScheme, .light)
            .applyIf(rootChangesToZLayerByWidthRule || includesCenteredColumns) {
                $0.environment(\.paywallWindowSize, size)
            }
            .frame(width: size.width, height: size.height)
            .applyIf(scrollToBottom) { $0.defaultScrollAnchor(.bottom) }
            .emergeExpansion(false)
            .previewLayout(.fixed(width: size.width, height: size.height))
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
struct RootViewScrollLayoutPreview_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            RootViewScrollLayoutPreview.preview(scrollToBottom: false, includesCenteredColumns: true)
                .previewDisplayName("Unfolded window: FIT offer centers beside scrolling story")
            RootViewScrollLayoutPreview.preview(includesCenteredColumns: true, tallFitOffer: true)
                .previewDisplayName("Unfolded window: tall FIT offer scrolls to bottom marker")
            RootViewScrollLayoutPreview.preview(footerIsZLayer: true, scrollToBottom: false)
                .previewDisplayName("Root z-layer: legacy z-layer footer")
            RootViewScrollLayoutPreview.preview(overflow: .default)
                .previewDisplayName("Root z-layer: explicit no scroll")
            RootViewScrollLayoutPreview.preview(includesChild: true)
                .previewDisplayName("Root no scroll: child explicit scroll")
            RootViewScrollLayoutPreview.preview(childOverflow: nil, includesChild: true)
                .previewDisplayName("Root no scroll: child default does not scroll")
            RootViewScrollLayoutPreview.preview(rootChangesToZLayerByWidthRule: true)
                .previewDisplayName("Width rule: z-layer root retains default scroll")
        }
    }

}

#endif
#endif
