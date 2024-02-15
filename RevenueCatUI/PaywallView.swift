//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallView.swift
//
//  Created by Nacho Soto.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS)

/// A SwiftUI view for displaying a `PaywallData` for an `Offering`.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
public struct PaywallView: View {

    private let contentToDisplay: PaywallViewConfiguration.Content
    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider
    private let displayCloseButton: Bool

    @Environment(\.locale)
    private var locale

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @StateObject
    private var introEligibility: TrialOrIntroEligibilityChecker

    @State
    private var offering: Offering?
    @State
    private var customerInfo: CustomerInfo?
    @State
    private var error: NSError?

    /// Create a view to display the paywall in `Offerings.current`.
    ///
    /// - Parameter fonts: An optional ``PaywallFontProvider``.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    ///
    /// - Note: If loading the current `Offering` fails (if the user is offline, for example),
    /// an error will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    /// If you want to handle that, you can use ``init(offering:)`` instead.
    public init(
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false
    ) {
        self.init(
            configuration: .init(
                fonts: fonts,
                displayCloseButton: displayCloseButton
            )
        )
    }

    /// Create a view to display the paywall in a given `Offering`.
    ///
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// - Parameter fonts: An optional `PaywallFontProvider`.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    ///
    /// - Note: if `offering` does not have a current paywall, or it fails to load due to invalid data,
    /// a default paywall will be displayed.
    /// - Note: Specifying this parameter means that it will ignore the offering configured in an active experiment.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(
        offering: Offering,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false
    ) {
        self.init(
            configuration: .init(
                offering: offering,
                fonts: fonts,
                displayCloseButton: displayCloseButton
            )
        )
    }

    init(configuration: PaywallViewConfiguration) {
        self._introEligibility = .init(wrappedValue: configuration.introEligibility ?? .default())
        self._purchaseHandler = .init(wrappedValue: configuration.purchaseHandler ?? .default())
        self._offering = .init(
            initialValue: configuration.content.extractInitialOffering()
        )
        self._customerInfo = .init(
            initialValue: configuration.customerInfo ?? Self.loadCachedCustomerInfoIfPossible()
        )
        self.contentToDisplay = configuration.content
        self.mode = configuration.mode
        self.fonts = configuration.fonts
        self.displayCloseButton = configuration.displayCloseButton
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        self.content
            .displayError(self.$error, dismissOnClose: true)
    }

    @MainActor
    @ViewBuilder
    private var content: some View {
        VStack { // Necessary to work around FB12674350 and FB12787354
            if self.introEligibility.isConfigured, self.purchaseHandler.isConfigured {
                if let offering = self.offering, let customerInfo = self.customerInfo {
                    self.paywallView(for: offering,
                                     activelySubscribedProductIdentifiers: customerInfo.activeSubscriptions,
                                     fonts: self.fonts,
                                     checker: self.introEligibility,
                                     purchaseHandler: self.purchaseHandler)
                    .transition(Self.transition)
                } else {
                    LoadingPaywallView(mode: self.mode, displayCloseButton: self.displayCloseButton)
                        .transition(Self.transition)
                        .task {
                            do {
                                guard Purchases.isConfigured else {
                                    throw PaywallError.purchasesNotConfigured
                                }

                                if self.offering == nil {
                                    self.offering = try await self.loadOffering()
                                }

                                if self.customerInfo == nil {
                                    self.customerInfo = try await Purchases.shared.customerInfo()
                                }
                            } catch let error as NSError {
                                self.error = error
                            }
                        }
                }
            } else {
                DebugErrorView("Purchases has not been configured.", releaseBehavior: .fatalError)
            }
        }
    }

    @ViewBuilder
    private func paywallView(
        for offering: Offering,
        activelySubscribedProductIdentifiers: Set<String>,
        fonts: PaywallFontProvider,
        checker: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) -> some View {
        let (paywall, template, error) = offering.validatedPaywall(locale: self.locale)

        let paywallView = LoadedOfferingPaywallView(
            offering: offering,
            activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
            paywall: paywall,
            template: template,
            mode: self.mode,
            fonts: fonts,
            displayCloseButton: self.displayCloseButton,
            introEligibility: checker,
            purchaseHandler: purchaseHandler
        )

        if let error {
            DebugErrorView(
                "\(error.description)\n" +
                "You can fix this by editing the paywall in the RevenueCat dashboard.\n" +
                "The displayed paywall contains default configuration.\n" +
                "This error will be hidden in production.",
                replacement: paywallView
            )
        } else {
            paywallView
        }
    }

    // MARK: -

    private static let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private extension PaywallView {

    static func loadCachedCustomerInfoIfPossible() -> CustomerInfo? {
        if Purchases.isConfigured {
            return Purchases.shared.cachedCustomerInfo
        } else {
            return nil
        }
    }

    func loadOffering() async throws -> Offering {
        switch self.contentToDisplay {
        case let .offering(offering):
            return offering

        case .defaultOffering:
            return try await Purchases.shared.offerings().current.orThrow(PaywallError.noCurrentOffering)

        case let .offeringIdentifier(identifier):
            return try await Purchases.shared.offerings()
                .offering(identifier: identifier)
                .orThrow(PaywallError.offeringNotFound(identifier: identifier))
        }
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewConfiguration.Content {

    func extractInitialOffering() -> Offering? {
        switch self {
        case let .offering(offering): return offering
        case .defaultOffering: return Self.loadCachedCurrentOfferingIfPossible()
        case .offeringIdentifier: return nil
        }
    }

    private static func loadCachedCurrentOfferingIfPossible() -> Offering? {
        if Purchases.isConfigured {
            return Purchases.shared.cachedOfferings?.current
        } else {
            return nil
        }
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct LoadedOfferingPaywallView: View {

    private let offering: Offering
    private let activelySubscribedProductIdentifiers: Set<String>
    private let paywall: PaywallData
    private let template: PaywallTemplate
    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider
    private let displayCloseButton: Bool

    @StateObject
    private var introEligibility: IntroEligibilityViewModel
    @ObservedObject
    private var purchaseHandler: PurchaseHandler

    @Environment(\.locale)
    private var locale

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.dismiss)
    private var dismiss

    init(
        offering: Offering,
        activelySubscribedProductIdentifiers: Set<String>,
        paywall: PaywallData,
        template: PaywallTemplate,
        mode: PaywallViewMode,
        fonts: PaywallFontProvider,
        displayCloseButton: Bool,
        introEligibility: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) {
        self.offering = offering
        self.activelySubscribedProductIdentifiers = activelySubscribedProductIdentifiers
        self.paywall = paywall
        self.template = template
        self.mode = mode
        self.fonts = fonts
        self.displayCloseButton = displayCloseButton
        self._introEligibility = .init(
            wrappedValue: .init(introEligibilityChecker: introEligibility)
        )
        self._purchaseHandler = .init(initialValue: purchaseHandler)
    }

    var body: some View {
        // Note: preferences need to be applied after `.toolbar` call
        self.content
            .preference(key: PurchasedInProgressPreferenceKey.self,
                        value: self.purchaseHandler.purchaseInProgress)
            .preference(key: PurchasedResultPreferenceKey.self,
                        value: .init(data: self.purchaseHandler.purchaseResult))
            .preference(key: RestoredCustomerInfoPreferenceKey.self,
                        value: self.purchaseHandler.restoredCustomerInfo)
            .preference(key: PurchaseErrorPreferenceKey.self,
                        value: self.purchaseHandler.purchaseError as NSError?)
            .preference(key: RestoreErrorPreferenceKey.self,
                        value: self.purchaseHandler.restoreError as NSError?)
    }

    @ViewBuilder
    private var content: some View {
        let view = self.paywall
            .createView(for: self.offering,
                        activelySubscribedProductIdentifiers: self.activelySubscribedProductIdentifiers,
                        template: self.template,
                        mode: self.mode,
                        fonts: self.fonts,
                        introEligibility: self.introEligibility,
                        locale: self.locale)
            .environmentObject(self.introEligibility)
            .environmentObject(self.purchaseHandler)
            .disabled(self.purchaseHandler.actionInProgress)
            .onAppear { self.purchaseHandler.trackPaywallImpression(self.createEventData()) }
            .onDisappear { self.purchaseHandler.trackPaywallClose() }
            .onChangeOf(self.purchaseHandler.purchased) { purchased in
                if self.mode.isFullScreen, purchased {
                    Logger.debug(Strings.dismissing_paywall)
                    self.dismiss()
                }
            }

        if self.displayCloseButton {
            NavigationView {
                view
                    .toolbar { self.toolbar }
            }
            .navigationViewStyle(.stack)
        } else {
            view
        }
    }

    private func createEventData() -> PaywallEvent.Data {
        return .init(
            offering: self.offering,
            paywall: self.paywall,
            sessionID: .init(),
            displayMode: self.mode,
            locale: .current,
            darkMode: self.colorScheme == .dark
        )
    }

    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button {
                self.dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .disabled(self.purchaseHandler.actionInProgress)
            .opacity(
                self.purchaseHandler.actionInProgress
                ? Constants.purchaseInProgressButtonOpacity
                : 1
            )
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private extension LoadedOfferingPaywallView {

    struct DisplayedPaywall: Equatable {
        var offeringIdentifier: String
        var paywallTemplate: String
        var revision: Int

        init(offering: Offering, paywall: PaywallData) {
            self.offeringIdentifier = offering.identifier
            self.paywallTemplate = paywall.templateName
            self.revision = paywall.revision
        }
    }

}

// MARK: -

// swiftlint:disable file_length

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(Self.offerings, id: \.self) { offering in
            ForEach(Self.modes, id: \.self) { mode in
                PaywallView(
                    configuration: .init(
                        offering: offering,
                        customerInfo: TestData.customerInfo,
                        mode: mode,
                        introEligibility: PreviewHelpers.introEligibilityChecker,
                        purchaseHandler: PreviewHelpers.purchaseHandler
                    )
                )
                .previewLayout(mode.layout)
                .previewDisplayName("\(offering.paywall?.templateName ?? "")-\(mode)")
            }
        }
    }

    private static let offerings: [Offering] = [
        TestData.offeringWithIntroOffer,
        TestData.offeringWithMultiPackagePaywall,
        TestData.offeringWithSinglePackageFeaturesPaywall,
        TestData.offeringWithMultiPackageHorizontalPaywall,
        TestData.offeringWithTemplate5Paywall
    ]

    private static let modes: [PaywallViewMode] = [
        .fullScreen
    ]

    private static let colors: PaywallData.Configuration.ColorInformation = .init(
        light: TestData.lightColors,
        dark: TestData.darkColors
    )

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var layout: PreviewLayout {
        switch self {
        case .fullScreen: return .device
        case .footer, .condensedFooter: return .sizeThatFits
        }
    }

}

#endif

#endif
