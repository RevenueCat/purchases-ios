//
//  Template4View.swift
//  
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct Template4View: TemplateViewType {

    let configuration: TemplateViewConfiguration

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @State
    private var packageContentHeight: CGFloat = 10
    @State
    private var containerWidth: CGFloat = 600
    @State
    private var displayingAllPlans: Bool

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

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
            ZStack(alignment: .bottom) {
                TemplateBackgroundImageView(configuration: self.configuration)

                self.overlayContent
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .background(self.configuration.colors.backgroundColor)
                    #if canImport(UIKit)
                    .roundedCorner(Self.cornerRadius,
                                   corners: [.topLeft, .topRight],
                                   edgesIgnoringSafeArea: .bottom)
                    #endif
            }

        case .overlay, .condensedOverlay:
            self.overlayContent
        }
    }

    @ViewBuilder
    var overlayContent: some View {
        VStack(spacing: Self.verticalPadding) {
            if self.configuration.mode.shouldDisplayText {
                Text(.init(self.selectedPackage.localization.title))
                    .foregroundColor(self.configuration.colors.text1Color)
                    .font(self.font(for: .title).bold())
                    .padding([.top, .bottom, .horizontal])
                    .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
            }

            if self.configuration.mode.shouldDisplayPackages {
                self.packagesScrollView
            } else {
                self.packagesScrollView
                    .hideOverlayContent(self.configuration,
                                     hide: !self.displayingAllPlans,
                                     offset: self.packageContentHeight)
            }

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.selectedPackage.localization.offerDetails,
                textWithIntroOffer: self.selectedPackage.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility[self.selectedPackage.content],
                foregroundColor: self.configuration.colors.text1Color
            )
            .font(self.font(for: .body).weight(.light))
            .dynamicTypeSize(...Constants.maximumDynamicTypeSize)

            self.subscribeButton
                .padding(.horizontal)

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
            .onSizeChange(.horizontal) {
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(PackageButtonStyle(isSelected: isSelected))
            }
        }
        .padding(.horizontal, self.packageHorizontalSpacing)
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            configuration: self.configuration,
            introEligibility: self.introEligibility[self.selectedPackage.content],
            purchaseHandler: self.purchaseHandler
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
                .background(.red)
                .offset(x: CGFloat(Int.random(in: -200...200)))
                .onSizeChange(.vertical) {
                    if $0 > self.packageContentHeight {
                        self.packageContentHeight = $0
                    }
                }
            }
        }
        .onChange(of: self.dynamicTypeSize) { _ in self.packageContentHeight = 0 }
        .hidden()
    }

    private var packageWidth: CGFloat {
        let packages = self.packagesToDisplay
        return self.containerWidth / packages - self.packageHorizontalSpacing * (packages - 1)
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

        // If there are fewer, use actual count
        return min(desiredCount, CGFloat(self.configuration.packages.all.count))
    }

}

// MARK: - Views

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
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
        .padding(.vertical, Self.labelVerticalSeparation * 2.0)
        .padding(.horizontal)
        .foregroundColor(self.configuration.colors.text1Color)
    }

    @ViewBuilder
    private var offerName: some View {
        Group {
            if let offerName = self.package.localization.offerName {
                let components = offerName.split(separator: " ", maxSplits: 2)
                if components.count == 2 {
                    VStack {
                        Text(components[0])
                            .font(self.font(for: .title).bold())

                        Text(components[1])
                            .font(self.font(for: .title3))
                    }
                } else {
                    Text(offerName)
                }
            } else {
                Text(self.package.content.productName)
            }
        }
            .font(self.font(for: .title3).weight(.regular))
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
                .foregroundColor(self.configuration.colors.text1Color)
                .font(self.font(for: .caption).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 2)
                .onSizeChange(.vertical) {
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

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var shouldDisplayPackages: Bool {
        switch self {
        case .fullScreen: return true
        case .overlay, .condensedOverlay: return false
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
struct Template4View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithMultiPackageHorizontalPaywall) {
            Template4View($0)
        }
    }

}

#endif
