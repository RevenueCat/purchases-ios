//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template7View.swift
//
//  Created by Nacho Soto.

// swiftlint:disable type_body_length file_length

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Template7View: TemplateViewType {

    let configuration: TemplateViewConfiguration

    private let tiers: [PaywallData.Tier: TemplateViewConfiguration.PackageConfiguration.MultiPackage]
    private let tierNames: [PaywallData.Tier: String]

    @State
    private var selectedTier: PaywallData.Tier

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @State
    private var displayingAllPlans: Bool

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    #if swift(>=5.9) || (!os(macOS) && !os(watchOS) && !os(tvOS))
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    #endif

    @Namespace
    private var namespace

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private var showTierSelector: Bool {
        return self.tiers.count > 1
    }

    private var displayableTiers: [PaywallData.Tier] {
        // Filter out to display tiers only
        // Tiers may not exist in self.tiers if there are no products available
        return self.configuration.configuration.tiers.filter({ tier in
            return self.tiers[tier] != nil
        })
    }

    init(_ configuration: TemplateViewConfiguration) {
        guard let (firstTier, allTiers, tierNames) = configuration.packages.multiTier else {
            fatalError("Attempted to display a multi-tier template with invalid data: \(configuration.packages)")
        }

        self.tiers = allTiers
        self.tierNames = tierNames
        self.configuration = configuration

        self._selectedTier = .init(initialValue: firstTier)
        self._selectedPackage = .init(initialValue: allTiers[firstTier]!.default)
        self._displayingAllPlans = .init(initialValue: configuration.mode.displayAllPlansByDefault)
    }

    var body: some View {
        Group {
            if self.shouldUseLandscapeLayout {
                self.horizontalContent
            } else {
                self.verticalFullScreenContent
            }
        }
            .foregroundColor(self.currentColors.text1Color)
            .background(self.currentColors.backgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(Constants.fastAnimation, value: self.selectedPackage)
            .notify(
                selectedTier: self.selectedTier,
                selectedPackage: self.selectedPackage
            )
    }

    @ViewBuilder
    var horizontalContent: some View {
        VStack {
            Spacer()

            HStack {
                VStack {
                    self.title
                        .frame(maxWidth: .infinity, alignment: .center)

                    self.features

                    Spacer()
                }
                .padding(.top, self.defaultVerticalPaddingLength)
                .scrollableIfNecessaryWhenAvailableForV1()

                VStack {
                    self.tierSelectorView
                    self.packages

                    Spacer()
                }
                .padding(.top, self.defaultVerticalPaddingLength)
                .scrollableIfNecessaryWhenAvailableForV1()
            }

            Spacer()

            self.subscribeButton

            self.footerView
        }
    }

    @ViewBuilder
    var verticalFullScreenContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            VStack(spacing: 0) {
                if self.configuration.mode.isFullScreen {
                    self.headerImage
                }

                self.scrollableContent
                    .padding(
                        .top,
                        self.displayingAllPlans
                        ? self.defaultVerticalPaddingLength
                        // Compensate for additional padding on condensed mode + iPad
                        : self.defaultVerticalPaddingLength.map { $0 * -1 }
                    )
                    .scrollableIfNecessaryWhenAvailableForV1(enabled: self.configuration.mode.isFullScreen)
            }

            if self.configuration.mode.shouldDisplayInlineOfferDetails(displayingAllPlans: self.displayingAllPlans) {
                self.offerDetails(
                    package: self.selectedPackage,
                    selected: false,
                    alignment: .center
                )
            }

            self.subscribeButton
                .defaultHorizontalPadding()

            self.footerView
        }
        .edgesIgnoringSafeArea(.top)
    }

    @ViewBuilder
    private var headerImage: some View {
        ConsistentTierContentView(
            tiers: self.tiers,
            selected: self.selectedTier
        ) { tier, _ in
            if let header = self.configuration.headerImageURL(for: tier) {
                RemoteImage(url: header,
                            aspectRatio: self.headerAspectRatio,
                            maxWidth: .infinity)
                .clipped()
            }
        }
    }

    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.isFullScreen {
                self.title

                self.tierSelectorView

                self.featuresAndPackages

                Spacer()
            } else {
                if case .condensedFooter = self.configuration.mode {
                    self.selectedTierView
                        .hideFooterContent(self.configuration, hide: self.displayingAllPlans)
                }

                self.packagesAndTierSelector
                    .hideFooterContent(self.configuration,
                                       hide: !self.displayingAllPlans)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var tierSelectorView: some View {
        Group {
            if self.showTierSelector {
                TierSelectorView(
                    tiers: self.displayableTiers,
                    tierNames: self.tierNames,
                    selectedTier: self.$selectedTier,
                    fonts: self.configuration.fonts,
                    backgroundColor: self.currentColors.tierControlBackground,
                    textColor: self.currentColors.tierControlForeground,
                    selectedBackgroundColor: self.currentColors.tierControlSelectedBackground,
                    selectedTextColor: self.currentColors.tierControlSelectedForeground
                )
            }
        }
        .onChangeOf(self.selectedTier) { tier in
            withAnimation(Constants.tierChangeAnimation) {
                self.selectedPackage = self.tiers[tier]!.default
            }
        }
    }

    private var selectedTierView: some View {
        TierSelectorView(
            tier: self.selectedTier,
            name: self.tierNames[self.selectedTier]!,
            fonts: self.configuration.fonts,
            backgroundColor: self.currentColors.tierControlBackground,
            textColor: self.currentColors.tierControlForeground,
            selectedBackgroundColor: self.currentColors.tierControlSelectedBackground,
            selectedTextColor: self.currentColors.tierControlSelectedForeground
        )
    }

    private var title: some View {
        ConsistentPackageContentView(
            packages: self.configuration.packages.all,
            selected: self.selectedPackage
        ) { package in
            self.title(package: package)
        }
        .defaultHorizontalPadding()
    }

    private func title(package: TemplateViewConfiguration.Package) -> some View {
        Text(.init(self.selectedPackage.localization.title))
            .font(self.font(for: .title).weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var featuresAndPackages: some View {
        ConsistentTierContentView(
            tiers: self.tiers,
            selected: self.selectedTier
        ) { tier, packages in
            VStack {
                self.features(package: self.selectedPackage)
                    // Only bottom padding if the tier selector is being hidden
                    .padding(self.showTierSelector ? .vertical : .bottom, self.defaultVerticalPaddingLength)

                self.packages(for: tier, packages: packages.all)

                // Needed if there are tiers that have
                // different number of packages than other tiers
                Spacer()
            }
        }
        .defaultHorizontalPadding()
    }

    private var features: some View {
        ConsistentPackageContentView(
            packages: self.configuration.packages.all,
            selected: self.selectedPackage
        ) { package in
            self.features(package: package)
        }
    }

    @ViewBuilder
    private func features(package: TemplateViewConfiguration.Package) -> some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            ForEach(package.localization.features, id: \.title) { feature in
                HStack {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if let icon = feature.icon {
                                IconView(icon: icon, tint: self.currentColors.featureIcon)
                            }
                        }
                        .frame(width: self.iconSize, height: self.iconSize)

                    Text(.init(feature.title))
                        .font(self.font(for: .body))
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var packages: some View {
        ConsistentTierContentView(
            tiers: self.tiers,
            selected: self.selectedTier
        ) { tier, packages in
            self.packages(for: tier, packages: packages.all)
        }
        .defaultHorizontalPadding()
    }

    private func packages(
        for tier: PaywallData.Tier,
        packages: [TemplateViewConfiguration.Package]
    ) -> some View {
        VStack(spacing: Constants.defaultPackageVerticalSpacing) {
            ForEach(packages, id: \.content.id) { package in
                let isSelected = self.selectedPackage.content === package.content

                Button {
                    self.selectedPackage = package
                } label: {
                    self.packageButton(package, selected: isSelected)
                }
                .buttonStyle(PackageButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var packagesAndTierSelector: some View {
        self.tierSelectorView
            .padding(.bottom)

        self.packages

        Spacer()
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        VStack(alignment: Self.packageButtonAlignment.horizontal, spacing: 5) {
            HStack(alignment: .top) {
                self.packageButtonTitle(package, selected: selected)
                    .defaultHorizontalPadding()
                    .padding(.top, self.defaultVerticalPaddingLength)

                Spacer(minLength: 0)

                self.packageBadgeLabel(package, selected: selected)
            }

            self.offerDetails(package: package, selected: selected)
                .defaultHorizontalPadding()
                .padding(.bottom, self.defaultVerticalPaddingLength)
        }
        .font(self.font(for: .body).weight(.medium))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: Self.packageButtonAlignment)
        .overlay {
            self.roundedRectangle
                .stroke(
                    selected
                    ? self.currentColors.selectedOutline
                    : self.currentColors.unselectedOutline,
                    lineWidth: Constants.defaultPackageBorderWidth
                )
        }
    }

    private var footerView: some View {
        FooterView(configuration: self.configuration,
                   locale: self.selectedPackage.localization.locale,
                   purchaseHandler: self.purchaseHandler,
                   displayingAllPlans: self.$displayingAllPlans)
    }

    @ViewBuilder
    private func packageBadgeLabel(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        if let badge = package.localization.offerBadge, !badge.isEmpty {
            let colors = self.currentColors

            Text(badge)
                .textCase(.uppercase)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(self.roundedRectangle.foregroundColor(
                    selected
                    ? colors.selectedOutline
                    : colors.unselectedOutline
                ))
                .foregroundColor(
                    selected
                    ? colors.selectedDiscountText
                    : colors.unselectedDiscountText
                )
                .font(self.font(for: .caption).weight(.semibold))
                .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
                .padding(8)
        }
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: Constants.defaultCornerRadius, style: .continuous)
    }

    @ViewBuilder
    private func packageButtonTitle(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        let image = selected
            ? "checkmark.circle.fill"
            : "circle.fill"
        let color = selected
            ? self.currentColors.selectedOutline
            : self.currentColors.unselectedOutline

        HStack {
            Image(systemName: image)
                .foregroundColor(color)

            Text(package.localization.offerName ?? package.content.productName)
        }
    }

    private func offerDetails(
        package: TemplateViewConfiguration.Package,
        selected: Bool,
        alignment: Alignment = Self.packageButtonAlignment
    ) -> some View {
        IntroEligibilityStateView(
            display: .offerDetails,
            localization: package.localization,
            introEligibility: self.introEligibility[package.content],
            foregroundColor: self.currentColors.text1Color,
            alignment: alignment
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
    }

    private var subscribeButton: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.selectedPackage,
            configuration: self.configuration,
            selectedTier: self.selectedTier
        )
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var currentColors: PaywallData.Configuration.Colors {
        return self.configuration.colors(for: self.selectedTier)
    }

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 25

    private static let packageButtonAlignment: Alignment = .leading

    private var headerAspectRatio: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad: return 3
        default: return 2
        }
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private extension PaywallData.Configuration.Colors {

    var featureIcon: Color { self.accent1Color }
    var selectedOutline: Color { self.accent2Color }
    var unselectedOutline: Color { self.accent3Color }
    var selectedDiscountText: Color { self.text2Color }
    var unselectedDiscountText: Color { self.text3Color }
    var selectedTier: Color { self.accent1Color }
    var callToAction: Color { self.selectedTier }

    var tierControlBackground: Color { self.tierControlBackgroundColor ?? self.accent1Color }
    var tierControlForeground: Color { self.tierControlForegroundColor ?? self.text1Color }
    var tierControlSelectedBackground: Color { self.tierControlSelectedBackgroundColor ?? self.unselectedDiscountText }
    var tierControlSelectedForeground: Color { self.tierControlSelectedForegroundColor ?? self.text1Color }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct Template7View_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            PreviewableTemplate(
                offering: TestData.offeringWithTemplate7Paywall,
                mode: mode
            ) {
                Template7View($0)
            }
        }
    }

}

#endif
