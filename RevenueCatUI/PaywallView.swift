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

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

/// A SwiftUI view for displaying the paywall for an `Offering`.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
// swiftlint:disable:next type_body_length
public struct PaywallView: View {

    private let contentToDisplay: PaywallViewConfiguration.Content
    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider
    private let displayCloseButton: Bool
    private let paywallViewOwnsPurchaseHandler: Bool
    private let useDraftPaywall: Bool

    @StateObject
    private var internalPurchaseHandler: PurchaseHandler

    @ObservedObject
    private var externalPurchaseHandler: PurchaseHandler

    private var purchaseHandler: PurchaseHandler {
        paywallViewOwnsPurchaseHandler ? internalPurchaseHandler : externalPurchaseHandler
    }

    @StateObject
    private var introEligibility: TrialOrIntroEligibilityChecker

    @State
    private var offering: Offering?

    @State
    private var customerInfo: CustomerInfo?
    @State
    private var error: NSError?

//    @StateObject
//    private var defaultPaywallPromoOfferCache = PaywallPromoOfferCache()

    private var initializationError: NSError?

    @Environment(\.onRequestedDismissal)
    private var onRequestedDismissal: (() -> Void)?

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.colorScheme)
    private var colorScheme

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
        displayCloseButton: Bool = false,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil
    ) {
        let purchaseHandler = PurchaseHandler.default(performPurchase: performPurchase, performRestore: performRestore)
        self.init(
            configuration: .init(
                fonts: fonts,
                displayCloseButton: displayCloseButton,
                purchaseHandler: purchaseHandler
            )
        )
    }

    /// Create a view to display the paywall in a given `Offering`.
    ///
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
    /// - Parameter fonts: An optional `PaywallFontProvider`.
    /// - Parameter displayCloseButton: Set this to `true` to automatically include a close button.
    ///
    /// - Note: if `offering` does not have a current paywall (`hasPaywall == false`), or it fails to load
    /// due to invalid data, a default paywall will be displayed.
    /// - Note: Specifying this parameter means that it will ignore the offering configured in an active experiment.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(
        offering: Offering,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil
    ) {
        self.init(
            offering: offering,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            useDraftPaywall: false,
            performPurchase: performPurchase,
            performRestore: performRestore
            )
    }

    // swiftlint:disable:next missing_docs
    @_spi(Internal) public init(
        offering: Offering,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        useDraftPaywall: Bool,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil
    ) {
        let purchaseHandler = PurchaseHandler.default(performPurchase: performPurchase, performRestore: performRestore)

        self.init(
            configuration: .init(
                offering: offering,
                fonts: fonts,
                displayCloseButton: displayCloseButton,
                useDraftPaywall: useDraftPaywall,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            )
        )
    }

    init(configuration: PaywallViewConfiguration, paywallViewOwnsPurchaseHandler: Bool = true) {
        self.paywallViewOwnsPurchaseHandler = paywallViewOwnsPurchaseHandler
        if paywallViewOwnsPurchaseHandler {
            self._internalPurchaseHandler = .init(wrappedValue: configuration.purchaseHandler)
            self.externalPurchaseHandler = PurchaseHandler.default()
        } else {
            // this is unused and is only present to fulfill the need to have an object assigned
            // to a @StateObject
            self._internalPurchaseHandler = .init(wrappedValue: PurchaseHandler.default())
            self.externalPurchaseHandler = configuration.purchaseHandler
        }

        self._introEligibility = .init(wrappedValue: configuration.introEligibility ?? .default())

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
        self.useDraftPaywall = configuration.useDraftPaywall

        self.initializationError = Self.checkForConfigurationConsistency(purchaseHandler: configuration.purchaseHandler)
    }

    private static func checkForConfigurationConsistency(purchaseHandler: PurchaseHandler) -> NSError? {
        switch purchaseHandler.purchasesAreCompletedBy {
        case .myApp:
            if purchaseHandler.performPurchase == nil || purchaseHandler.performRestore == nil {
                let missingBlocks: String
                if purchaseHandler.performPurchase == nil && purchaseHandler.performRestore == nil {
                    missingBlocks = "performPurchase and performRestore are"
                } else if purchaseHandler.performPurchase == nil {
                    missingBlocks = "performPurchase is"
                } else {
                    missingBlocks = "performRestore is"
                }

                let error = PaywallError.performPurchaseAndRestoreHandlersNotDefined(
                    missingBlocks: missingBlocks
                ) as NSError
                Logger.error(error)

                return error
            }
        case .revenueCat:
            if purchaseHandler.performPurchase != nil || purchaseHandler.performRestore != nil {
                Logger.warning(PaywallError.purchaseAndRestoreDefinedForRevenueCat)
            }
        }

        return nil
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        self.content
            .displayError(self.$error) {
                guard let onRequestedDismissal = self.onRequestedDismissal else {
                    self.dismiss()
                    return
                }
                onRequestedDismissal()
            }
            // If the parent view uses refreshable, it can be inherited by the paywall view
            // and pulling down in the paywall would execute the parent's refreshable action
            .refreshableDisabled()
    }

    @MainActor
    @ViewBuilder
    private var content: some View {
        VStack { // Necessary to work around FB12674350 and FB12787354
            if let error = self.initializationError {
                DebugErrorView(error.localizedDescription, releaseBehavior: .fatalError)
            } else if self.introEligibility.isConfigured, self.purchaseHandler.isConfigured {
                if let offering = self.offering, let customerInfo = self.customerInfo {
                    self.paywallView(for: offering,
                                     useDraftPaywall: self.useDraftPaywall,
                                     activelySubscribedProductIdentifiers: customerInfo.activeSubscriptions,
                                     fonts: self.fonts,
                                     checker: self.introEligibility,
                                     purchaseHandler: self.purchaseHandler)
                    .transition(Self.transition)
                } else {
                    #if os(macOS)
                    DebugErrorView("Legacy paywalls are unsupported on macOS.", releaseBehavior: .errorView)
                    #else
                    LoadingPaywallView(mode: self.mode,
                                       displayCloseButton: self.displayCloseButton)
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
                    #endif
                }
            } else {
                DebugErrorView("Purchases has not been configured.", releaseBehavior: .fatalError)
            }
        }
    }

    func showZeroDecimalPlacePrices(countries: [String]?) -> Bool {
        if Purchases.isConfigured, let countries, let currentCountry = Purchases.shared.storeFrontCountryCode {
            return countries.contains(currentCountry)
        } else {
            return false
        }
    }

//    var paywallPromoOfferCache: PaywallPromoOfferCache {
//        if Purchases.isConfigured, let cache = Purchases.shared.paywallPromoOfferCache as? PaywallPromoOfferCache {
//            return cache
//        } else {
//            return self.defaultPaywallPromoOfferCache
//        }
//    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length function_parameter_count
    private func paywallView(
        for offering: Offering,
        useDraftPaywall: Bool,
        activelySubscribedProductIdentifiers: Set<String>,
        fonts: PaywallFontProvider,
        checker: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) -> some View {

        let showZeroDecimalPlacePrices = self.showZeroDecimalPlacePrices(
            countries: offering.paywall?.zeroDecimalPlaceCountries
        )

        if let paywallComponents = useDraftPaywall ? offering.draftPaywallComponents : offering.paywallComponents {

            // For fallback view or footer
            let paywall: PaywallData = .createDefault(with: offering.availablePackages,
                                                      locale: purchaseHandler.preferredLocaleOverride ?? .current)

            switch self.mode {
            // Show the default/fallback paywall for Paywalls V2 footer views
            #if !os(macOS)
            case .footer, .condensedFooter:
                LoadedOfferingPaywallView(
                    offering: offering,
                    activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                    paywall: paywall,
                    template: PaywallData.defaultTemplate,
                    mode: self.mode,
                    fonts: fonts,
                    displayCloseButton: self.displayCloseButton,
                    introEligibility: checker,
                    purchaseHandler: purchaseHandler,
                    locale: purchaseHandler.preferredLocaleOverride ?? .current,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )
            #endif
            // Show the actually V2 paywall for full screen
            case .fullScreen:
                let dataForV1DefaultPaywall = DataForV1DefaultPaywall(
                    offering: offering,
                    activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                    paywall: paywall,
                    template: PaywallData.defaultTemplate,
                    mode: self.mode,
                    fonts: fonts,
                    displayCloseButton: self.displayCloseButton,
                    introEligibility: checker,
                    purchaseHandler: purchaseHandler,
                    locale: purchaseHandler.preferredLocaleOverride ?? .current,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )

                PaywallsV2View(
                    paywallComponents: paywallComponents,
                    offering: offering,
                    purchaseHandler: purchaseHandler,
                    introEligibilityChecker: checker,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
                    onDismiss: {
                        guard let onRequestedDismissal = self.onRequestedDismissal else {
                            self.dismiss()
                            return
                        }
                        onRequestedDismissal()
                    },
                    fallbackContent: .paywallV1View(dataForV1DefaultPaywall),
                    failedToLoadFont: { fontConfig in
                        if Purchases.isConfigured {
                            Purchases.shared.failedToLoadFontWithConfig(fontConfig)
                        }
                    },
                    colorScheme: colorScheme
                )
            }
        } else {
            #if os(macOS)
            DebugErrorView("Legacy paywalls are unsupported on macOS.", releaseBehavior: .errorView)
            #else
            let (paywall, displayedLocale, template, error) = offering.validatedPaywall(
                locale: purchaseHandler.preferredLocaleOverride ?? .current
            )

            let paywallView = LoadedOfferingPaywallView(
                offering: offering,
                activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                paywall: paywall,
                template: template,
                mode: self.mode,
                fonts: fonts,
                displayCloseButton: self.displayCloseButton,
                introEligibility: checker,
                purchaseHandler: purchaseHandler,
                locale: displayedLocale,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
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
            #endif
        }
    }

    // MARK: -

    private static let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

        case let .offeringIdentifier(identifier, presentedOfferingContext):
            let offering = try await Purchases.shared.offerings()
                .offering(identifier: identifier)
                .orThrow(PaywallError.offeringNotFound(identifier: identifier))

            if let presentedOfferingContext {
                return offering.withPresentedOfferingContext(presentedOfferingContext)
            }

            return offering
        }
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewConfiguration.Content {

    func extractInitialOffering() -> Offering? {
        switch self {
        case let .offering(offering):
            return offering
        case .defaultOffering:
            return Self.loadCachedCurrentOfferingIfPossible()
        case let .offeringIdentifier(identifier, presentedOfferingContext):
            let offering = Self.loadCachedOfferingIfPossible(
                identifier: identifier
            )

            if let presentedOfferingContext {
                return offering?.withPresentedOfferingContext(presentedOfferingContext)
            }

            return offering
        }
    }

    private static func loadCachedCurrentOfferingIfPossible() -> Offering? {
        if Purchases.isConfigured {
            return Purchases.shared.cachedOfferings?.current
        } else {
            return nil
        }
    }

    private static func loadCachedOfferingIfPossible(identifier: String) -> Offering? {
        if Purchases.isConfigured {
            return Purchases.shared.cachedOfferings?.offering(identifier: identifier)
        } else {
            return nil
        }
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "Legacy paywalls are unavailable on macOS")
@available(tvOS, unavailable)
struct LoadedOfferingPaywallView: View {

    private let offering: Offering
    private let activelySubscribedProductIdentifiers: Set<String>
    private let paywall: PaywallData
    private let template: PaywallTemplate
    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider
    private let displayCloseButton: Bool
    private let showZeroDecimalPlacePrices: Bool

    @StateObject
    private var introEligibility: IntroEligibilityViewModel
    @ObservedObject
    private var purchaseHandler: PurchaseHandler

    private var locale: Locale

    @Environment(\.onRequestedDismissal)
    private var onRequestedDismissal: (() -> Void)?

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
        purchaseHandler: PurchaseHandler,
        locale: Locale,
        showZeroDecimalPlacePrices: Bool
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
        self.locale = locale
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
    }

    var body: some View {
        // Note: preferences need to be applied after `.toolbar` call
        self.content
            .preference(key: PurchaseInProgressPreferenceKey.self,
                        value: self.purchaseHandler.packageBeingPurchased)
            .preference(key: PurchasedResultPreferenceKey.self,
                        value: .init(data: self.purchaseHandler.purchaseResult))
            .preference(key: RestoredCustomerInfoPreferenceKey.self,
                        value: self.purchaseHandler.restoredCustomerInfo)
            .preference(key: RestoreInProgressPreferenceKey.self,
                        value: self.purchaseHandler.restoreInProgress)
            .preference(key: PurchaseErrorPreferenceKey.self,
                        value: self.purchaseHandler.purchaseError as NSError?)
            .preference(key: RestoreErrorPreferenceKey.self,
                        value: self.purchaseHandler.restoreError as NSError?)
    }

    @ViewBuilder
    private var content: some View {
        let configuration = self.paywall.configuration(
            for: self.offering,
            activelySubscribedProductIdentifiers: self.activelySubscribedProductIdentifiers,
            template: self.template,
            mode: self.mode,
            fonts: self.fonts,
            locale: self.locale,
            showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices
        )

        let view = self.paywall
            .createView(for: self.offering,
                        template: self.template,
                        configuration: configuration,
                        introEligibility: self.introEligibility)
            .environmentObject(self.introEligibility)
            .environmentObject(self.purchaseHandler)
            .disabled(self.purchaseHandler.actionInProgress)
            .onAppear { self.purchaseHandler.trackPaywallImpression(self.createEventData()) }
            .onDisappear { self.purchaseHandler.trackPaywallClose() }
            .onChangeOf(self.purchaseHandler.purchased) { purchased in
                if purchased {
                    guard let onRequestedDismissal = self.onRequestedDismissal else {
                        if self.mode.isFullScreen {
                            Logger.debug(Strings.dismissing_paywall)
                            self.dismiss()
                        }
                        return
                    }
                    onRequestedDismissal()
                }
            }

        if self.displayCloseButton {
            NavigationView {
                // Prevents navigation bar from being showing as translucent
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    view
                        .toolbar {
                            self.makeToolbar(
                                color: self.getCloseButtonColor(configuration: configuration)
                            )
                        }
                        .toolbarBackground(.hidden, for: .navigationBar)
                } else {
                    view
                        .toolbar {
                            self.makeToolbar(
                                color: self.getCloseButtonColor(configuration: configuration)
                            )
                        }
                }
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

    private func getCloseButtonColor(configuration: Result<TemplateViewConfiguration, Error>) -> Color? {
        switch configuration {
        case .success(let configuration):
            return configuration.colors.closeButtonColor
        case .failure:
            return nil
        }
    }

    private func makeToolbar(color: Color?) -> some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button {
                guard let onRequestedDismissal = self.onRequestedDismissal else {
                    self.dismiss()
                    return
                }
                onRequestedDismissal()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(color)
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
