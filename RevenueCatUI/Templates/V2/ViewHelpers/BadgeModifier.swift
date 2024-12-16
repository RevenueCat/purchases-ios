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
    let textComponentViewModel: TextComponentViewModel?

    struct BadgeInfo {
        let style: PaywallComponent.BadgeStyle
        let alignment: PaywallComponent.TwoDimensionAlignment
        let shape: ShapeModifier.Shape
        let padding: PaywallComponent.Padding
        let margin: PaywallComponent.Padding
        let textLid: String
        let fontName: String?
        let fontWeight: PaywallComponent.FontWeight
        let fontSize: PaywallComponent.FontSize
        let horizontalAlignment: PaywallComponent.HorizontalAlignment
        let color: PaywallComponent.ColorScheme
        let backgroundColor: PaywallComponent.ColorScheme
        let parentShape: ShapeModifier.Shape?
    }

    func body(content: Content) -> some View {
        if let badge = badge, let textComponentViewModel = textComponentViewModel {
            content.apply(badge: badge, textComponentViewModel: textComponentViewModel)
        } else {
            content
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {

    @ViewBuilder
    func apply(badge: BadgeModifier.BadgeInfo, textComponentViewModel: TextComponentViewModel) -> some View {
        switch badge.style {
        case .edgeToEdge:
            self.appleBadgeEdgeToEdge(badge: badge, textComponentViewModel: textComponentViewModel)
        case .overlaid:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        TextComponentView(viewModel: textComponentViewModel)
                            .backgroundStyle(badge.backgroundColor.backgroundStyle)
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
                        TextComponentView(viewModel: textComponentViewModel)
                            .backgroundStyle(badge.backgroundColor.backgroundStyle)
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
    private func appleBadgeEdgeToEdge(
        badge: BadgeModifier.BadgeInfo,
        textComponentViewModel: TextComponentViewModel) -> some View {
        switch badge.alignment {
        case .bottom:
            self.background(
                VStack(alignment: .leading) {
                    VStack {
                        TextComponentView(viewModel: textComponentViewModel)
                            .backgroundStyle(badge.backgroundColor.backgroundStyle)
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
                        .backgroundStyle(badge.backgroundColor.backgroundStyle)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .top:
            self.background(
                VStack(alignment: .leading) {
                    VStack {
                        TextComponentView(viewModel: textComponentViewModel)
                            .backgroundStyle(badge.backgroundColor.backgroundStyle)
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
                        .backgroundStyle(badge.backgroundColor.backgroundStyle)
                    Rectangle()
                        .fill(Color.clear)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .bottomLeading, .bottomTrailing, .topLeading, .topTrailing:
            self.overlay(
                VStack(alignment: .leading) {
                    VStack {
                        TextComponentView(viewModel: textComponentViewModel)
                            .backgroundStyle(badge.backgroundColor.backgroundStyle)
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
        return switch alignment {
        case .top, .topLeading, .topTrailing:
            VerticalAlignment.top
        case .bottom, .bottomLeading, .bottomTrailing:
            VerticalAlignment.bottom
        default:
            VerticalAlignment.top
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
                return .init(top: 0, bottom: 0, leading: badge.margin.leading, trailing: 0)
            case .trailing, .topTrailing, .bottomTrailing:
                return .init(top: 0, bottom: 0, leading: 0, trailing: badge.margin.trailing)
            }
        case .nested:
            switch badge.alignment {
            case .center, .leading, .trailing:
                return .zero
            case .top:
                return .init(top: badge.margin.top, bottom: 0, leading: 0, trailing: 0)
            case .bottom:
                return .init(top: 0, bottom: badge.margin.bottom, leading: 0, trailing: 0)
            case .topLeading:
                return .init(top: badge.margin.top, bottom: 0, leading: badge.margin.leading, trailing: 0)
            case .topTrailing:
                return .init(top: badge.margin.top, bottom: 0, leading: 0, trailing: badge.margin.trailing)
            case .bottomLeading:
                return .init(top: 0, bottom: badge.margin.bottom, leading: badge.margin.leading, trailing: 0)
            case .bottomTrailing:
                return .init(top: 0, bottom: badge.margin.bottom, leading: 0, trailing: badge.margin.trailing)
            }
        }
    }

    // Helper to calculate the shape of the edge-to-edge badge in trailing/leading positions.
    // swiftlint:disable:next cyclomatic_complexity
    private func effectiveShape(badge: BadgeModifier.BadgeInfo) -> ShapeModifier.Shape? {
        switch badge.style {
        case .edgeToEdge:
            switch badge.shape {
            case .pill, .concave, .convex:
                // Edge-to-edge badge cannot have pill shape
                return nil
            case .rectangle(let corners):
                switch badge.alignment {
                case .center, .leading, .trailing:
                    return nil
                case .top:
                    return .rectangle(.init(
                        topLeft: corners?.topLeft,
                        topRight: corners?.topRight,
                        bottomLeft: 0,
                        bottomRight: 0))
                case .bottom:
                    return .rectangle(.init(
                        topLeft: 0,
                        topRight: 0,
                        bottomLeft: corners?.bottomLeft,
                        bottomRight: corners?.bottomRight))
                case .topLeading:
                    return .rectangle(.init(
                        topLeft: radiusInfo(shape: badge.parentShape)?.topLeft,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: corners?.bottomRight))
                case .topTrailing:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: radiusInfo(shape: badge.parentShape)?.topRight,
                        bottomLeft: corners?.bottomLeft,
                        bottomRight: 0))
                case .bottomLeading:
                    return .rectangle(.init(
                        topLeft: 0.0,
                        topRight: corners?.topRight,
                        bottomLeft: radiusInfo(shape: badge.parentShape)?.bottomLeft,
                        bottomRight: 0))
                case .bottomTrailing:
                    return .rectangle(.init(
                        topLeft: corners?.topLeft,
                        topRight: 0,
                        bottomLeft: 0,
                        bottomRight: radiusInfo(shape: badge.parentShape)?.bottomRight))
                }
            }
        case .nested, .overlaid:
            return badge.shape
        }
    }

    // Helper to extract the RadiusInfo from a rectable shape
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
    func badge(_ badge: BadgeModifier.BadgeInfo?, textComponentViewModel: TextComponentViewModel?) -> some View {
        self.modifier(BadgeModifier(badge: badge, textComponentViewModel: textComponentViewModel))
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
    .backgroundStyle(.color(.init(light: .hex("#ffffff"))))
    .shape(
        border: .init(color: .blue, width: 10),
        shape: .rectangle(ShapeModifier.RadiusInfo(topLeft: 12.0, topRight: 12, bottomLeft: 12, bottomRight: 12))
    )
    .compositingGroup()
    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
        .badge(
            BadgeModifier.BadgeInfo(
                style: style,
                alignment: alignment,
                shape: .rectangle(.init(topLeft: 8.0, topRight: 8, bottomLeft: 8, bottomRight: 8)),
                padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
                textLid: "id_1",
                fontName: nil,
                fontWeight: .bold,
                fontSize: .bodyS,
                horizontalAlignment: .center,
                color: .init(light: .hex("#000000")),
                backgroundColor: .init(light: .hex("#FA8072")),
                parentShape: .rectangle(.init(topLeft: 12.0, topRight: 12, bottomLeft: 12, bottomRight: 12))
            ),
            // swiftlint:disable:next force_try
            textComponentViewModel: try! TextComponentViewModel(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Special Discount\nSave 50%")
                    ]
                ),
                component: PaywallComponent.TextComponent(
                    text: "id_1",
                    fontName: nil,
                    fontWeight: .bold,
                    color: .init(light: .hex("#000000")),
                    padding: .init(top: 4, bottom: 4, leading: 16, trailing: 16),
                    margin: .zero,
                    fontSize: .bodyS,
                    horizontalAlignment: .center
                )
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
