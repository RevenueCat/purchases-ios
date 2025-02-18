//
//  TierSelectorView.swift
//
//
//  Created by Nacho Soto on 2/8/24.
//

import SwiftUI

import RevenueCat

// swiftlint:disable force_unwrapping

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TierSelectorView: View {

    private let tiers: [PaywallData.Tier]
    private let namesByTierID: [String: String]
    private let selectedTier: Binding<PaywallData.Tier>

    private let fonts: PaywallFontProvider

    private let backgroundColor: Color
    private let textColor: Color
    private let selectedBackgroundColor: Color
    private let selectedTextColor: Color

    private let indexesByTier: [PaywallData.Tier: Int]

    @Namespace
    private var namespace

    /// Creates a `TierSelectorView` that only displays the currently selected tier.
    init(
        tier: PaywallData.Tier,
        name: String,
        fonts: PaywallFontProvider,
        backgroundColor: Color,
        textColor: Color,
        selectedBackgroundColor: Color,
        selectedTextColor: Color
    ) {
        self.init(
            tiers: [tier],
            tierNames: [tier: name],
            selectedTier: .constant(tier),
            fonts: fonts,
            backgroundColor: backgroundColor,
            textColor: textColor,
            selectedBackgroundColor: selectedBackgroundColor,
            selectedTextColor: selectedTextColor
        )
    }

    init(
        tiers: [PaywallData.Tier],
        namesByTierID: [String: String],
        selectedTier: Binding<PaywallData.Tier>,
        fonts: PaywallFontProvider,
        backgroundColor: Color,
        textColor: Color,
        selectedBackgroundColor: Color,
        selectedTextColor: Color
    ) {
        precondition(!tiers.isEmpty)

        self.tiers = tiers
        self.namesByTierID = namesByTierID
        self.selectedTier = selectedTier
        self.fonts = fonts
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.selectedTextColor = selectedTextColor

        self.indexesByTier = .init(
            uniqueKeysWithValues: tiers
                .enumerated()
                .map { ($1, $0) }
        )
    }

    var body: some View {
        self.buttons
            .background {
                self.background
                    .hidden(if: self.isSingleTier)
            }
            .defaultHorizontalPadding()
            .fixedSize(horizontal: self.isSingleTier, vertical: true)
            .allowsHitTesting(!self.isSingleTier)
    }

    @ViewBuilder
    private var buttons: some View {
        HStack {
            ForEach(self.tiers) { tier in
                let index = self.indexesByTier[tier]!
                let selected = tier.id == self.selectedTier.id
                let isLastTier = index == self.tiers.count - 1

                Button {
                    withAnimation(Constants.tierChangeAnimation) {
                        self.selectedTier.wrappedValue = tier
                    }
                } label: {
                    self.buttonLabel(for: tier, selected: selected)
                }

                if !isLastTier {
                    let selectedIndex = self.indexesByTier[self.selectedTier.wrappedValue]!

                    Divider()
                        .padding(.vertical, Padding.vertical)
                        .opacity(
                            selectedIndex == index || selectedIndex == index + 1
                            ? 0
                            : 1
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func buttonLabel(for tier: PaywallData.Tier, selected: Bool) -> some View {
        // Layout all labels to ensure consistent sizing
        self.allLabels
            .hidden()
            .overlay {
                ZStack {
                    // Allows fading between both states.
                    // Without this, SwiftUI does a really poor transition between font weights.
                    self.tierNameLabel(tier, selected: true)
                        .opacity(selected ? 1 : 0)
                    self.tierNameLabel(tier, selected: false)
                        .opacity(selected ? 0 : 1)
                }
                .animation(Constants.fastAnimation, value: self.selectedTier.wrappedValue)
            }
            .frame(maxWidth: .infinity) // Equal width labels
            .contentShape(Rectangle()) // Make the whole label tappable
            .background {
                if selected {
                    self.selectedTierBackground
                }
            }
    }

    private var allLabels: some View {
        ZStack {
            ForEach(self.tiers) { tier in
                self.tierNameLabel(tier, selected: true)
            }
        }
    }

    private func tierNameLabel(_ tier: PaywallData.Tier, selected: Bool) -> some View {
        Text(self.namesByTierID[tier.id] ?? "")
            .foregroundStyle(selected ? self.selectedTextColor : self.textColor)
            .font(self.fonts.font(for: .callout).weight(selected ? .semibold : .regular))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, Padding.vertical)
    }

    @ViewBuilder
    private var selectedTierBackground: some View {
        Capsule(style: .continuous)
            .foregroundColor(self.selectedBackgroundColor)
            .padding(Padding.background)
            .matchedGeometryEffect(
                id: Self.geometryEffectID,
                in: self.namespace,
                properties: [.frame]
            )
            .animation(Constants.tierChangeAnimation, value: self.selectedTier.wrappedValue)
    }

    @ViewBuilder
    private var background: some View {
        Capsule(style: .continuous)
            .foregroundColor(self.backgroundColor)
    }

    private var isSingleTier: Bool {
        return self.tiers.count == 1
    }

    // MARK: -

    private static let geometryEffectID = "background"

    private enum Padding {
        static let background: CGFloat = 2
        static let vertical: CGFloat = 8
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TierSelectorView {

    init(
        tiers: [PaywallData.Tier],
        tierNames: [PaywallData.Tier: String],
        selectedTier: Binding<PaywallData.Tier>,
        fonts: PaywallFontProvider,
        backgroundColor: Color,
        textColor: Color,
        selectedBackgroundColor: Color,
        selectedTextColor: Color
    ) {
        self.init(
            tiers: tiers,
            namesByTierID: .init(
                uniqueKeysWithValues: tierNames.map { ($0.id, $1) }
            ),
            selectedTier: selectedTier,
            fonts: fonts,
            backgroundColor: backgroundColor,
            textColor: textColor,
            selectedBackgroundColor: selectedBackgroundColor,
            selectedTextColor: selectedTextColor
        )
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TierSelectorPreview: View {

    @State
    private var selectedTier: PaywallData.Tier = Self.tiers.first!

    var body: some View {
        TierSelectorView(
            tiers: Self.tiers,
            namesByTierID: Self.namesByTierID,
            selectedTier: self.$selectedTier,
            fonts: DefaultPaywallFontProvider(),
            backgroundColor: #colorLiteral(red: 0.46, green: 0.46, blue: 0.5, alpha: 0.12).asPaywallColor.underlyingColor,
            textColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor.underlyingColor,
            selectedBackgroundColor: #colorLiteral(red: 0.65, green: 0.93, blue: 0.46, alpha: 1).asPaywallColor.underlyingColor,
            selectedTextColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor.underlyingColor
        )
    }

    private static let tiers: [PaywallData.Tier] = [
        .init(id: "standard",
              packages: [],
              defaultPackage: ""),
        .init(id: "premium",
              packages: [],
              defaultPackage: ""),
        .init(id: "advanced",
              packages: [],
              defaultPackage: "")
    ]
    private static let namesByTierID = [
        "standard": "Standard",
        "premium": "Premium",
        "advanced": "Advanced"
    ]

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TierSelectorView_Previews: PreviewProvider {

    static var previews: some View {
        TierSelectorPreview()
            .previewDisplayName("Normal")

        TierSelectorPreview()
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Large")

        TierSelectorView(
            tier: .init(id: "standard",
                        packages: [],
                        defaultPackage: ""),
            name: "Standard",
            fonts: DefaultPaywallFontProvider(),
            backgroundColor: #colorLiteral(red: 0.46, green: 0.46, blue: 0.5, alpha: 0.12).asPaywallColor.underlyingColor,
            textColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor.underlyingColor,
            selectedBackgroundColor: #colorLiteral(red: 0.65, green: 0.93, blue: 0.46, alpha: 1).asPaywallColor.underlyingColor,
            selectedTextColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor.underlyingColor
        )
        .previewDisplayName("Current Tier")
    }

}

#endif
