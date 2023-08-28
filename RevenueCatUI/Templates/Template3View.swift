//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template3View.swift
//
//  Created by Nacho Soto on 7/26/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct Template3View: TemplateViewType {

    let configuration: TemplateViewConfiguration
    private let localization: ProcessedLocalizedConfiguration

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
        self.localization = configuration.packages.single.localization
    }

    var body: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.shouldDisplayIcon {
                if let url = self.configuration.iconImageURL {
                    RemoteImage(url: url, aspectRatio: 1)
                        .frame(width: self.iconSize, height: self.iconSize)
                        .cornerRadius(8)
                }
            }

            if self.configuration.mode.shouldDisplayText {
                Text(.init(self.localization.title))
                    .font(self.font(for: .title))
                    .foregroundStyle(self.configuration.colors.text1Color)
                    .multilineTextAlignment(.center)

                Spacer()
            }

            if self.configuration.mode.shouldDisplayFeatures {
                self.features
                    .scrollableIfNecessary()
            }

            Spacer()

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.offerDetails,
                textWithIntroOffer: self.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility,
                foregroundColor: self.configuration.colors.text2Color
            )
            .multilineTextAlignment(.center)
            .font(self.font(for: .subheadline))
            .padding(.bottom)

            PurchaseButton(
                package: self.configuration.packages.single,
                configuration: self.configuration,
                introEligibility: self.introEligibility,
                purchaseHandler: self.purchaseHandler
            )
            .padding(.bottom)

            FooterView(configuration: self.configuration,
                       purchaseHandler: self.purchaseHandler)
        }
        .defaultHorizontalPadding()
        .padding(.top, self.defaultVerticalPaddingLength)
    }

    private var features: some View {
        VStack(spacing: 40) {
            ForEach(self.localization.features, id: \.title) { feature in
                FeatureView(feature: feature,
                            colors: self.configuration.colors,
                            fonts: self.configuration.fonts)
                    .accessibilityElement(children: .combine)
            }
        }
        .defaultHorizontalPadding()
    }

    private var introEligibility: IntroEligibilityStatus? {
        return self.introEligibilityViewModel.singleEligibility
    }

    @ScaledMetric(relativeTo: .title)
    private var iconSize = 65

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct FeatureView: View {

    let feature: PaywallData.LocalizedConfiguration.Feature
    let colors: PaywallData.Configuration.Colors
    let fonts: PaywallFontProvider

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if self.horizontalIconLayout {
                self.icon
            }

            self.content
        }
    }

    private var icon: some View {
        Circle()
            .overlay {
                if let iconName = self.feature.iconID,
                   let icon = PaywallIcon(rawValue: iconName) {
                    IconView(icon: icon, tint: self.colors.accent1Color)
                        .padding(self.iconPadding)
                }
            }
            .foregroundColor(self.colors.accent2Color)
            .frame(width: self.iconSize, height: self.iconSize)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: self.iconPadding * 2) {
                if !self.horizontalIconLayout {
                    self.icon
                }

                Text(.init(self.feature.title))
                    .foregroundStyle(self.colors.text1Color)
                    .font(self.font(for: .headline))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let content = self.feature.content {
                Text(.init(content))
                    .foregroundStyle(self.colors.text2Color)
                    .font(self.font(for: .body))
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.leading)
    }

    /// Determines whether the icon is displayed to the left of `content`.
    private var horizontalIconLayout: Bool {
        return self.dynamicTypeSize < Self.cutoffForHorizontalLayout
    }

    private func font(for textStyle: Font.TextStyle) -> Font {
        return self.fonts.font(for: textStyle)
    }

    @ScaledMetric(relativeTo: .headline)
    private var iconSize = 35

    @ScaledMetric(relativeTo: .headline)
    private var iconPadding = 5

    private static let cutoffForHorizontalLayout: DynamicTypeSize = .xxxLarge

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct Template3View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithSinglePackageFeaturesPaywall) {
            Template3View($0)
        }
    }

}

#endif
