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

    var textWithNoIntroOffer: String
    var textWithIntroOffer: String?
    var introEligibility: IntroEligibilityStatus?

    init(
        textWithNoIntroOffer: String,
        textWithIntroOffer: String?,
        introEligibility: IntroEligibilityStatus?
    ) {
        self.textWithNoIntroOffer = textWithNoIntroOffer
        self.textWithIntroOffer = textWithIntroOffer
        self.introEligibility = introEligibility
    }

    var body: some View {
        Text(self.text)
            // Hide until we've determined intro eligibility
            // only if there is a custom intro text.
            .withPendingData(self.needsToWaitForIntroEligibility)
    }

    private var text: String {
        if let textWithIntroOffer = self.textWithIntroOffer, self.isEligibleForIntro {
            return textWithIntroOffer
        } else {
            return self.textWithNoIntroOffer
        }
    }

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension IntroEligibilityStateView {

    var isEligibleForIntro: Bool {
        return self.introEligibility?.isEligible != false
    }

    var needsToWaitForIntroEligibility: Bool {
        return self.introEligibility == nil && self.textWithIntroOffer != nil
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension View {

    func withPendingData(_ pending: Bool) -> some View {
        self
            .hidden(if: pending)
            .overlay {
                if pending {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .transition(.opacity.animation(Constants.defaultAnimation))
    }

}
