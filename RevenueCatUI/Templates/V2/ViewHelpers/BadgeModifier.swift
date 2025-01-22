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
        let stackBorder: ShapeModifier.BorderInfo?
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
                        computeValue: { dim in
                            dim[VerticalAlignment.center] + effetiveYTranslationForOverlaidBadge(badge: badge)
                        })
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
            .applyIfLet(badge.stackShape?.toInsettableShape()) { view, shape in
                view.clipShape(shape)
            }
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
                            .frame(maxWidth: .infinity)
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
                            .frame(maxWidth: .infinity)
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
            .applyIfLet(badge.stackShape?.toInsettableShape()) { view, shape in
                view.clipShape(shape)
            }
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

    // Helper to calculate the position of an overlaid badge to place it at the center of the parent stack's border
    private func effetiveYTranslationForOverlaidBadge(badge: BadgeModifier.BadgeInfo) -> CGFloat {
        return switch badge.alignment {
        case .top, .topLeading, .topTrailing:
            -(badge.stackBorder?.width ?? 0)/2
        case .bottom, .bottomLeading, .bottomTrailing:
            +(badge.stackBorder?.width ?? 0)/2
        default:
            0
        }
    }

    // Helper to calculate the effective margins of a badge depending on its type:
    // - Edge-to-ege: No margin allowed.
    // - Overlaid: Only leading/trailing margins allowed if in the leading/trailing positions respectively.
    // - Nested: Margin only allowed in the sides adjacent to the stack borders. Also the
    //  margin will include the stack border.
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
            let borderWidth = badge.stackBorder?.width ?? 0
            switch badge.alignment {
            case .center, .leading, .trailing:
                return .zero
            case .top:
                return .init(top: (badge.stack.value.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: 0, trailing: 0)
            case .bottom:
                return .init(top: 0, bottom: (badge.stack.value.margin.bottom ?? 0) + borderWidth,
                             leading: 0, trailing: 0)
            case .topLeading:
                return .init(top: (badge.stack.value.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: (badge.stack.value.margin.leading ?? 0) + borderWidth, trailing: 0)
            case .topTrailing:
                return .init(top: (badge.stack.value.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: 0, trailing: (badge.stack.value.margin.trailing ?? 0) + borderWidth)
            case .bottomLeading:
                return .init(top: 0, bottom: (badge.stack.value.margin.bottom ?? 0) + borderWidth,
                             leading: (badge.stack.value.margin.leading ?? 0) + borderWidth, trailing: 0)
            case .bottomTrailing:
                return .init(top: 0, bottom: (badge.stack.value.margin.bottom ?? 0) + borderWidth,
                             leading: 0, trailing: (badge.stack.value.margin.trailing ?? 0) + borderWidth)
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
                        topLeft: radiusInfo(shape: badge.stackShape).topLeft,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: corners?.bottomTrailing))
                case .topTrailing:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: radiusInfo(shape: badge.stackShape).topRight,
                        bottomLeft: corners?.bottomLeading,
                        bottomRight: 0))
                case .bottomLeading:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: corners?.topTrailing,
                        bottomLeft: radiusInfo(shape: badge.stackShape).bottomLeft,
                        bottomRight: 0))
                case .bottomTrailing:
                    return .rectangle(.init(
                        topLeft: corners?.topLeading,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: radiusInfo(shape: badge.stackShape).bottomRight))
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
    private func radiusInfo(shape: ShapeModifier.Shape?) -> ShapeModifier.RadiusInfo {
        switch shape {
        case .rectangle(let radius):
            return radius ?? .init(topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0)
        default:
            return .init(topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0)
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
    StackComponentView(
        // swiftlint:disable:next force_try
        viewModel: try! StackComponentViewModel(
            component: PaywallComponent.StackComponent(
                components: [
                    .text(PaywallComponent.TextComponent(
                        text: "text_1",
                        color: .init(light: .hex("#000000")),
                        size: .init(width: .fit, height: .fit),
                        margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                    ))
                ],
                dimension: .horizontal(),
                size: .init(width: .fill, height: .fixed(150)),
                spacing: 10,
                backgroundColor: .init(light: .hex("#ffffff")),
                padding: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12)),
                border: .init(color: .init(light: .hex("#0000FF")), width: 10),
                shadow:.init(color: .init(light: .hex("#00000030")), radius: 4, x: 0, y: 0),
                badge: .init(
                    style: style,
                    alignment: alignment,
                    stack: .init(PaywallComponent.StackComponent(
                        components: [
                            .text(PaywallComponent.TextComponent(
                                text: "text_2",
                                color: .init(light: .hex("#000000")),
                                size: .init(width: .fit, height: .fit),
                                margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                            ))
                        ],
                        dimension: .horizontal(),
                        size: .init(width: .fill, height: .fixed(150)),
                        spacing: 10,
                        backgroundColor: .init(light: .hex("#ff0000")),
                        padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                        margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                        shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12))
                    ))
                )
            ),
            localizationProvider: .init(
                locale: Locale.current,
                localizedStrings: [
                    "text_1": .string("Feature 1\nFeature 2\nFeature 3\nFeature 4"),
                    "text_2": .string("Special Discount\nSave 50%")
                ]
            )
        ),
        onDismiss: {}
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
