//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroEligibilityStateView.swift
//  
//  Created by Nacho Soto on 7/18/23.

import RevenueCat
import SwiftUI

/// A view that can process intro eligibility and display different data based on the result.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct IntroEligibilityStateView: View {

    enum Display {

        case callToAction
        case offerDetails

    }

    private var textWithNoIntroOffer: String?
    private var textWithIntroOffer: String?
    private var introEligibility: IntroEligibilityStatus?
    private var foregroundColor: Color?
    private var alignment: Alignment

    init(
        display: Display,
        localization: ProcessedLocalizedConfiguration,
        introEligibility: IntroEligibilityStatus?,
        foregroundColor: Color? = nil,
        alignment: Alignment = .center
    ) {
        self.init(
            textWithNoIntroOffer: display.textWithNoIntroOffer(localization),
            textWithIntroOffer: display.textWithIntroOffer(localization),
            introEligibility: introEligibility,
            foregroundColor: foregroundColor,
            alignment: alignment
        )
    }

    fileprivate init(
        textWithNoIntroOffer: String?,
        textWithIntroOffer: String?,
        introEligibility: IntroEligibilityStatus?,
        foregroundColor: Color? = nil,
        alignment: Alignment = .center
    ) {
        self.textWithNoIntroOffer = textWithNoIntroOffer
        self.textWithIntroOffer = textWithIntroOffer
        self.introEligibility = introEligibility
        self.foregroundColor = foregroundColor
        self.alignment = alignment
    }

    var body: some View {
        Text(.init(self.text))
            // Hide until we've determined intro eligibility
            // only if there is a custom intro text.
            .withPendingData(self.needsToWaitForIntroEligibility, alignment: self.alignment)
            // Hide if there is no intro but we have no text to ensure layout does not change.
            .hidden(if: self.isNotEligibleForIntro && self.textWithNoIntroOffer == nil)
            .foregroundColor(self.foregroundColor)
            .tint(self.foregroundColor)
    }

    private var text: String {
        if let textWithIntroOffer = self.textWithIntroOffer, self.isEligibleForIntro {
            return textWithIntroOffer
        } else {
            // Display text with intro offer as a backup to ensure layout does not change
            // when switching states.
            return self.textWithNoIntroOffer ?? self.textWithIntroOffer ?? ""
        }
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension IntroEligibilityStateView.Display {

    func textWithNoIntroOffer(_ localization: ProcessedLocalizedConfiguration) -> String? {
        switch self {
        case .callToAction: return localization.callToAction
        case .offerDetails: return localization.offerDetails
        }
    }

    func textWithIntroOffer(_ localization: ProcessedLocalizedConfiguration) -> String? {
        switch self {
        case .callToAction: return localization.callToActionWithIntroOffer
        case .offerDetails: return localization.offerDetailsWithIntroOffer
        }
    }

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension IntroEligibilityStateView {

    var isEligibleForIntro: Bool {
        return self.introEligibility?.isEligible != false
    }

    var isNotEligibleForIntro: Bool {
        return self.introEligibility?.isEligible == false
    }

    var needsToWaitForIntroEligibility: Bool {
        return self.introEligibility == nil && self.textWithIntroOffer != nil
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension View {

    func withPendingData(_ pending: Bool, alignment: Alignment) -> some View {
        self
            .hidden(if: pending)
            .overlay {
                if pending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: alignment)
                }
            }
            .transition(.opacity.animation(Constants.defaultAnimation))
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
struct IntroEligibilityStateView_Previews: PreviewProvider {

    static var previews: some View {
        List {
            Section(header: Text("Loading")) {
                IntroEligibilityStateView(
                    textWithNoIntroOffer: Self.textWithNoIntroOffer,
                    textWithIntroOffer: nil,
                    introEligibility: nil,
                    alignment: .leading
                )
                IntroEligibilityStateView(
                    textWithNoIntroOffer: nil,
                    textWithIntroOffer: Self.textWithIntroOffer,
                    introEligibility: nil,
                    alignment: .leading
                )
            }

            Section(header: Text("Eligible")) {
                IntroEligibilityStateView(
                    textWithNoIntroOffer: Self.textWithNoIntroOffer,
                    textWithIntroOffer: nil,
                    introEligibility: .eligible,
                    alignment: .leading
                )
                IntroEligibilityStateView(
                    textWithNoIntroOffer: nil,
                    textWithIntroOffer: Self.textWithIntroOffer,
                    introEligibility: .eligible,
                    alignment: .leading
                )
                IntroEligibilityStateView(
                    textWithNoIntroOffer: Self.textWithNoIntroOffer,
                    textWithIntroOffer: Self.textWithIntroOffer,
                    introEligibility: .eligible,
                    alignment: .leading
                )
            }

            Section(header: Text("Ineligible")) {
                IntroEligibilityStateView(
                    textWithNoIntroOffer: Self.textWithNoIntroOffer,
                    textWithIntroOffer: nil,
                    introEligibility: .ineligible,
                    alignment: .leading
                )
                IntroEligibilityStateView(
                    textWithNoIntroOffer: Self.textWithNoIntroOffer,
                    textWithIntroOffer: Self.textWithIntroOffer,
                    introEligibility: .ineligible,
                    alignment: .leading
                )
            }
        }
    }

    private static let textWithNoIntroOffer = "$3.99/mo"
    private static let textWithIntroOffer = "7 day trial, then $3.99/mo"

}

#endif
