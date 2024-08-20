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

// swiftlint:disable type_body_length

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *)
struct Template2View: TemplateViewType {

    let configuration: TemplateViewConfiguration

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(self.configuration.mode.isFullScreen ? .top : [])
            .animation(Constants.fastAnimation, value: self.selectedPackage)
            .background {
                TemplateBackgroundImageView(configuration: self.configuration)
            }
    }

    @ViewBuilder
    private var verticalFullScreenContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            // Avoid unnecessary spacing, except for iOS 15 because SwiftUI breaks the layout.
            Spacer(minLength: VersionDetector.iOS15 ? nil : 0)

            self.scrollableContent
                .scrollableIfNecessary(enabled: self.configuration.mode.isFullScreen)

            if self.configuration.mode.shouldDisplayInlineOfferDetails(displayingAllPlans: self.displayingAllPlans) {
                self.offerDetails(package: self.selectedPackage, selected: false)
            }

            self.subscribeButton
                .defaultHorizontalPadding()

            self.footer
        }
        .multilineTextAlignment(.center)
        .padding(
            .top,
            self.displayingAllPlans
            ? self.defaultVerticalPaddingLength
            // Compensate for additional padding on condensed mode + iPad
            : self.defaultVerticalPaddingLength.map { $0 * -1 }
        )
    }

    @ViewBuilder
    private var horizontalContent: some View {
        VStack {
            HStack {
                VStack {
                    Spacer()
                    self.iconImage
                    Spacer()
                    self.title
                    Spacer()
                    self.subtitle
                    Spacer()
                }
                .scrollableIfNecessary()
                .frame(maxHeight: .infinity)

                VStack(spacing: self.defaultVerticalPaddingLength) {
                    Spacer()

                    self.packages
                        .scrollableIfNecessary()

                    Spacer(minLength: self.defaultVerticalPaddingLength)

                    self.subscribeButton
                }
                .frame(maxHeight: .infinity)
            }

            self.footer
        }
    }

    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.isFullScreen {
                Spacer()
                self.iconImage
                Spacer()

                self.title

                Spacer()

                self.subtitle

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
            .foregroundColor(self.configuration.colors.text1Color)
            .font(self.font(for: .largeTitle).bold())
            .defaultHorizontalPadding()
    }

    private var subtitle: some View {
        Text(.init(self.selectedLocalization.subtitle ?? ""))
            .foregroundColor(self.configuration.colors.text1Color)
            .font(self.font(for: .title3))
            .defaultHorizontalPadding()
    }

    @ViewBuilder
    private var packages: some View {
        VStack(spacing: Constants.defaultPackageVerticalSpacing / 2.0) {
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
    }

    @ViewBuilder
    private var packagesWithBottomSpacer: some View {
        self.packages
            .padding(.horizontal, self.defaultHorizontalPaddingLength)

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
                    .stroke(self.configuration.colors.text1Color.opacity(Self.fadedColorOpacity),
                            lineWidth: Constants.defaultPackageBorderWidth)
            }
        }
        .background {
            if selected {
                self.roundedRectangle
                    .foregroundColor(self.selectedBackgroundColor)
            } else {
                #if !os(watchOS)
                if self.configuration.backgroundImageURLToDisplay != nil {
                    // Blur background if there is a background image.
                    self.roundedRectangle
                        .foregroundStyle(.thinMaterial)
                } else {
                    // Otherwise the text should have enough contrast with the selected background color.
                    EmptyView()
                }
                #endif
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
            Constants.checkmarkImage
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
            display: .offerDetails,
            localization: package.localization,
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
            packages: self.configuration.packages,
            selectedPackage: self.selectedPackage,
            configuration: self.configuration
        )
    }

    private var footer: some View {
        FooterView(configuration: self.configuration,
                   locale: self.selectedLocalization.locale,
                   purchaseHandler: self.purchaseHandler,
                   displayingAllPlans: self.$displayingAllPlans)
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            #if canImport(UIKit)
            if let iconUrl = self.configuration.iconImageURL {
                let iconLowResURL = self.configuration.iconLowResImageURL
                Group {
                    if iconUrl.pathComponents.contains(PaywallData.appIconPlaceholder) {
                        if let appIcon = Bundle.main.appIcon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: self.appIconSize, height: self.appIconSize)
                        } else {
                            self.placeholderIconImage
                        }
                    } else {
                        RemoteImage(url: iconUrl, lowResUrl: iconLowResURL, aspectRatio: 1, maxWidth: self.iconSize)
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
    private static let cornerRadius: CGFloat = Constants.defaultPackageCornerRadius
    private static let packageButtonAlignment: Alignment = .leading

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *)
private extension Template2View {

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.selectedPackage.localization
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
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
