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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeModifier: ViewModifier {

    let badge: BadgeInfo?

    struct BadgeInfo {
        let style: PaywallComponent.BadgeStyle
        let alignment: PaywallComponent.TwoDimensionAlignment
        let stack: PaywallComponent.StackComponent
        let badgeViewModels: [PaywallComponentViewModel]
        let stackShape: ShapeModifier.Shape?
        let stackBorder: ShapeModifier.BorderInfo?
        let uiConfigProvider: UIConfigProvider

        var backgroundStyle: BackgroundStyle? {
            stack.background?.asDisplayable(uiConfigProvider: uiConfigProvider)
                ?? stack.backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
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
                            .padding(badge.stack.padding.edgeInsets)
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: badge.stackBorder, shape: effectiveShape(badge: badge))
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
                            .padding(badge.stack.padding.edgeInsets)
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: badge.stackBorder, shape: effectiveShape(badge: badge))
                    }
                    .fixedSize()
                    .padding(effectiveMargin(badge: badge).edgeInsets)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: badge.alignment.stackAlignment)
            )
            .applyIfLet(badge.stackShape?.toInsettableShape()) { view, shape in
                view.clipShape(shape)
            }
        @unknown default:
            self
        }
    }

    // Helper to apply the edge-to-edge badge style
    @ViewBuilder
    private func applyBadgeEdgeToEdge(badge: BadgeModifier.BadgeInfo) -> some View {
        switch badge.alignment {
        case .top, .bottom:
            self.modifier(EdgeToEdgeTopBottomModifier(badge: badge))
        case .bottomLeading, .bottomTrailing, .topLeading, .topTrailing:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                            .padding(badge.stack.padding.edgeInsets)
                            .backgroundStyle(badge.backgroundStyle)
                            .shape(border: badge.stackBorder, shape: effectiveShape(badge: badge))
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
        switch badge.alignment {
        case .top, .topLeading, .topTrailing:
            return -(badge.stackBorder?.width ?? 0)/2
        case .bottom, .bottomLeading, .bottomTrailing:
            return +(badge.stackBorder?.width ?? 0)/2
        default:
            return 0
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
                return .init(top: 0, bottom: 0, leading: badge.stack.margin.leading, trailing: 0)
            case .trailing, .topTrailing, .bottomTrailing:
                return .init(top: 0, bottom: 0, leading: 0, trailing: badge.stack.margin.trailing)
            @unknown default:
                return .zero
            }
        case .nested:
            let borderWidth = badge.stackBorder?.width ?? 0
            switch badge.alignment {
            case .center, .leading, .trailing:
                return .zero
            case .top:
                return .init(top: (badge.stack.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: 0, trailing: 0)
            case .bottom:
                return .init(top: 0, bottom: (badge.stack.margin.bottom ?? 0) + borderWidth,
                             leading: 0, trailing: 0)
            case .topLeading:
                return .init(top: (badge.stack.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: (badge.stack.margin.leading ?? 0) + borderWidth, trailing: 0)
            case .topTrailing:
                return .init(top: (badge.stack.margin.top ?? 0) + borderWidth, bottom: 0,
                             leading: 0, trailing: (badge.stack.margin.trailing ?? 0) + borderWidth)
            case .bottomLeading:
                return .init(top: 0, bottom: (badge.stack.margin.bottom ?? 0) + borderWidth,
                             leading: (badge.stack.margin.leading ?? 0) + borderWidth, trailing: 0)
            case .bottomTrailing:
                return .init(top: 0, bottom: (badge.stack.margin.bottom ?? 0) + borderWidth,
                             leading: 0, trailing: (badge.stack.margin.trailing ?? 0) + borderWidth)
            @unknown default:
                return .zero
            }
        @unknown default:
            return .zero
        }
    }
}

// Helper to calculate the shape of the edge-to-edge badge badge in trailing/leading positions.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next cyclomatic_complexity function_body_length
private func effectiveShape(badge: BadgeModifier.BadgeInfo, pillStackRadius: Double? = 0) -> ShapeModifier.Shape? {
    switch badge.style {
    case .edgeToEdge:
        switch badge.stack.shape {
        case .pill, .none:
            // Edge-to-edge badge cannot have pill shape
            return nil
        case .rectangle(let corners):
            let stackRadius = radiusInfo(shape: badge.stackShape, pillRadius: pillStackRadius)
            switch badge.alignment {
            case .center, .leading, .trailing:
                return nil
            case .top:
                return .rectangle(.init(
                    topLeft: corners?.topLeading,
                    topRight: corners?.topTrailing,
                    bottomLeft: stackRadius.bottomLeft,
                    bottomRight: stackRadius.bottomRight))
            case .bottom:
                return .rectangle(.init(
                    topLeft: stackRadius.topLeft,
                    topRight: stackRadius.topRight,
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
            @unknown default:
                return nil
            }
        @unknown default:
            return nil
        }
    case .nested, .overlaid:
        switch badge.stack.shape {
        case .rectangle(let radius):
            return .rectangle(.init(topLeft: radius?.topLeading,
                                    topRight: radius?.topTrailing,
                                    bottomLeft: radius?.bottomLeading,
                                    bottomRight: radius?.bottomTrailing))
        case .pill:
            return .pill
        case .none:
            return nil
        @unknown default:
            return nil
        }
    @unknown default:
        return nil
    }
}

// Helper to extract the RadiusInfo from a shape.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private func radiusInfo(shape: ShapeModifier.Shape?, pillRadius: Double? = 0) -> ShapeModifier.RadiusInfo {
    switch shape {
    case .rectangle(let radius):
        return radius ?? .init(topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0)
    case .pill:
        return .init(topLeft: pillRadius, topRight: pillRadius, bottomLeft: pillRadius, bottomRight: pillRadius)
    default:
        return .init(topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0)
    }
}

// This modifier is used exclusively for edge-to-edge badges in top and bottom positions.
// In case the stack has pill shape, we can calculate its radius by using the stack's size.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct EdgeToEdgeTopBottomModifier: ViewModifier {

    @State private var stackSize: CGSize = .zero
    var badge: BadgeModifier.BadgeInfo

    var badgeView: some View {
        VStack {
            ComponentsView(componentViewModels: badge.badgeViewModels, onDismiss: {})
                .padding(badge.stack.padding.edgeInsets)
        }.zIndex(-1)
    }

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if badge.alignment == .top {
                badgeView
            }
            content
                .onSizeChange { size in
                    stackSize = size
                }
            if badge.alignment == .bottom {
                badgeView
            }
        }
        .background {
            VStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .backgroundStyle(badge.backgroundStyle)
                .shape(border: badge.stackBorder,
                       shape: effectiveShape(badge: badge,
                                             pillStackRadius: min(stackSize.width, stackSize.height)/2))
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func stackBadge(_ badge: BadgeModifier.BadgeInfo?) -> some View {
        self.modifier(BadgeModifier(badge: badge))
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgePreviews: View {

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func badge(style: PaywallComponent.BadgeStyle,
                       alignment: PaywallComponent.TwoDimensionAlignment,
                       shape: PaywallComponent.Shape) -> some View {
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
                    dimension: .horizontal(.center, .center),
                    size: .init(width: .fill, height: .fixed(100)),
                    spacing: 10,
                    backgroundColor: .init(light: .hex("#ffffff")),
                    padding: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                    shape: shape,
                    border: .init(color: .init(light: .hex("#0074F3")), width: 10),
                    shadow: .init(color: .init(light: .hex("#00000080")), radius: 4, x: 0, y: 4),
                    badge: .init(
                        style: style,
                        alignment: alignment,
                        stack: PaywallComponent.StackComponent(
                            components: [
                                .text(PaywallComponent.TextComponent(
                                    text: "text_2",
                                    fontWeight: .bold,
                                    color: .init(light: .hex("#000000")),
                                    size: .init(width: .fit, height: .fit),
                                    fontSize: 13
                                ))
                            ],
                            dimension: .horizontal(),
                            size: .init(width: .fill, height: .fixed(150)),
                            spacing: 10,
                            backgroundColor: .init(light: .hex("#F67E70")),
                            padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                            margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                            shape: .rectangle(.init(topLeading: 12, topTrailing: 12,
                                                    bottomLeading: 12, bottomTrailing: 12))
                        )
                    )
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("Feature 1\nFeature 2\nFeature 3\nFeature 4"),
                        "text_2": .string("Special Discount\nSave 50%")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
    }

    var style: PaywallComponent.BadgeStyle

    var body: some View {
        let alignments: [PaywallComponent.TwoDimensionAlignment] = [
            .topLeading, .top, .topTrailing, .bottomLeading, .bottom, .bottomTrailing
        ]
        let shapes: [PaywallComponent.Shape] = [
            .pill,
            .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12)),
            .rectangle(.init(topLeading: 999, topTrailing: 12, bottomLeading: 12, bottomTrailing: 999))
        ]
        ForEach(alignments, id: \.self) { alignment in
            VStack(spacing: 50) {
                ForEach(shapes, id: \.self) { shape in
                    badge(style: style,
                          alignment: alignment,
                          shape: shape)

                }
            }
            .previewDisplayName("\(style) - \(alignment)")
        }
        .previewLayout(.sizeThatFits)
        .padding(30)
        .padding(.vertical, 50)
        .previewRequiredPaywallsV2Properties()
    }
}

// As of Xcode 16, there is a limit of 15 views per PreviewProvider.
// To work around this, we can create multiple PreviewProviders with different sets of previews.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeEdgeToEdge_Previews: PreviewProvider {

    static var previews: some View {
        BadgePreviews(style: .edgeToEdge)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeOverlaid_Previews: PreviewProvider {

    static var previews: some View {
        BadgePreviews(style: .overlaid)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BadgeNested_Previews: PreviewProvider {

    static var previews: some View {
        BadgePreviews(style: .nested)
    }

}

#endif

#endif
