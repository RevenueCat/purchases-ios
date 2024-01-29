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

// swiftlint:disable type_body_length file_length

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

    init(_ configuration: TemplateViewConfiguration) {
        self._selectedPackage = .init(initialValue: configuration.packages.default)
        self.configuration = configuration
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
            .foregroundColor(self.configuration.colors.text1Color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(Constants.fastAnimation, value: self.selectedPackage)
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
                }
                .padding(.top, self.defaultVerticalPaddingLength)
                .scrollableIfNecessaryWhenAvailable()

                self.packages
                    .padding(.top, self.defaultVerticalPaddingLength)
                    .scrollableIfNecessaryWhenAvailable()
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
                    .scrollableIfNecessaryWhenAvailable(enabled: self.configuration.mode.isFullScreen)
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
        if let header = self.configuration.headerImageURL {
            RemoteImage(url: header,
                        aspectRatio: self.headerAspectRatio,
                        maxWidth: .infinity)
            .clipped()
        }
    }

    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.isFullScreen {
                Spacer()

                self.title
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                self.features
                    .defaultHorizontalPadding()

                Spacer()

                self.packagesWithBottomSpacer
            } else {
                self.packagesWithBottomSpacer
                    .hideFooterContent(self.configuration,
                                       hide: !self.displayingAllPlans)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var title: some View {
        Text(.init(self.selectedLocalization.title))
            .font(self.font(for: .largeTitle).bold())
            .defaultHorizontalPadding()
            .matchedGeometryEffect(id: Geometry.title, in: self.namespace)
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
                                IconView(icon: icon, tint: self.configuration.colors.featureIcon)
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
        .matchedGeometryEffect(id: Geometry.features, in: self.namespace)
    }

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
        .matchedGeometryEffect(id: Geometry.packages, in: self.namespace)
        .defaultHorizontalPadding()
    }

    @ViewBuilder
    private var packagesWithBottomSpacer: some View {
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

                self.packageDiscountLabel(package, selected: selected)
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
                    ? self.configuration.colors.selectedOutline
                    : self.configuration.colors.unselectedOutline,
                    lineWidth: Constants.defaultPackageBorderWidth
                )
        }
    }

    private var footerView: some View {
        FooterView(configuration: self.configuration,
                   purchaseHandler: self.purchaseHandler,
                   displayingAllPlans: self.$displayingAllPlans)
    }

    @ViewBuilder
    private func packageDiscountLabel(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        if let discount = package.discountRelativeToMostExpensivePerMonth {
            let colors = self.configuration.colors

            Text(Localization.localized(discount: discount, locale: self.locale))
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
                .font(self.font(for: .caption))
                .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
                .padding(8)
        }
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
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
            ? self.configuration.colors.selectedOutline
            : self.configuration.colors.unselectedOutline

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
            foregroundColor: self.configuration.colors.text1Color,
            alignment: alignment
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
    }

    private var subscribeButton: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.selectedPackage,
            configuration: self.configuration
        )
        .matchedGeometryEffect(id: Geometry.subscribeButton, in: self.namespace)
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Template5View {

    enum Geometry: Hashable {
        case title
        case features
        case packages
        case subscribeButton
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private extension PaywallData.Configuration.Colors {

    var featureIcon: Color { self.accent1Color }
    var selectedOutline: Color { self.accent2Color }
    var unselectedOutline: Color { self.accent3Color }
    var selectedDiscountText: Color { self.text2Color }
    var unselectedDiscountText: Color { self.text3Color }

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Template5View {

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.selectedPackage.localization
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
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
