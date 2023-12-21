//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WatchTemplateView.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

#if os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct WatchTemplateView: TemplateViewType {

    let configuration: TemplateViewConfiguration

    @State
    private var selectedPackage: TemplateViewConfiguration.Package

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    #if swift(>=5.9)
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
    }

    var body: some View {
        ScrollView {
            VStack(spacing: self.defaultVerticalPaddingLength) {
                if let url = self.configuration.headerImageURL {
                    RemoteImage(url: url, aspectRatio: Self.imageAspectRatio, maxWidth: .infinity)
                        .clipped()
                        .roundedCorner(Self.imageRoundedCorner, corners: [.bottomLeft, .bottomRight])
                        .padding(.bottom)
                }

                Group {
                    Text(.init(self.selectedLocalization.title))
                        .font(self.font(for: .title3))
                        .fontWeight(.semibold)

                    if let subtitle = self.selectedLocalization.subtitle {
                        Text(.init(subtitle))
                            .font(self.font(for: .subheadline))
                    }

                    if let package = self.configuration.packages.singleIfNotMultiple {
                        self.offerDetails(package: package, selected: false)
                            .padding(.top, self.defaultVerticalPaddingLength)
                    }

                    self.packages
                        .padding(.top, self.defaultVerticalPaddingLength)

                    self.button

                    FooterView(configuration: self.configuration,
                               purchaseHandler: self.purchaseHandler)
                }
                .defaultHorizontalPadding()
            }
            .foregroundColor(self.configuration.colors.text1Color)
            .multilineTextAlignment(.center)
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .background {
            TemplateBackgroundImageView(configuration: self.configuration)
        }
        .edgesIgnoringSafeArea(.horizontal)
        .edgesIgnoringSafeArea(
            self.configuration.headerImageURL != nil
            ? .top
            : []
        )
    }

    @ViewBuilder
    private var packages: some View {
        if self.configuration.packages.all.count > 1 {
            VStack(spacing: 8) {
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

            Spacer()
        }
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            self.packageButtonTitle(package, selected: selected)
                .font(self.font(for: .body).weight(.medium))

            self.offerDetails(package: package, selected: selected)
                .font(self.font(for: .caption2))
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .defaultPadding()
        .overlay {
            if selected {
                EmptyView()
            } else {
                self.roundedRectangle
                    .stroke(self.configuration.colors.text1Color,
                            lineWidth: 1)
            }
        }
        .background {
            if selected {
                self.roundedRectangle
                    .foregroundColor(self.configuration.colors.callToActionBackgroundColor)
            } else {
                if self.configuration.backgroundImageURLToDisplay != nil {
                    #if swift(>=5.9)
                    if #available(watchOS 10.0, *) {
                        // Blur background if there is a background image.
                        self.roundedRectangle.foregroundStyle(.thinMaterial)
                    } else {
                        self.fadedBackgroundRectangle
                    }
                    #else
                    self.fadedBackgroundRectangle
                    #endif
                } else {
                    // Otherwise the text should have enough contrast with the selected background color.
                    EmptyView()
                }
            }
        }
    }

    private var fadedBackgroundRectangle: some View {
        self.roundedRectangle
            .opacity(0.3)
    }

    private func offerDetails(package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        IntroEligibilityStateView(
            display: .offerDetails,
            localization: package.localization,
            introEligibility: self.introEligibility[package.content],
            foregroundColor: self.textColor(selected)
        )
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
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
                            .foregroundColor(self.configuration.colors.callToActionBackgroundColor.opacity(0.3))
                    }
                }

            Text(package.localization.offerName ?? package.content.productName)
        }
        .foregroundColor(self.textColor(selected))
    }

    @ViewBuilder
    private var button: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.selectedPackage,
            configuration: self.configuration
        )
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: Constants.defaultPackageCornerRadius, style: .continuous)
    }

    private func textColor(_ selected: Bool) -> Color {
        return selected
        ? self.configuration.colors.accent1Color
        : self.configuration.colors.text1Color
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.selectedPackage.localization
    }

    private static let imageAspectRatio: CGFloat = 1.2
    private static let imageRoundedCorner: CGFloat = 30

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct WatchTemplateView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach([
            TestData.offeringWithIntroOffer,
            TestData.offeringWithMultiPackagePaywall
        ], id: \.self) { offering in
            PreviewableTemplate(offering: offering) {
                WatchTemplateView($0)
            }
        }
    }

}

#endif

#endif
