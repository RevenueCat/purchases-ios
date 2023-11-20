//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateViewConfiguration+Extensions.swift
//
//  Created by Nacho Soto on 11/19/23.

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// - Returns: `true` if the packages contain more than one different text
    /// for the given `display`.
    /// This allows determining whether animations are required when transitioning between
    /// packages.
    @MainActor
    func packagesProduceDifferentLabels(
        for display: IntroEligibilityStateView.Display,
        eligibility: IntroEligibilityViewModel
    ) -> Bool {
        return self.packagesProduceDifferentLabels(
            for: display,
            eligibility: eligibility.allEligibility
        )
    }

    /// - Returns: `true` if any of the packages produce text for the given `display`.
    /// This allows determining whether a label is required to be rendered.
    @MainActor
    func packagesProduceAnyLabel(
        for display: IntroEligibilityStateView.Display,
        eligibility: IntroEligibilityViewModel
    ) -> Bool {
        return self.packagesProduceAnyLabel(
            for: display,
            eligibility: eligibility.allEligibility
        )
    }

}

// MARK: - Implementation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    typealias Eligibility = [Package: IntroEligibilityStatus]

    func packagesProduceDifferentLabels(
        for display: IntroEligibilityStateView.Display,
        eligibility: Eligibility
    ) -> Bool {
        return self.labels(for: display, eligibility: eligibility).count > 1
    }

    func packagesProduceAnyLabel(
        for display: IntroEligibilityStateView.Display,
        eligibility: Eligibility
    ) -> Bool {
        return self
            .labels(for: display, eligibility: eligibility)
            .contains { !$0.isEmpty }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TemplateViewConfiguration.PackageConfiguration {

    private func labels(
        for display: IntroEligibilityStateView.Display,
        eligibility: Eligibility
    ) -> Set<String> {
        return Set(
            self.all
            .lazy
            .map {
                IntroEligibilityStateView.text(
                    for: display,
                    localization: $0.localization,
                    introEligibility: eligibility[$0.content]
                )
            }
        )
    }

}
