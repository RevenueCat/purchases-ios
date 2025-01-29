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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TimelineComponentView: View {
    private let viewModel: TimelineComponentViewModel

    @Environment(\.colorScheme)
    private var colorScheme

    internal init(viewModel: TimelineComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: viewModel.component.itemSpacing ?? 0) {
            ForEach(viewModel.items, id: \.component) { item in
                timelineRow(item: item)
            }
        }
        // Add `itemSpacing` padding to the bottom of the timeline so the last connector can extend
        // a little beyond the description text of the last item.
        .padding(.bottom, viewModel.component.itemSpacing ?? 0)
        .backgroundPreferenceValue(ItemBoundsKey.self) { bounds in
            GeometryReader { proxy in
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                    let next = viewModel.items.indices.contains(index + 1) ? viewModel.items[index + 1] : nil
                    // swiftlint:disable identifier_name
                    if let from = bounds[item.id], let next, let to = bounds[next.id] {
                        // Connect two items from center to center respecting margins
                        if let connector = item.component.connector {
                            let color = connector.color.asDisplayable(uiConfigProvider: viewModel.uiConfigProvider)
                            Rectangle()
                                .fillColorScheme(color, colorScheme: colorScheme)
                                .frame(
                                    width: connector.width,
                                    height: proxy[to][.center].y - proxy[from][.center].y -
                                    (item.component.connector?.margin.bottom ?? 0) -
                                    (item.component.connector?.margin.top ?? 0)
                                )
                                .offset(
                                    x: proxy[from][.bottom].x - connector.width / 2,
                                    y: proxy[from][.center].y + (item.component.connector?.margin.top ?? 0)
                                )
                        }
                    } else if let from = bounds[item.id] {
                        // The last connector goes from the center of the last icon to the bottom of component
                        // (including `itemSpacing` padding and respecting margins)
                        if let connector = item.component.connector {
                            let color = connector.color.asDisplayable(uiConfigProvider: viewModel.uiConfigProvider)
                            Rectangle()
                                .fillColorScheme(color, colorScheme: colorScheme)
                                .frame(
                                    width: connector.width,
                                    height: proxy.size.height - proxy[from][.center].y -
                                    (item.component.connector?.margin.bottom ?? 0) -
                                    (item.component.connector?.margin.top ?? 0)
                                )
                                .offset(
                                    x: proxy[from][.bottom].x - connector.width / 2,
                                    y: proxy[from][.center].y + (item.component.connector?.margin.top ?? 0)
                                )
                        }
                    }
                }
            }
        }
        .padding(viewModel.component.margin.edgeInsets)
        .size(viewModel.component.size, horizontalAlignment: .leading, verticalAlignment: .top)
        .clipped()
    }

    @ViewBuilder
    func timelineRow(
        item: TimelineItemViewModel
    ) -> some View {
        HStack(alignment: .centerIcon, spacing: viewModel.component.columnGutter ?? 0) {
            VStack(spacing: 0) {
                IconComponentView(viewModel: item.icon)
                    // Store the bounds of the icon so we can later use them to position the connectors
                    .anchorPreference(key: ItemBoundsKey.self, value: .bounds, transform: { [item.id: $0 ]})
                    .alignmentGuide(.centerIcon) { dim in dim[VerticalAlignment.center] }
            }

            VStack(alignment: .leading, spacing: viewModel.component.textSpacing ?? 0) {
                TextComponentView(viewModel: item.title)
                    .applyIf(viewModel.component.iconAlignment == .title) { view in
                        view.alignmentGuide(.centerIcon) { dim in dim[VerticalAlignment.center] }
                    }
                if let description = item.description {
                    TextComponentView(viewModel: description)
                }
            }
            .applyIf(viewModel.component.iconAlignment == .titleAndDescription) { view in
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

    static func iconComponent(name: String, color: String) -> PaywallComponent.IconComponent {
        return .init(
            baseUrl: "https://icons.pawwalls.com/icons",
            iconName: name,
            formats: .init(
                svg: "\(name).svg",
                png: "\(name).png",
                heic: "\(name).heic",
                webp: "\(name).webp"
            ),
            size: .init(width: .fixed(32), height: .fixed(32)),
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
            )
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
            )
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
            icon: iconComponent(name: "star", color: "#11D483"),
            connector: .init(
                width: 8,
                color: .init(
                    light: .linear(180, [
                        .init(color: "#11D483", percent: 0),
                        .init(color: "#FFFFFF", percent: 70)
                    ])
                ),
                margin: .init(top: 14, bottom: 0, leading: 0, trailing: 0)
            )
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
                    items: items
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
            .previewRequiredEnvironmentProperties()
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
                icon: try IconComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: item.icon
                )
            )
        }

        try self.init(
            component: component,
            items: models,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif

#endif
