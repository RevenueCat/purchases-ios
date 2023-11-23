//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template1View.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
struct Template1View: TemplateViewType {

    let configuration: TemplateViewConfiguration
    private var localization: ProcessedLocalizedConfiguration

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
            self.scrollableContent
                .scrollableIfNecessary()
                .scrollBounceBehaviorBasedOnSize()

            Spacer()

            IntroEligibilityStateView(
                display: .offerDetails,
                localization: self.localization,
                introEligibility: self.introEligibility,
                foregroundColor: self.configuration.colors.text1Color
            )
            .font(self.font(for: .callout))
            .multilineTextAlignment(.center)
            .defaultHorizontalPadding()
            .padding(.top, self.defaultVerticalPaddingLength)

            self.button
                .defaultHorizontalPadding()

            FooterView(configuration: self.configuration,
                       purchaseHandler: self.purchaseHandler)
        }
    }

    @ViewBuilder
    private var scrollableContent: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            if self.configuration.mode.isFullScreen {
                self.headerImage

                Group {
                    Text(.init(self.localization.title))
                        .font(self.font(for: .largeTitle))
                        .fontWeight(.heavy)
                        .padding(.bottom)

                    if let subtitle = self.localization.subtitle {
                        Text(.init(subtitle))
                            .font(self.font(for: .subheadline))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .foregroundColor(self.configuration.colors.text1Color)
        .multilineTextAlignment(.center)
        .edgesIgnoringSafeArea(.top)
    }

    @ViewBuilder
    private var asyncImage: some View {
        if let headerImage = self.configuration.headerImageURL {
            RemoteImage(url: headerImage, aspectRatio: self.imageAspectRatio)
            .frame(maxWidth: .infinity)
            .aspectRatio(self.imageAspectRatio, contentMode: .fit)
        }
    }

    @ViewBuilder
    private var headerImage: some View {
        self.asyncImage
            .modifier(CircleMaskModifier())

        Spacer()
    }

    @ViewBuilder
    private var button: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.configuration.packages.default,
            configuration: self.configuration
        )
    }

    // MARK: -

    private var introEligibility: IntroEligibilityStatus? {
        return self.introEligibilityViewModel.singleEligibility
    }

    private var imageAspectRatio: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad:
            return VersionDetector.iOS15
                // iOS 15 has layout issues on iPad landscape, this makes it look better
                ? 2.8
                : 2.0
        default:
            return 1.2
        }
    }

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct CircleMaskModifier: ViewModifier {

    @Environment(\.userInterfaceIdiom)
    private var userInterfaceIdiom

    @State
    private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onSizeChange { self.size = $0 }
            .clipShape(
                Circle()
                    .scale(self.circleScale)
                    .offset(y: self.circleOffset)
            )
    }

    private var circleOffset: CGFloat {
        return (((self.size.height * self.circleScale) - self.size.height) / 2.0 * -1)
            .rounded(.down)
    }

    private var circleScale: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad: return 7
        default: return 3
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct Template1View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithIntroOffer) {
            Template1View($0)
        }
    }

}

#endif
