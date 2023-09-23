//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template5View.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct Template5View: TemplateViewType {

    let configuration: TemplateViewConfiguration

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @State
    private var displayingAllPlans: Bool

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    @Environment(\.locale)
    var locale

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self._selectedPackage = .init(initialValue: configuration.packages.default)
        self.configuration = configuration
        self._displayingAllPlans = .init(initialValue: configuration.mode.displayAllPlansByDefault)
    }

    var body: some View {
        self.content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.shouldDisplayIcon {
                if let header = self.configuration.headerImageURL {
                    RemoteImage(url: header,
                                aspectRatio: self.headerAspectRatio,
                                maxWidth: .infinity)
                    .clipped()

                    Spacer()
                }
            }

            self.scrollableContent
                .scrollableIfNecessary(enabled: self.configuration.mode.shouldDisplayPackages)
                .padding(
                    .top,
                    self.displayingAllPlans
                    ? self.defaultVerticalPaddingLength
                    // Compensate for additional padding on condensed mode + iPad
                    : self.defaultVerticalPaddingLength.map { $0 * -1 }
                )

            if self.configuration.mode.shouldDisplayInlineOfferDetails(displayingAllPlans: self.displayingAllPlans) {
                self.offerDetails(package: self.selectedPackage, selected: false)
            }

            self.subscribeButton
                .defaultHorizontalPadding()

            FooterView(configuration: self.configuration,
                       purchaseHandler: self.purchaseHandler,
                       displayingAllPlans: self.$displayingAllPlans)
        }
        .foregroundColor(self.configuration.colors.text1Color)
        .edgesIgnoringSafeArea(.top)
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.shouldDisplayText {
                Text(.init(self.selectedLocalization.title))
                    .font(self.font(for: .largeTitle).bold())
                    .frame(maxWidth: .infinity)
                    .defaultHorizontalPadding()

                Spacer()

                self.features
                    .defaultHorizontalPadding()

                Spacer()
            }

            if self.configuration.mode.shouldDisplayPackages {
                self.packages
            } else {
                self.packages
                    .hideFooterContent(self.configuration,
                                       hide: !self.displayingAllPlans)
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var features: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            ForEach(self.selectedLocalization.features, id: \.title) { feature in
                HStack {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if let icon = feature.icon {
                                IconView(icon: icon, tint: self.configuration.colors.accent1Color)
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

    @ViewBuilder
    private var packages: some View {
        VStack(spacing: 16) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.selectedPackage.content === package.content

                Button {
                    self.selectedPackage = package
                } label: {
                    self.packageButton(package, selected: isSelected)
                }
                .buttonStyle(PackageButtonStyle())
            }
        }
        .defaultHorizontalPadding()

        Spacer()
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        VStack(alignment: Self.packageButtonAlignment.horizontal, spacing: 5) {
            self.packageButtonTitle(package, selected: selected)

            self.offerDetails(package: package, selected: selected)
        }
        .font(self.font(for: .body).weight(.medium))
        .defaultPadding()
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: Self.packageButtonAlignment)
        .overlay {
            self.roundedRectangle
                .stroke(
                    selected
                    ? self.configuration.colors.accent1Color
                    : self.configuration.colors.accent2Color,
                    lineWidth: Constants.defaultPackageBorderWidth
                )
        }
        .overlay(alignment: .topTrailing) {
            self.packageDiscountLabel(package)
                .padding(8)
        }
    }

    @ViewBuilder
    private func packageDiscountLabel(_ package: TemplateViewConfiguration.Package) -> some View {
        if let discount = package.discountRelativeToMostExpensivePerMonth {
            Text(Localization.localized(discount: discount, locale: self.locale))
                .textCase(.uppercase)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(self.roundedRectangle.foregroundColor(self.configuration.colors.accent1Color))
                .foregroundColor(self.configuration.colors.callToActionForegroundColor)
                .font(self.font(for: .caption))
                .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
        }
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
    }

    private func packageButtonTitle(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        HStack {
            Constants.checkmarkImage
                .hidden(if: !selected)
                .overlay {
                    if selected {
                        EmptyView()
                    } else {
                        Circle()
                            .foregroundColor(self.selectedBackgroundColor)
                    }
                }
                .foregroundColor(self.configuration.colors.accent1Color)

            Text(package.localization.offerName ?? package.content.productName)
        }
    }

    private func offerDetails(package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        IntroEligibilityStateView(
            textWithNoIntroOffer: package.localization.offerDetails,
            textWithIntroOffer: package.localization.offerDetailsWithIntroOffer,
            introEligibility: self.introEligibility[package.content],
            foregroundColor: self.configuration.colors.text1Color,
            alignment: Self.packageButtonAlignment
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            configuration: self.configuration,
            introEligibility: self.introEligibility[self.selectedPackage.content],
            purchaseHandler: self.purchaseHandler
        )
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var selectedBackgroundColor: Color { self.configuration.colors.accent2Color }

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 25

    private static let cornerRadius: CGFloat = Constants.defaultPackageCornerRadius
    private static let packageButtonAlignment: Alignment = .leading

    private var headerAspectRatio: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad: return 3
        default: return 2
        }
    }

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension Template5View {

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.selectedPackage.localization
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewMode {

    var shouldDisplayPackages: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct Template5View_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            PreviewableTemplate(
                offering: TestData.offeringWithTemplate5Paywall,
                mode: mode
            ) {
                Template5View($0)
            }
        }
    }

}

#endif
