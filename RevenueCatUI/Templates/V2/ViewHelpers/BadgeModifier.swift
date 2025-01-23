//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BadgeModifier.swift
//
//  Created by Mark Villacampa 09/12/2024.

// swiftlint:disable file_length

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeModifier: ViewModifier {

    let badge: BadgeInfo?

    struct BadgeInfo {
        let style: PaywallComponent.BadgeStyle
        let alignment: PaywallComponent.TwoDimensionAlignment
        let stack: PaywallComponent.CodableBox<PaywallComponent.StackComponent>
        let badgeViewModels: [PaywallComponentViewModel]
        let stackShape: ShapeModifier.Shape?
        let uiConfigProvider: UIConfigProvider

        var backgroundStyle: BackgroundStyle? {
            stack.value.backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        }
    }

    func body(content: Content) -> some View {
        if let badge = badge {
            content.apply(badge: badge)
        } else {
            content
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {

    @ViewBuilder
    func apply(badge: BadgeModifier.BadgeInfo) -> some View {
        switch badge.style {
        case .edgeToEdge:
            self.applyBadgeEdgeToEdge(badge: badge)
        case .overlaid:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: nil, shape: effectiveShape(badge: badge))
                    }
                    .fixedSize()
                    .padding(effectiveMargin(badge: badge).edgeInsets)
                    .alignmentGuide(
                        effetiveVerticalAlinmentForOverlaidBadge(alignment: badge.alignment.stackAlignment),
                        computeValue: { dim in dim[VerticalAlignment.center] })
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
        case .nested:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: nil, shape: effectiveShape(badge: badge))
                    }

                    .fixedSize()
                    .padding(effectiveMargin(badge: badge).edgeInsets)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
        }
    }

    // Helper to apply the edge-to-edge badge style
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func applyBadgeEdgeToEdge(badge: BadgeModifier.BadgeInfo) -> some View {
        switch badge.alignment {
        case .bottom:
            self.background(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: nil, shape: effectiveShape(badge: badge))
                    }
                    .alignmentGuide(.bottom) { dim in dim[VerticalAlignment.top] }
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
            .background(
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                    Rectangle()
                        .fill(Color.clear)
                        .backgroundStyle(badge.backgroundStyle)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .top:
            self.background(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: nil, shape: effectiveShape(badge: badge))
                    }
                    .alignmentGuide(.top) { dim in dim[VerticalAlignment.bottom] }
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
            .background(
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .backgroundStyle(badge.backgroundStyle)
                    Rectangle()
                        .fill(Color.clear)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .bottomLeading, .bottomTrailing, .topLeading, .topTrailing:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: nil, shape: effectiveShape(badge: badge))
                    }
                    .fixedSize()
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
        default:
            self
        }
    }

    // Helper to calculate the position of an overlaid badge at the top or bottom of the stack
    private func effetiveVerticalAlinmentForOverlaidBadge(alignment: Alignment) -> VerticalAlignment {
        switch alignment {
        case .top, .topLeading, .topTrailing:
            return VerticalAlignment.top
        case .bottom, .bottomLeading, .bottomTrailing:
            return VerticalAlignment.bottom
        default:
            return VerticalAlignment.top
        }
    }

    // Helper to calculate the effective margins of a badge depending on its type:
    // - Edge-to-ege: No margin allowed.
    // - Overlaid: Only leading/trailing margins allowed if in the leading/trailing positions respectively.
    // - Nested: Margin only allowed in the sides adjacent to the stack borders.
    // swiftlint:disable:next cyclomatic_complexity
    private func effectiveMargin(badge: BadgeModifier.BadgeInfo) -> PaywallComponent.Padding {
        switch badge.style {
        case .edgeToEdge:
            return .zero
        case .overlaid:
            switch badge.alignment {
            case .top, .bottom, .center:
                return .zero
            case .leading, .topLeading, .bottomLeading:
                return .init(top: 0, bottom: 0, leading: badge.stack.value.margin.leading, trailing: 0)
            case .trailing, .topTrailing, .bottomTrailing:
                return .init(top: 0, bottom: 0, leading: 0, trailing: badge.stack.value.margin.trailing)
            }
        case .nested:
            switch badge.alignment {
            case .center, .leading, .trailing:
                return .zero
            case .top:
                return .init(top: badge.stack.value.margin.top, bottom: 0, leading: 0, trailing: 0)
            case .bottom:
                return .init(top: 0, bottom: badge.stack.value.margin.bottom, leading: 0, trailing: 0)
            case .topLeading:
                return .init(top: badge.stack.value.margin.top, bottom: 0,
                             leading: badge.stack.value.margin.leading, trailing: 0)
            case .topTrailing:
                return .init(top: badge.stack.value.margin.top, bottom: 0,
                             leading: 0, trailing: badge.stack.value.margin.trailing)
            case .bottomLeading:
                return .init(top: 0, bottom: badge.stack.value.margin.bottom,
                             leading: badge.stack.value.margin.leading, trailing: 0)
            case .bottomTrailing:
                return .init(top: 0, bottom: badge.stack.value.margin.bottom,
                             leading: 0, trailing: badge.stack.value.margin.trailing)
            }
        }
    }

    // Helper to calculate the shape of the edge-to-edge badge in trailing/leading positions.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func effectiveShape(badge: BadgeModifier.BadgeInfo) -> ShapeModifier.Shape? {
        switch badge.style {
        case .edgeToEdge:
            switch badge.stack.value.shape {
            case .pill, .none:
                // Edge-to-edge badge cannot have pill shape
                return nil
            case .rectangle(let corners):
                switch badge.alignment {
                case .center, .leading, .trailing:
                    return nil
                case .top:
                    return .rectangle(.init(
                        topLeft: corners?.topLeading,
                        topRight: corners?.topTrailing,
                        bottomLeft: 0,
                        bottomRight: 0))
                case .bottom:
                    return .rectangle(.init(
                        topLeft: 0,
                        topRight: 0,
                        bottomLeft: corners?.bottomLeading,
                        bottomRight: corners?.bottomTrailing))
                case .topLeading:
                    return .rectangle(.init(
                        topLeft: radiusInfo(shape: badge.stackShape)?.topLeft,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: corners?.bottomTrailing))
                case .topTrailing:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: radiusInfo(shape: badge.stackShape)?.topRight,
                        bottomLeft: corners?.bottomLeading,
                        bottomRight: 0))
                case .bottomLeading:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: corners?.topTrailing,
                        bottomLeft: radiusInfo(shape: badge.stackShape)?.bottomLeft,
                        bottomRight: 0))
                case .bottomTrailing:
                    return .rectangle(.init(
                        topLeft: corners?.topLeading,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: radiusInfo(shape: badge.stackShape)?.bottomRight))
                }
            }
        case .nested, .overlaid:
            switch badge.stack.value.shape {
            case .rectangle(let radius):
                return .rectangle(.init(topLeft: radius?.topLeading,
                                        topRight: radius?.topTrailing,
                                        bottomLeft: radius?.bottomLeading,
                                        bottomRight: radius?.bottomTrailing))
            case .pill:
                return .pill
            case .none:
                return nil
            }
        }
    }

    // Helper to extract the RadiusInfo from a rectanle shape
    private func radiusInfo(shape: ShapeModifier.Shape?) -> ShapeModifier.RadiusInfo? {
        switch shape {
        case .rectangle(let radius):
            return radius
        default:
            return nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func stackBadge(_ badge: BadgeModifier.BadgeInfo?) -> some View {
        self.modifier(BadgeModifier(badge: badge))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@ViewBuilder
// swiftlint:disable:next function_body_length
private func badge(style: PaywallComponent.BadgeStyle, alignment: PaywallComponent.TwoDimensionAlignment) -> some View {
    VStack(spacing: 16) {
        Text("Standard")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.black)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Feature 1")
                    .foregroundColor(.black)
            }
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Feature 2")
                    .foregroundColor(.black)
            }
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Feature 3")
                    .foregroundColor(.black)
            }
        }

        Text("$9.99/month")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.black)

        Text("Includes 7 Day Free Trial")
            .font(.caption)
            .foregroundColor(.gray)

        Text("Continue")
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

    }
    .padding()
    .padding(.vertical, 34)
    .backgroundStyle(.color(.init(light: .hex("#ffffff"))).backgroundStyle)
    .shape(
        border: .init(color: .blue, width: 10),
        shape: .rectangle(ShapeModifier.RadiusInfo(topLeft: 12.0, topRight: 12, bottomLeft: 12, bottomRight: 12))
    )
    .compositingGroup()
    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
    .stackBadge(
        BadgeModifier.BadgeInfo(
            style: style,
            alignment: alignment,
            stack: PaywallComponent.CodableBox(PaywallComponent.StackComponent(
                components: [
                    PaywallComponent.text(
                        PaywallComponent.TextComponent(
                            text: "id_1",
                            fontName: nil,
                            fontWeight: .bold,
                            color: .init(light: .hex("#000000")),
                            padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                            margin: .zero,
                            fontSize: 13,
                            horizontalAlignment: .center
                        )
                    )
                ],
                backgroundColor: .init(light: .hex("#FA8072")),
                padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                shape: .rectangle(.init(topLeading: 8.0, topTrailing: 8, bottomLeading: 8, bottomTrailing: 8))
            )), badgeViewModels: [
                .text(
                    // swiftlint:disable:next force_try
                    try! TextComponentViewModel(
                        localizationProvider: .init(
                            locale: Locale.current,
                            localizedStrings: [
                                "id_1": .string("Special Discount\nSave 50%")
                            ]
                        ),
                        uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                        component: PaywallComponent.TextComponent(
                            text: "id_1",
                            fontName: nil,
                            fontWeight: .bold,
                            color: .init(light: .hex("#000000")),
                            padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                            margin: .zero,
                            fontSize: 13,
                            horizontalAlignment: .center
                        )
                    )
                )
            ],
            stackShape: .rectangle(.init(topLeft: 12.0, topRight: 12.0, bottomLeft: 12.0, bottomRight: 12.0)),
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
        )
    )
}

// As of Xcode 16, there is a limit of 15 views per PreviewProvider.
// To work around this, we can create multiple PreviewProviders with different sets of previews.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeEdgeToEdge_Previews: PreviewProvider {

    static var previews: some View {
        let alignments: [PaywallComponent.TwoDimensionAlignment] = [
            .topLeading, .top, .topTrailing, .bottomLeading, .bottom, .bottomTrailing
        ]
        ForEach(alignments, id: \.self) { alignment in
            badge(style: .edgeToEdge, alignment: alignment)
                .previewDisplayName("edgeToEdge - \(alignment)")
        }
        .previewLayout(.sizeThatFits)
        .padding(30)
        .padding(.vertical, 50)
        .previewRequiredEnvironmentProperties()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeOverlaid_Previews: PreviewProvider {

    static var previews: some View {
        let alignments: [PaywallComponent.TwoDimensionAlignment] = [
            .topLeading, .top, .topTrailing, .bottomLeading, .bottom, .bottomTrailing
        ]
        ForEach(alignments, id: \.self) { alignment in
            badge(style: .overlaid, alignment: alignment)
                .previewDisplayName("overlaid - \(alignment)")
        }
        .previewLayout(.sizeThatFits)
        .padding(30)
        .padding(.vertical, 50)
        .previewRequiredEnvironmentProperties()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeNested_Previews: PreviewProvider {

    static var previews: some View {
        let alignments: [PaywallComponent.TwoDimensionAlignment] = [
            .topLeading, .top, .topTrailing, .bottomLeading, .bottom, .bottomTrailing
        ]
        ForEach(alignments, id: \.self) { alignment in
            badge(style: .nested, alignment: alignment)
                .previewDisplayName("nested - \(alignment)")
        }
        .previewLayout(.sizeThatFits)
        .padding(30)
        .padding(.vertical, 50)
        .previewRequiredEnvironmentProperties()
    }

}

#endif
