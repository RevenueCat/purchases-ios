//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreviewHelpers.swift
//
//  Created by Nacho Soto on 7/29/23.

import RevenueCat
import SwiftUI

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@MainActor
enum PreviewHelpers {

    static let introEligibilityChecker: TrialOrIntroEligibilityChecker =
        .producing(eligibility: Bool.random() ? .eligible : .ineligible)
        .with(delay: 0.5)
    static let purchaseHandler: PurchaseHandler =
        .mock()
        .with(delay: 0.5)

}

/// Creates an easily previewable `TemplateViewType`.
/// Usage:
/// ```swift
/// PreviewableTemplate(
///   offering: TestData.testOffering
/// ) {
///   PaywallTemplate($0)
/// }
/// ```
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PreviewableTemplate<T: TemplateViewType>: View {

    typealias Creator = @Sendable @MainActor (TemplateViewConfiguration) -> T

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    private let configuration: Result<TemplateViewConfiguration, Error>
    private let presentInSheet: Bool
    private let creator: Creator

    @StateObject
    private var introEligibilityViewModel = IntroEligibilityViewModel(
        introEligibilityChecker: PreviewHelpers.introEligibilityChecker
    )

    init(
        offering: Offering,
        activelySubscribedProductIdentifiers: Set<String> = [],
        mode: PaywallViewMode = .default,
        presentInSheet: Bool = false,
        creator: @escaping Creator
    ) {
        let paywall = offering.paywall!

        self.configuration = paywall.configuration(
            for: offering,
            activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
            template: PaywallTemplate(rawValue: paywall.templateName)!,
            mode: mode,
            fonts: DefaultPaywallFontProvider(),
            locale: .current
        )
        self.presentInSheet = presentInSheet
        self.creator = creator
    }

    var body: some View {
        if self.presentInSheet || self.interfaceIdiom == .pad {
            Rectangle()
                .hidden()
                .sheet(isPresented: .constant(true)) {
                    self.content
                }
        } else {
            self.content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.configuration {
        case let .success(configuration):
            self.creator(configuration)
                .environmentObject(self.introEligibilityViewModel)
                .environmentObject(PreviewHelpers.purchaseHandler)
                .adaptTemplateView(with: configuration)
                .disabled(PreviewHelpers.purchaseHandler.actionInProgress)
                .task {
                    await self.introEligibilityViewModel.computeEligibility(
                        for: configuration.packages
                    )
                }
                .previewDisplayName("\(configuration.mode)")
                .previewLayout(configuration.mode.layout)

        case let .failure(error):
            DebugErrorView("Invalid configuration: \(error)",
                           releaseBehavior: .fatalError)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var layout: PreviewLayout {
        switch self {
        case .fullScreen: return .device
        case .footer: return .fixed(width: 400, height: 280)
        case .condensedFooter: return .fixed(width: 400, height: 150)
        }
    }

}

#endif
