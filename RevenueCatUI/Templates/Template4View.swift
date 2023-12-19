//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template4View.swift
//
//  Created by Nacho Soto on 8/1/23.

import RevenueCat
import SwiftUI

// swiftlint:disable file_length

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Template4View: TemplateViewType {

    let configuration: TemplateViewConfiguration

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @State
    private var packageContentHeight: CGFloat?
    @State
    private var containerWidth: CGFloat = 600
    @State
    private var displayingAllPlans: Bool

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    #if swift(>=5.9) || (!os(macOS) && !os(watchOS) && !os(tvOS))
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    #endif

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration

        self._selectedPackage = .init(initialValue: configuration.packages.default)
        self._displayingAllPlans = .init(initialValue: configuration.mode.displayAllPlansByDefault)
    }

    var body: some View {
        switch self.configuration.mode {
        case .fullScreen:
            VStack {
                Spacer()

                self.footerContent
                    .background(self.configuration.colors.backgroundColor)
                    #if canImport(UIKit)
                    .roundedCorner(Self.cornerRadius,
                                   corners: [.topLeft, .topRight],
                                   edgesIgnoringSafeArea: .bottom)
                    #endif
            }
            .background {
                if !self.shouldUseLandscapeLayout {
                    TemplateBackgroundImageView(configuration: self.configuration)
                }
            }

        case .footer, .condensedFooter:
            self.footerContent
        }
    }

    @ViewBuilder
    var footerContent: some View {
        VStack(spacing: Self.verticalPadding) {
            if self.configuration.mode.isFullScreen {
                Text(.init(self.selectedPackage.localization.title))
                    .foregroundColor(self.configuration.colors.text1Color)
                    .font(self.font(for: .title).bold())
                    .padding([.horizontal])
                    .padding(.top, Self.verticalPadding)
                    .dynamicTypeSize(...Constants.maximumDynamicTypeSize)

                self.packagesScrollView
            } else {
                self.packagesScrollView
                    .defaultVerticalPadding()
                    .hideFooterContent(self.configuration,
                                       hide: !self.displayingAllPlans)
            }

            if self.configuration.packages.packagesProduceAnyLabel(
                for: .offerDetails,
                eligibility: self.introEligibility
            ) {
                self.offerDetails
                    .defaultHorizontalPadding()
            }

            self.subscribeButton
                .defaultHorizontalPadding()
                .padding(.bottom, Self.verticalPadding / -2)

            FooterView(configuration: self.configuration,
                       bold: false,
                       purchaseHandler: self.purchaseHandler,
                       displayingAllPlans: self.$displayingAllPlans)
            .frame(maxWidth: .infinity)
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .multilineTextAlignment(.center)
        .overlay {
            self.packageHeightCalculation
        }
    }

    private var packagesScrollView: some View {
        self.packages
            .scrollableIfNecessary(.horizontal)
            .frame(height: self.packageContentHeight)
            .frame(maxWidth: .infinity)
            .onWidthChange {
                self.containerWidth = $0
            }
    }

    private var packages: some View {
        HStack(spacing: self.packageHorizontalSpacing) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.selectedPackage.content === package.content

                Button {
                    self.selectedPackage = package
                } label: {
                    PackageButton(configuration: self.configuration,
                                  package: package,
                                  selected: isSelected,
                                  packageWidth: self.packageWidth,
                                  desiredHeight: self.packageContentHeight)
                }
                .buttonStyle(PackageButtonStyle(
                    // Reducing opacity would reveal the discount overlay
                    // layers behind the button
                    fadeDuringPurchases: false
                ))
            }
        }
        .defaultHorizontalPadding()
    }

    private var offerDetails: some View {
        ConsistentPackageContentView(
            packages: self.configuration.packages.all,
            selected: self.selectedPackage
        ) { package in
            IntroEligibilityStateView(
                display: .offerDetails,
                localization: package.localization,
                introEligibility: self.introEligibility[package.content],
                foregroundColor: self.configuration.colors.text1Color
            )
        }
        .font(self.font(for: .body).weight(.light))
        .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
    }

    private var subscribeButton: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.selectedPackage,
            configuration: self.configuration
        )
    }

    /// Proxy views to calculate the largest package view
    private var packageHeightCalculation: some View {
        ZStack {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                PackageButton(configuration: self.configuration,
                              package: package,
                              selected: false,
                              packageWidth: self.packageWidth,
                              desiredHeight: nil)
                .onHeightChange {
                    if $0 > self.packageContentHeight ?? 0 {
                        self.packageContentHeight = $0
                    }
                }
            }
        }
        .onChangeOf(self.dynamicTypeSize) { _ in self.packageContentHeight = nil }
        .onChangeOf(self.containerWidth) { _ in self.packageContentHeight = nil }
        .hidden()
    }

    private var packageWidth: CGFloat {
        let packages = self.packagesToDisplay
        let availableWidth = self.containerWidth - (self.defaultHorizontalPaddingLength ?? 10) * 2

        return max(
            0,
            availableWidth / packages - self.packageHorizontalSpacing * (packages - 1)
        )
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    fileprivate static let cornerRadius = Constants.defaultCornerRadius
    fileprivate static let verticalPadding: CGFloat = 20

    @ScaledMetric(relativeTo: .title2)
    private var packageHorizontalSpacing: CGFloat = 8

    private var packagesToDisplay: CGFloat {
        let desiredCount = {
            if self.dynamicTypeSize < .xxLarge {
                return 3.5
            } else if self.dynamicTypeSize < .accessibility3 {
                return 2.5
            } else {
                return 1.5
            }
        }()
        let maximumPackagesToDisplay = 3

        return min(
            // If there are fewer, use actual count
            min(desiredCount, CGFloat(self.configuration.packages.all.count)),
            CGFloat(maximumPackagesToDisplay)
        )
    }

}

// MARK: - Views

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PackageButton: View {

    var configuration: TemplateViewConfiguration
    var package: TemplateViewConfiguration.Package
    var selected: Bool
    var packageWidth: CGFloat
    var desiredHeight: CGFloat?

    @State
    private var discountLabelHeight: CGFloat = 10

    @Environment(\.locale)
    private var locale

    var body: some View {
        self.buttonTitle(self.package)
            .frame(width: self.packageWidth)
            .background { // Stroke
                RoundedRectangle(cornerRadius: Template4View.cornerRadius)
                    .stroke(
                        self.selected
                        ? self.configuration.colors.accent1Color
                        : self.configuration.colors.accent2Color,
                        lineWidth: Self.borderWidth
                    )
                    .frame(width: self.packageWidth)
                    .frame(maxHeight: .infinity)
                    .padding(Self.borderWidth)
            }
            .background { // Background
                RoundedRectangle(cornerRadius: Template4View.cornerRadius)
                    .foregroundStyle(self.configuration.colors.backgroundColor)
                    .frame(width: self.packageWidth)
                    .padding(Self.borderWidth)
                    .frame(maxHeight: .infinity)
            }
            .background { // Discount overlay
                if let discount = self.package.discountRelativeToMostExpensivePerMonth {
                    self.discountOverlay(discount)
                } else {
                    self.discountOverlay(0)
                        .hidden()
                }
            }
            .overlay(alignment: .topTrailing) { // Checkmark
                if self.selected {
                    Constants.checkmarkImage
                        .font(self.font(for: .headline))
                        .foregroundStyle(self.configuration.colors.accent1Color)
                        .background(self.configuration.colors.backgroundColor)
                        .padding(8)
                }
            }
            .padding(.top, self.discountOverlayHeight)
            .frame(height: self.desiredHeight)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
    }

    private func buttonTitle(
        _ package: TemplateViewConfiguration.Package
    ) -> some View {
        VStack(spacing: Self.labelVerticalSeparation) {
            self.offerName

            Text(self.package.content.localizedPrice)
                .font(self.font(for: .title2).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, Self.labelVerticalSeparation * 4.0)
        .defaultHorizontalPadding()
        .foregroundColor(self.configuration.colors.text1Color)
    }

    @ViewBuilder
    private var offerName: some View {
        // Placeholder to make sure consistent layout
        self.offerText(Localization.localizedDuration(for: .init(value: 12, unit: .month),
                                                      locale: self.locale))
        .hidden()
        .overlay {
            if let offerName = self.package.localization.offerName {
                self.offerText(offerName)
            } else {
                self.offerText(firstRow: nil,
                               secondRow: self.package.content.productName)
            }
        }
    }

    @ViewBuilder
    private func offerText(_ text: String) -> some View {
        let components = text.split(separator: " ", maxSplits: 2)
        if components.count == 2 {
            self.offerText(firstRow: String(components[0]),
                           secondRow: String(components[1]))
        } else {
            self.offerText(firstRow: nil,
                           secondRow: text)
        }
    }

    @ViewBuilder
    private func offerText(firstRow: String?, secondRow: String) -> some View {
        VStack {
            if let firstRow {
                Text(firstRow)
                    .font(self.font(for: .title).bold())
            }

            Text(secondRow)
                .font(self.font(for: .title3).weight(.regular))
        }
    }

    private func discountOverlay(_ discount: Double) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Template4View.cornerRadius)
                .foregroundStyle(
                    self.selected
                    ? self.configuration.colors.accent1Color
                    : self.configuration.colors.accent2Color
                )

            Text(Localization.localized(discount: discount, locale: self.locale))
                .textCase(.uppercase)
                .foregroundColor(
                    self.selected
                    ? self.configuration.colors.text2Color
                    : self.configuration.colors.text3Color
                )
                .font(self.font(for: .caption).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 2)
                .onHeightChange {
                    self.discountLabelHeight = $0
                }
                .offset(
                    y: (self.discountOverlayHeight - self.discountLabelHeight) / 2.0
                    + Self.borderWidth
                )
        }
        .offset(y: self.discountOverlayHeight * -1)
        .frame(width: self.packageWidth + Self.borderWidth)
    }

    private static let labelVerticalSeparation: CGFloat = 5
    private static let borderWidth: CGFloat = 2

    private var discountOverlayHeight: CGFloat {
        return self.discountLabelHeight + Template4View.verticalPadding / 2.0
    }

    private func font(for textStyle: Font.TextStyle) -> Font {
        return self.configuration.fonts.font(for: textStyle)
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct Template4View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithMultiPackageHorizontalPaywall) {
            Template4View($0)
        }
    }

}

#endif
