//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimelineComponentView.swift
//
//  Created by Mark Villacampa on 15/1/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TimelineComponentView: View {

    private let viewModel: TimelineComponentViewModel

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.colorScheme)
    private var colorScheme

    internal init(viewModel: TimelineComponentViewModel) {
        self.viewModel = viewModel
    }

    @State private var maxIconWidth: CGFloat = 0

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            )
        ) { style in
            if style.visible {
                timeline(style: style)
            }
        }
    }

    @ViewBuilder
    private func timeline(
        style: TimelineComponentStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: style.itemSpacing ?? 0) {
            ForEach(viewModel.items, id: \.component) { item in
                item.styles(
                    state: self.componentViewState,
                    condition: self.screenCondition,
                    isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                        package: self.packageContext.package
                    ),
                    isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                        for: self.packageContext.package
                    )
                ) { itemStyle in
                    if itemStyle.visible {
                        timelineRow(itemStyle: itemStyle, style: style)
                    }
                }
            }
        }
        .onPreferenceChange(MaxIconWidthPreferenceKey.self) { width in
            self.maxIconWidth = width
        }
        // Add `itemSpacing` padding to the bottom of the timeline so the last connector can extend
        // a little beyond the description text of the last item.
        .padding(.bottom, style.itemSpacing ?? 0)
        .backgroundPreferenceValue(ItemBoundsKey.self) { bounds in
            GeometryReader { proxy in
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                    item.styles(
                        state: self.componentViewState,
                        condition: self.screenCondition,
                        isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                            package: self.packageContext.package
                        ),
                        isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                            for: self.packageContext.package
                        )
                    ) { itemStyle in
                        if itemStyle.visible {
                            let next = viewModel.items.indices.contains(index + 1) ? viewModel.items[index + 1] : nil
                            // swiftlint:disable identifier_name
                            if let from = bounds[itemStyle.id], let next, let to = bounds[next.id] {
                                // Connect two items from center to center respecting margins
                                if let connector = itemStyle.connector {
                                    let color = connector.color.asDisplayable(
                                        uiConfigProvider: viewModel.uiConfigProvider
                                    )
                                    Rectangle()
                                        .fillColorScheme(color, colorScheme: colorScheme)
                                        .frame(
                                            width: connector.width,
                                            height: proxy[to][.center].y - proxy[from][.center].y -
                                            (connector.margin.bottom ?? 0) -
                                            (connector.margin.top ?? 0)
                                        )
                                        .offset(
                                            x: proxy[from][.bottom].x - connector.width / 2,
                                            y: proxy[from][.center].y + (connector.margin.top ?? 0)
                                        )
                                }
                            } else if let from = bounds[itemStyle.id] {
                                // The last connector goes from the center of the last icon to the bottom of component
                                // (including `itemSpacing` padding and respecting margins)
                                if let connector = itemStyle.connector {
                                    let color = connector.color.asDisplayable(
                                        uiConfigProvider: viewModel.uiConfigProvider
                                    )
                                    Rectangle()
                                        .fillColorScheme(color, colorScheme: colorScheme)
                                        .frame(
                                            width: connector.width,
                                            height: proxy.size.height - proxy[from][.center].y -
                                            (connector.margin.bottom ?? 0) -
                                            (connector.margin.top ?? 0)
                                        )
                                        .offset(
                                            x: proxy[from][.bottom].x - connector.width / 2,
                                            y: proxy[from][.center].y + (connector.margin.top ?? 0)
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(style.margin)
        .size(style.size, horizontalAlignment: .leading, verticalAlignment: .top)
        .clipped()
    }

    @ViewBuilder
    private func timelineRow(
        itemStyle: TimelineItemStyle,
        style: TimelineComponentStyle
    ) -> some View {
        HStack(alignment: .centerIcon, spacing: style.columnGutter ?? 0) {
            VStack(spacing: 0) {
                IconComponentView(viewModel: itemStyle.icon)
                    // Store the bounds of the icon so we can later use them to position the connectors
                    .anchorPreference(key: ItemBoundsKey.self, value: .bounds, transform: { [itemStyle.id: $0 ]})
                    .alignmentGuide(.centerIcon) { dim in dim[VerticalAlignment.center] }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(
                            key: MaxIconWidthPreferenceKey.self,
                            value: geometry.size.width
                        )
                    })
            }
            .frame(width: maxIconWidth > 0 ? maxIconWidth : nil)
            VStack(alignment: .leading, spacing: style.textSpacing ?? 0) {
                TextComponentView(viewModel: itemStyle.title)
                    .applyIf(style.iconAlignment == .title) { view in
                        view.alignmentGuide(.centerIcon) { dim in dim[VerticalAlignment.center] }
                    }
                if let description = itemStyle.description {
                    TextComponentView(viewModel: description)
                }
            }
            .applyIf(style.iconAlignment == .titleAndDescription) { view in
                view.alignmentGuide(.centerIcon) { dim in dim[VerticalAlignment.center] }
            }
        }
    }

}

private extension VerticalAlignment {
    enum CenterIcon: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.bottom]
        }
    }

    static let centerIcon = VerticalAlignment(CenterIcon.self)
}

private struct ItemBoundsKey: PreferenceKey {
    static let defaultValue: [UUID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct MaxIconWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension CGRect {
    subscript(unitPoint: UnitPoint) -> CGPoint {
        CGPoint(x: minX + width * unitPoint.x, y: minY + height * unitPoint.y)
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ContentView_Previews: PreviewProvider {

    static func textComponent(text: String) -> PaywallComponent.TextComponent {
        .init(
            text: text,
            color: .init(light: .hex("#000000")),
            size: .init(width: .fit, height: .fit),
            horizontalAlignment: .leading
        )
    }

    static func iconComponent(
        name: String,
        color: String,
        size: PaywallComponent.Size = .init(width: .fixed(32), height: .fixed(32))
    ) -> PaywallComponent.IconComponent {
        return .init(
            baseUrl: "https://icons.pawwalls.com/icons",
            iconName: name,
            formats: .init(
                svg: "\(name).svg",
                png: "\(name).png",
                heic: "\(name).heic",
                webp: "\(name).webp"
            ),
            size: size,
            padding: .init(top: 5, bottom: 5, leading: 5, trailing: 5),
            margin: .zero,
            color: PaywallComponent.ColorScheme(
                light: .hex("#ffffff")
            ),
            iconBackground: PaywallComponent.IconComponent.IconBackground(
                color: .init(light: .hex(color)),
                shape: .circle,
                border: nil,
                shadow: nil
            )
        )
    }

    static let items: [PaywallComponent.TimelineComponent.Item] = [
        PaywallComponent.TimelineComponent.Item(
            title: .init(
                text: "id_1",
                fontWeight: .bold,
                color: .init(light: .hex("#000000")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            description: .init(
                text: "id_2",
                fontWeight: .light,
                color: .init(light: .hex("#616161")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            icon: iconComponent(name: "lock", color: "#576CDB"),
            connector: .init(
                width: 8,
                color: .init(light: .hex("#576CDB66")),
                margin: .init(top: 14, bottom: 14, leading: 0, trailing: 0)
            ),
            overrides: nil
        ),
        PaywallComponent.TimelineComponent.Item(
            title: .init(
                text: "id_3",
                fontWeight: .bold,
                color: .init(light: .hex("#000000")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            description: .init(
                text: "id_4",
                fontWeight: .light,
                color: .init(light: .hex("#616161")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            icon: iconComponent(name: "bell", color: "#576CDB"),
            connector: .init(
                width: 8,
                color: .init(light: .hex("#576CDB66")),
                margin: .init(top: 14, bottom: 14, leading: 0, trailing: 0)
            ),
            overrides: nil
        ),
        PaywallComponent.TimelineComponent.Item(
            title: .init(
                text: "id_5",
                fontWeight: .bold,
                color: .init(light: .hex("#000000")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            description: .init(
                text: "id_6",
                fontWeight: .light,
                color: .init(light: .hex("#616161")),
                size: .init(width: .fit, height: .fit),
                horizontalAlignment: .leading
            ),
            icon: iconComponent(name: "star", color: "#11D483", size: .init(width: .fixed(50), height: .fixed(50))),
            connector: .init(
                width: 8,
                color: .init(
                    light: .linear(180, [
                        .init(color: "#11D483", percent: 0),
                        .init(color: "#FFFFFF", percent: 70)
                    ])
                ),
                margin: .init(top: 23, bottom: 0, leading: 0, trailing: 0)
            ),
            overrides: nil
        )
    ]

    static var previews: some View {
        let alignments = [PaywallComponent.TimelineComponent.IconAlignment.title, .titleAndDescription]
        ForEach(alignments, id: \.self) { alignment in
            TimelineComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(component: .init(
                    iconAlignment: alignment,
                    itemSpacing: 24,
                    textSpacing: 5,
                    columnGutter: 15,
                    size: .init(width: .fill, height: .fit),
                    padding: .init(top: 5, bottom: 5, leading: 5, trailing: 5),
                    margin: .init(top: 5, bottom: 5, leading: 5, trailing: 5),
                    items: items,
                    overrides: nil
                ), localizationProvider: LocalizationProvider(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Today"),
                        "id_2": .string("Description of what you get today if you subscribe"),
                        "id_3": .string("Day x"),
                        "id_4": .string("We’ll remind you that your trial is ending soon"),
                        "id_5": .string("Day y"),
                        "id_6": .string("You’ll be charged. You can cancel anytime before.")
                    ]
                ), uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
            ))
            .previewRequiredPaywallsV2Properties()
            .previewDisplayName("Timeline - \(alignment)")
        }

    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension TimelineComponentViewModel {

    convenience init(
        component: PaywallComponent.TimelineComponent,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) throws {
        let models = try component.items.map { item in
            var description: TextComponentViewModel?
            if let descriptionComponent = item.description {
                description = try TextComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: descriptionComponent
                )
            }
            return TimelineItemViewModel(
                component: item,
                title: try TextComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: item.title
                ),
                description: description,
                icon: IconComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: item.icon
                )
            )
        }

        self.init(
            component: component,
            items: models,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif

#endif
