//
//  OnePackageWithFeaturesTemplate.swift
//  
//
//  Created by Nacho Soto on 7/26/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct OnePackageWithFeaturesTemplate: TemplateViewType {

    private let configuration: TemplateViewConfiguration
    @EnvironmentObject
    private var introEligibility: IntroEligibilityViewModel

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        OnePackageWithFeaturesTemplateContent(
            configuration: self.configuration,
            introEligibility: self.introEligibility.singleEligibility
        )
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct OnePackageWithFeaturesTemplateContent: View {

    private var configuration: TemplateViewConfiguration
    private var introEligibility: IntroEligibilityStatus?
    private var localization: ProcessedLocalizedConfiguration

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(configuration: TemplateViewConfiguration, introEligibility: IntroEligibilityStatus?) {
        self.configuration = configuration
        self.introEligibility = introEligibility
        self.localization = configuration.packages.single.localization
    }

    var body: some View {
        ZStack {
            self.background

            self.content
        }
    }

    private var content: some View {
        VStack {
            if let url = self.configuration.iconImageURL {
                RemoteImage(url: url)
                    .frame(width: self.iconSize, height: self.iconSize)
                    .cornerRadius(8)
            }

            Text(self.localization.title)
                .font(.title)
                .foregroundStyle(self.configuration.colors.text1Color)
                .multilineTextAlignment(.center)

            Spacer()

            self.features
                .scrollableIfNecessary()

            Spacer()

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.offerDetails,
                textWithIntroOffer: self.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility,
                foregroundColor: self.configuration.colors.accent2Color
            )
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .padding(.bottom)

            PurchaseButton(
                package: self.configuration.packages.single.content,
                purchaseHandler: self.purchaseHandler,
                colors: self.configuration.colors,
                localization: self.localization,
                introEligibility: self.introEligibility,
                mode: self.configuration.mode
            )
            .padding(.bottom)

            FooterView(configuration: self.configuration.configuration,
                       color: self.configuration.colors.accent2Color,
                       purchaseHandler: self.purchaseHandler)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var features: some View {
        VStack(spacing: 20) {
            ForEach(self.localization.features, id: \.title) { feature in
                FeatureView(feature: feature, colors: self.configuration.colors)
                    .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal)
    }

    private var background: some View {
        Rectangle()
            .foregroundStyle(self.configuration.colors.backgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }

    @ScaledMetric(relativeTo: .title)
    private var iconSize = 55

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct FeatureView: View {

    let feature: PaywallData.LocalizedConfiguration.Feature
    let colors: PaywallData.Configuration.Colors

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
            .foregroundColor(.black)
            .frame(width: self.iconSize, height: self.iconSize)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: self.iconPadding * 2) {
                if !self.horizontalIconLayout {
                    self.icon
                }

                Text(self.feature.title)
                    .foregroundStyle(self.colors.text1Color)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let content = self.feature.content {
                Text(content)
                    .foregroundStyle(self.colors.accent2Color)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.leading)
    }

    /// Determines whether the icon is displayed to the left of `content`.
    private var horizontalIconLayout: Bool {
        return self.dynamicTypeSize < Self.cutoffForHorizontalLayout
    }

    @ScaledMetric(relativeTo: .headline)
    private var iconSize = 35

    @ScaledMetric(relativeTo: .headline)
    private var iconPadding = 5

    private static let cutoffForHorizontalLayout: DynamicTypeSize = .xxxLarge

}
