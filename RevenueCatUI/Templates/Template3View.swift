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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
struct Template3View: TemplateViewType {

    let configuration: TemplateViewConfiguration
    private let localization: ProcessedLocalizedConfiguration

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

    @Namespace
    private var namespace

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
        self.localization = configuration.packages.single.localization
    }

    var body: some View {
        Group {
            if self.shouldUseLandscapeLayout {
                self.horizontalFullScreenContent
            } else {
                self.verticalContent
            }
        }
            .defaultHorizontalPadding()
            .padding(.top, self.defaultVerticalPaddingLength)
    }

    @ViewBuilder
    private var horizontalFullScreenContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: self.defaultVerticalPaddingLength) {
                VStack {
                    self.headerIcon
                        .padding(.bottom, self.defaultVerticalPaddingLength)
                    self.title
                }

                Spacer()

                VStack {
                    self.features
                    Spacer()
                    self.offerDetails
                    self.purchaseButton
                }
            }

            self.footer
        }
    }

    @ViewBuilder
    private var verticalContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.isFullScreen {
                self.headerIcon

                self.title

                Spacer()

                self.features
            }

            Spacer()

            self.offerDetails
                .padding(.bottom)

            self.purchaseButton

            self.footer
        }
    }

    @ViewBuilder
    private var headerIcon: some View {
        if let iconImageURL = self.configuration.iconImageURL {
            let iconImageLowResURL = self.configuration.iconLowResImageURL
            RemoteImage(url: iconImageURL, lowResUrl: iconImageLowResURL, aspectRatio: 1)
                .frame(width: self.iconSize, height: self.iconSize)
                .cornerRadius(8)
                .matchedGeometryEffect(id: Geometry.icon, in: self.namespace)
        }
    }

    private var title: some View {
        Text(.init(self.localization.title))
            .font(self.font(for: .title))
            .foregroundStyle(self.configuration.colors.text1Color)
            .multilineTextAlignment(.center)
            .matchedGeometryEffect(id: Geometry.title, in: self.namespace)
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
        .scrollableIfNecessary()
        .matchedGeometryEffect(id: Geometry.features, in: self.namespace)
    }

    private var offerDetails: some View {
        IntroEligibilityStateView(
            display: .offerDetails,
            localization: self.localization,
            introEligibility: self.introEligibility,
            foregroundColor: self.configuration.colors.text2Color
        )
        .multilineTextAlignment(.center)
        .font(self.font(for: .subheadline))
        .matchedGeometryEffect(id: Geometry.offerDetails, in: self.namespace)
    }

    private var purchaseButton: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.configuration.packages.default,
            configuration: self.configuration
        )
        .matchedGeometryEffect(id: Geometry.purchaseButton, in: self.namespace)
    }

    private var footer: some View {
        FooterView(configuration: self.configuration,
                   locale: self.localization.locale,
                   purchaseHandler: self.purchaseHandler)
    }

    // MARK: -

    private var introEligibility: IntroEligibilityStatus? {
        return self.introEligibilityViewModel.singleEligibility
    }

    @ScaledMetric(relativeTo: .title)
    private var iconSize = 65

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension Template3View {

    enum Geometry: Hashable {
        case icon
        case title
        case features
        case offerDetails
        case purchaseButton
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
                if let icon = self.feature.icon {
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
