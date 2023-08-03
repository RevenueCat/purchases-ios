//
//  IntroEligibilityStateView.swift
//  
//
//  Created by Nacho Soto on 7/18/23.
//

import RevenueCat
import SwiftUI

/// A view that can process intro eligibility and display different data based on the result.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct IntroEligibilityStateView: View {

    var textWithNoIntroOffer: String?
    var textWithIntroOffer: String?
    var introEligibility: IntroEligibilityStatus?
    var foregroundColor: Color?
    var alignment: Alignment

    init(
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
        Text(self.text)
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

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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
