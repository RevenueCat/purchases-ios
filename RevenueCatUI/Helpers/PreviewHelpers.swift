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

// swiftlint:disable force_unwrapping
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@MainActor
enum PreviewHelpers {

    static let introEligibilityChecker: TrialOrIntroEligibilityChecker = eligibleChecker
    static let eligibleChecker: TrialOrIntroEligibilityChecker = .producing(eligibility: .eligible)
    static let ineligibleChecker: TrialOrIntroEligibilityChecker = .producing(eligibility: .ineligible)
    static let purchaseHandler: PurchaseHandler =
        .mock()
        .with(delay: 0.5)
    static let customFonts: PaywallFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")

    static let fullScreenSize: CGSize = .init(width: 460, height: 950)
    static let landscapeSize: CGSize = .init(width: 950, height: 460)
    static let iPadSize: CGSize = .init(width: 744, height: 1130)
    static let footerSize: CGSize = .init(width: 460, height: 460)

    private static let localBaseURL = Bundle.revenueCatUI.resourceURL ?? Bundle.revenueCatUI.bundleURL
    private static let localImageName = "background.jpg"

    /// Returns a copy of the offering with images pointing to the bundled `background.jpg`
    /// in RevenueCatUI's resources, so previews render without network access.
    static func withLocalImages(_ offering: Offering) -> Offering {
        guard var paywall = offering.paywall else { return offering }

        paywall.assetBaseURL = localBaseURL
        paywall.config.images = .init(
            header: localImageName,
            background: localImageName
        )

        return .init(
            identifier: offering.identifier,
            serverDescription: offering.serverDescription,
            metadata: offering.metadata,
            paywall: paywall,
            availablePackages: offering.availablePackages,
            webCheckoutUrl: nil
        )
    }

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
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PreviewableTemplate<T: TemplateViewType>: View {

    typealias Creator = @Sendable @MainActor (TemplateViewConfiguration) -> T

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    private let configuration: Result<(PaywallTemplate, TemplateViewConfiguration), Error>
    private let presentInSheet: Bool
    private let creator: Creator
    private let purchaseHandler: PurchaseHandler

    @StateObject
    private var introEligibilityViewModel: IntroEligibilityViewModel

    init(
        offering: Offering,
        activelySubscribedProductIdentifiers: Set<String> = [],
        mode: PaywallViewMode = .default,
        presentInSheet: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        locale: Locale = .current,
        introEligibility: IntroEligibilityStatus = .eligible,
        purchaseHandler: PurchaseHandler = PreviewHelpers.purchaseHandler,
        creator: @escaping Creator
    ) {
        let offering = PreviewHelpers.withLocalImages(offering)
        let paywall = offering.paywall!
        let template = PaywallTemplate(rawValue: paywall.templateName)!

        self.configuration = paywall.configuration(
            for: offering,
            activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
            template: template,
            mode: mode,
            fonts: fonts,
            locale: locale,
            showZeroDecimalPlacePrices: false
        ).map { (template, $0) }

        self.presentInSheet = presentInSheet
        self.creator = creator
        self.purchaseHandler = purchaseHandler

        let checker = TrialOrIntroEligibilityChecker.producing(eligibility: introEligibility)
        let viewModel = IntroEligibilityViewModel(introEligibilityChecker: checker)

        // Pre-populate eligibility so pricing is visible on first render,
        // without waiting for an async .task to complete.
        if case let .success((_, config)) = self.configuration {
            let packages = config.packages.all.map(\.content)
            viewModel.allEligibility = Dictionary(
                uniqueKeysWithValues: packages.map { package in
                    let status: IntroEligibilityStatus = package.storeProduct.hasIntroDiscount
                        ? introEligibility
                        : .noIntroOfferExists
                    return (package, status)
                }
            )
        }

        self._introEligibilityViewModel = StateObject(wrappedValue: viewModel)
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
        case let .success((_, configuration)):
            self.creator(configuration)
                .environmentObject(self.introEligibilityViewModel)
                .environmentObject(self.purchaseHandler)
                .adaptTemplateView(with: configuration)
                .disabled(self.purchaseHandler.actionInProgress)

        case let .failure(error):
            DebugErrorView("Invalid configuration: \(error)",
                           releaseBehavior: .fatalError)
        }
    }

}

#endif
