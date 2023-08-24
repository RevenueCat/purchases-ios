//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateViewType.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

/*
 This file is the entry point to all templates.
 
 For future developers implementing new templates, here are a few recommended principles to follow:
 - Avoid magic numbers as much as possible. Use `@ScaledMetric` if necessary.
 - Prefer reusable views over custom implementations:
    - `FooterView`
    - `PurchaseButton`
    - `RemoteImage`
    - `IntroEligibilityStateView`
    - `IconView`
 - Consider everything beyond the "basic"s:
    - iPad
    - VoiceOver / A11y
    - Dynamic Type
    - All `PaywallViewMode`s
 - Fonts: use `PaywallFontProvider` to derive fonts
 - Colors: avoid hardcoded colors
*/

/// A `SwiftUI` view that can display a paywall with `TemplateViewConfiguration`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
protocol TemplateViewType: SwiftUI.View {

    var configuration: TemplateViewConfiguration { get }
    var userInterfaceIdiom: UserInterfaceIdiom { get }

    init(_ configuration: TemplateViewConfiguration)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewType {

    func font(for textStyle: Font.TextStyle) -> Font {
        return self.configuration.fonts.font(for: textStyle)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallTemplate {

    var packageSetting: TemplateViewConfiguration.PackageSetting {
        switch self {
        case .template1: return .single
        case .template2: return .multiple
        case .template3: return .single
        case .template4: return .multiple
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
extension PaywallData {

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func createView(for offering: Offering,
                    activelySubscribedProductIdentifiers: Set<String>,
                    template: PaywallTemplate,
                    mode: PaywallViewMode,
                    fonts: PaywallFontProvider,
                    introEligibility: IntroEligibilityViewModel,
                    locale: Locale) -> some View {
        switch self.configuration(for: offering,
                                  activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                                  template: template,
                                  mode: mode,
                                  fonts: fonts,
                                  locale: locale) {
        case let .success(configuration):
            Self.createView(template: template, configuration: configuration)
                .task(id: offering) {
                    await introEligibility.computeEligibility(for: configuration.packages)
                }
                .background(configuration.backgroundView)

        case let .failure(error):
            DebugErrorView(error, releaseBehavior: .emptyView)
        }
    }

    // swiftlint:disable:next function_parameter_count
    func configuration(
        for offering: Offering,
        activelySubscribedProductIdentifiers: Set<String>,
        template: PaywallTemplate,
        mode: PaywallViewMode,
        fonts: PaywallFontProvider,
        locale: Locale
    ) -> Result<TemplateViewConfiguration, Error> {
        return Result {
            TemplateViewConfiguration(
                mode: mode,
                packages: try .create(with: offering.availablePackages,
                                      activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                                      filter: self.config.packages,
                                      default: self.config.defaultPackage,
                                      localization: self.localizedConfiguration,
                                      setting: template.packageSetting,
                                      locale: locale),
                configuration: self.config,
                colors: self.config.colors.multiScheme,
                fonts: fonts,
                assetBaseURL: self.assetBaseURL
            )
        }
    }

    @ViewBuilder
    private static func createView(template: PaywallTemplate,
                                   configuration: TemplateViewConfiguration) -> some View {
        switch template {
        case .template1:
            Template1View(configuration)
        case .template2:
            Template2View(configuration)
        case .template3:
            Template3View(configuration)
        case .template4:
            Template4View(configuration)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration {

    @ViewBuilder
    var backgroundView: some View {
        switch self.mode {
        case .fullScreen:
            self.backgroundContent
        case .footer, .condensedFooter:
            self.backgroundContent
            #if canImport(UIKit)
                .roundedCorner(
                    Constants.defaultCornerRadius,
                    corners: [.topLeft, .topRight],
                    edgesIgnoringSafeArea: .all
                )
            #endif
        }
    }

    @ViewBuilder
    private var backgroundContent: some View {
        let view = Rectangle()
            .edgesIgnoringSafeArea(.all)

        if self.configuration.blurredBackgroundImage {
            view.foregroundStyle(.thinMaterial)
        } else {
            view.foregroundStyle(self.colors.backgroundColor)
        }
    }

}
