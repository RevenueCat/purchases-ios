//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template2View.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct Template2View: TemplateViewType {

    let configuration: TemplateViewConfiguration

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @State
    private var displayingAllPlans: Bool

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

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
            .background {
                TemplateBackgroundImageView(configuration: self.configuration)
            }
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            Spacer()

            self.scrollableContent
                .scrollableIfNecessary(enabled: self.configuration.mode.shouldDisplayPackages)

            if self.configuration.mode.shouldDisplayInlineOfferDetails {
                self.offerDetails(package: self.selectedPackage, selected: false)
            }

            self.subscribeButton
                .defaultHorizontalPadding()

            FooterView(configuration: self.configuration,
                       purchaseHandler: self.purchaseHandler,
                       displayingAllPlans: self.$displayingAllPlans)
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.shouldDisplayIcon {
                Spacer()
                self.iconImage
                Spacer()
            }

            if self.configuration.mode.shouldDisplayText {
                Text(.init(self.selectedLocalization.title))
                    .foregroundColor(self.configuration.colors.text1Color)
                    .font(self.font(for: .largeTitle).bold())
                    .defaultHorizontalPadding()

                Spacer()

                Text(.init(self.selectedLocalization.subtitle ?? ""))
                    .foregroundColor(self.configuration.colors.text1Color)
                    .font(self.font(for: .title3))
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
    private var packages: some View {
        VStack(spacing: 8) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.selectedPackage.content === package.content

                Button {
                    self.selectedPackage = package
                } label: {
                    self.packageButton(package, selected: isSelected)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PackageButtonStyle(isSelected: isSelected))
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
            if selected {
                EmptyView()
            } else {
                self.roundedRectangle
                    .stroke(self.configuration.colors.text1Color.opacity(Self.fadedColorOpacity), lineWidth: 2)
            }
        }
        .background {
            if selected {
                self.roundedRectangle
                    .foregroundColor(self.selectedBackgroundColor)
            } else {
                if self.configuration.backgroundImageURLToDisplay != nil {
                    // Blur background if there is a background image.
                    self.roundedRectangle
                        .foregroundStyle(.thinMaterial)
                } else {
                    // Otherwise the text should have enough contrast with the selected background color.
                    EmptyView()
                }
            }
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
            Image(systemName: "checkmark.circle.fill")
                .hidden(if: !selected)
                .overlay {
                    if selected {
                        EmptyView()
                    } else {
                        Circle()
                            .foregroundColor(self.selectedBackgroundColor.opacity(Self.fadedColorOpacity))
                    }
                }

            Text(package.localization.offerName ?? package.content.productName)
        }
        .foregroundColor(self.textColor(selected))
    }

    private func offerDetails(package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        IntroEligibilityStateView(
            textWithNoIntroOffer: package.localization.offerDetails,
            textWithIntroOffer: package.localization.offerDetailsWithIntroOffer,
            introEligibility: self.introEligibility[package.content],
            foregroundColor: self.textColor(selected),
            alignment: Self.packageButtonAlignment
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
    }

    private func textColor(_ selected: Bool) -> Color {
        return selected
        ? self.configuration.colors.accent1Color
        : self.configuration.colors.text1Color
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            configuration: self.configuration,
            introEligibility: self.introEligibility[self.selectedPackage.content],
            purchaseHandler: self.purchaseHandler
        )
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            #if canImport(UIKit)
            if let url = self.configuration.iconImageURL {
                Group {
                    if url.pathComponents.contains(PaywallData.appIconPlaceholder) {
                        if let appIcon = Bundle.main.appIcon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: self.appIconSize, height: self.appIconSize)
                        } else {
                            self.placeholderIconImage
                        }
                    } else {
                        RemoteImage(url: url, aspectRatio: 1, maxWidth: self.iconSize)
                    }
                }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                self.placeholderIconImage
            }
            #else
            self.placeholderIconImage
            #endif
        }
        .padding(.top)
    }

    private var placeholderIconImage: some View {
        // Placeholder to be able to add a consistent padding
        Text(verbatim: "")
            .hidden()
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var selectedBackgroundColor: Color { self.configuration.colors.accent2Color }

    @ScaledMetric(relativeTo: .largeTitle)
    private var appIconSize: CGFloat = 100
    @ScaledMetric(relativeTo: .largeTitle)
    private var iconSize: CGFloat = 140

    private static let fadedColorOpacity: CGFloat = 0.3
    private static let cornerRadius: CGFloat = 15
    private static let packageButtonAlignment: Alignment = .leading

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
private extension Template2View {

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.selectedPackage.localization
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var shouldDisplayPackages: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

    var shouldDisplayInlineOfferDetails: Bool {
        switch self {
        case .fullScreen: return false
        case .footer, .condensedFooter: return true
        }
    }

}

#if canImport(UIKit)
private extension Bundle {

    var appIcon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return .init(named: lastIcon)
        }
        return nil
    }

}
#endif

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(macCatalyst, unavailable)
struct Template2View_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            PreviewableTemplate(
                offering: TestData.offeringWithMultiPackagePaywall,
                mode: mode
            ) {
                Template2View($0)
            }
        }
    }

}

#endif
