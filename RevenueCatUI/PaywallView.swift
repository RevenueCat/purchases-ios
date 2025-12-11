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

#if canImport(AppKit)
import AppKit
#endif

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
            let (paywall, displayedLocale, template, error) = offering.validatedPaywall(
                locale: purchaseHandler.preferredLocaleOverride ?? .current
            )

            if let error {
                DefaultPaywallView(warning: .from(error), offering: offering)
            } else {
                #if os(macOS)
                DebugErrorView("Legacy paywalls are unsupported on macOS.", releaseBehavior: .errorView)
                #else
                LoadedOfferingPaywallView(
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
                #endif
            }
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

fileprivate extension Color {
    static let revenueCatBrandRed = Color(red: 0.949, green: 0.329, blue: 0.357) // #f2545b
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct DefaultPaywallView: View {

    init(warning: PaywallWarning? = nil, offering: Offering?) {
        self.warning = warning
        if let packages = offering?.availablePackages, !packages.isEmpty {
            self.products = packages
        } else {
            self.warning = .noProducts(CocoaError.error(.coderInvalidValue))
            self.products = []
        }
    }

    @State private var warning: PaywallWarning?
    @State private var products: [Package]
    @State private var selected: Package?

    @State var colors: [Color] = []

    var activeColor: Color {
        if colors.isEmpty {
            return .accentColor
        }

        return selectColorWithBestContrast(from: colors, againstColor: colorScheme == .dark ? .black : .white)
    }

    var foregroundOnAccentColor: Color {
        if colors.isEmpty {
            return .primary
        }

        return selectColorWithBestContrast(
            from: colors + [colorScheme == .dark ? .black : .white],
            againstColor: activeColor
        )
    }

    @Environment(\.colorScheme) var colorScheme

    private var mainColor: Color {
        return warning != nil ? .revenueCatBrandRed : activeColor
    }

    var shouldShowWarning: Bool {
        #if DEBUG
        return warning != nil
        #else
        return false
        #endif
    }

    @ViewBuilder
    var warningTitle: some View {
        if shouldShowWarning {
            Text("RevenueCat Paywalls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var body: some View {
        VStack {
            warningTitle
            Spacer()

            if shouldShowWarning, let warning {
                DefaultPaywallWarning(warning: warning, hasProducts: !products.isEmpty)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    let image = AppDetails.appIcon()
                    ZStack {
                        image
                            .resizable()
                            .blur(radius: 48)
                            .opacity(0.2)
                            .accessibilityHidden(true)
                        image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 31))
                            .accessibilityHidden(true)
                    }
                    .frame(width: 120, height: 120)
                    .shadow(color: mainColor.opacity(0.2), radius: 6, x: 0, y: 2)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("App Icon Image")

                    Text(AppDetails.getAppName())
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer()

            VStack {
                ForEach(products) { product in
                    DefaultProductCell(
                        product: product,
                        accentColor: mainColor,
                        selectedFontColor: foregroundOnAccentColor,
                        selected: $selected
                    )
                }
            }
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            if !products.isEmpty {
                VStack {
                    Button {
                        // Purchase
                    } label: {
                        Text("Purchase")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(foregroundOnAccentColor)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        // Restore
                    } label: {
                        Text("Restore Purchases")
                    }
                    .controlSize(.large)
                    .tint(Color.primary)
                    .padding(.top, 8)
                }
                .padding()
            }

        }
        .fillWithReadableContentWidth()
        .background {
            LinearGradient(colors: [
                mainColor.opacity(0.2),
                mainColor.opacity(0)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        .tint(mainColor)
        .task {
            colors = await AppDetails.getProminentColorsFromAppIcon()
        }
    }
}

// MARK: - Constants for Color Extraction

/// Constants used in the prominent color extraction algorithm.
private enum ColorExtractionConstants {
    /// Maximum number of pixels to sample from the image.
    /// Sampling reduces processing time while maintaining accuracy.
    /// 10,000 samples provides a good balance between performance and color detection quality.
    static let maxPixelSamples = 10000

    /// The divisor used to quantize (reduce) color precision.
    /// Dividing RGB values by 32 reduces 256 possible values per channel to 8,
    /// grouping similar colors together. This helps identify dominant colors
    /// by combining nearly-identical shades into single buckets.
    /// Value of 32 = 256/8, creating 8 color levels per channel (512 total possible colors).
    static let colorQuantizationDivisor: UInt8 = 32

    /// Minimum alpha (opacity) value for a pixel to be considered.
    /// Pixels with alpha <= 128 (50% transparent or more) are ignored
    /// to avoid counting transparent/semi-transparent areas.
    /// Range: 0 (fully transparent) to 255 (fully opaque).
    static let minimumAlphaThreshold: UInt8 = 128

    /// Minimum combined RGB brightness for a color to be considered.
    /// Filters out very dark colors (near-black) that aren't visually distinctive.
    /// Calculated as: quantizedR + quantizedG + quantizedB.
    /// Value of 30 ≈ RGB(10,10,10) after quantization, very dark gray.
    static let minimumBrightnessThreshold = 30

    /// Maximum combined RGB brightness for a color to be considered.
    /// Filters out very bright colors (near-white) that aren't visually distinctive.
    /// Calculated as: quantizedR + quantizedG + quantizedB.
    /// Value of 720 ≈ RGB(240,240,240) after quantization, very light gray.
    /// Maximum possible value would be 224*3 = 672 for quantized, but we use 720
    /// to account for the actual max of 255*3 = 765.
    static let maximumBrightnessThreshold = 720

    /// Minimum Euclidean distance between colors in RGB space (normalized 0-1).
    /// Colors closer than this threshold are considered "too similar".
    /// This ensures the returned colors are visually distinct from each other.
    /// Value of 0.15 in normalized RGB space ≈ 38 in 0-255 scale.
    /// For reference: sqrt(3) ≈ 1.73 is the max distance (black to white).
    static let minimumColorDistance = 0.05

    /// Number of bytes per pixel in RGBA format.
    /// Each pixel has 4 components: Red, Green, Blue, Alpha (1 byte each).
    static let bytesPerPixel = 4

    /// Number of bits per color component (R, G, or B).
    /// Standard 8-bit color depth allows 256 values (0-255) per channel.
    static let bitsPerComponent = 8

    /// Minimum Euclidean distance a color must be from pure black (0,0,0) or pure white (1,1,1).
    /// Colors closer than this threshold to black or white are excluded from results.
    /// This ensures returned colors have enough "color" to be visually interesting
    /// and will provide reasonable contrast against both light and dark backgrounds.
    /// Value of 0.20 in normalized RGB space ≈ 51 in 0-255 scale.
    /// A color like RGB(50,50,50) or RGB(205,205,205) would be excluded.
    static let minimumDistanceFromBlackWhite = 0.60
}

// MARK: - Constants for WCAG Contrast Calculation

/// Constants defined by WCAG 2.1 for calculating relative luminance and contrast ratios.
/// These are standardized values, not arbitrary choices.
/// Reference: https://www.w3.org/WAI/GL/wiki/Relative_luminance
private enum WCAGConstants {
    /// Luminance coefficient for the red channel.
    /// Human eyes are less sensitive to red than green.
    static let redLuminanceCoefficient = 0.2126

    /// Luminance coefficient for the green channel.
    /// Human eyes are most sensitive to green light.
    static let greenLuminanceCoefficient = 0.7152

    /// Luminance coefficient for the blue channel.
    /// Human eyes are least sensitive to blue.
    static let blueLuminanceCoefficient = 0.0722

    /// Threshold for sRGB linearization.
    /// Below this value, the gamma curve is approximately linear.
    /// This is part of the sRGB color space specification.
    static let linearizationThreshold = 0.04045

    /// Divisor for linear portion of sRGB gamma curve.
    /// Used when the color value is below the linearization threshold.
    static let linearDivisor = 12.92

    /// Offset added before applying gamma correction.
    /// Part of the sRGB transfer function specification.
    static let gammaOffset = 0.055

    /// Divisor used in gamma correction formula.
    /// Calculated as (1 + gammaOffset) = 1.055.
    static let gammaDivisor = 1.055

    /// Gamma exponent for sRGB color space.
    /// Approximates the actual sRGB curve which varies slightly.
    static let gammaExponent = 2.4

    /// Small offset added to luminance values when calculating contrast ratio.
    /// Prevents division by zero and accounts for ambient light.
    /// This value is defined by WCAG specification.
    static let contrastOffset = 0.05
}

// MARK: - AppDetails

/// Provides utilities for accessing app metadata and visual assets.
///
/// This enum contains static methods for retrieving information about the current app,
/// including its name, icon, and prominent colors from the icon.
///
/// All methods work across iOS, macOS, and tvOS platforms.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum AppDetails {

    /// Retrieves the name of the app's primary icon from the bundle.
    ///
    /// This method navigates the Info.plist structure to find the icon filename.
    /// The icon name can be used with `UIImage(named:)` on iOS/tvOS.
    ///
    /// - Returns: The icon filename, or an empty string if not found.
    private static func appIconName() -> String {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let lastIconName = iconFiles.last else {
            return ""
        }
        return lastIconName
    }

    /// Retrieves the display name of the application.
    ///
    /// Attempts to get the localized display name first (`CFBundleDisplayName`),
    /// falling back to the bundle name (`CFBundleName`) if not available.
    ///
    /// - Returns: The app's display name, or an empty string if neither is found.
    static func getAppName() -> String {
        let bundle = Bundle.main
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        return ""
    }

    /// Returns the app's icon as a SwiftUI `Image`.
    ///
    /// - On macOS: Returns the application icon from `NSApplication.shared`.
    /// - On iOS/tvOS: Returns the icon loaded by name from the asset catalog.
    ///
    /// - Returns: A SwiftUI `Image` containing the app icon, or an empty image if unavailable.
    static func appIcon() -> Image {
        #if os(macOS)
        return Image(nsImage: NSApplication.shared.applicationIconImage)
        #elseif canImport(UIKit)
        if let image = UIImage(named: appIconName()) {
            return Image(uiImage: image)
        }
        #endif
        return Image("")
    }

    /// Extracts the most prominent colors from the app icon asynchronously.
    ///
    /// This method performs color extraction on a background thread to avoid
    /// blocking the main thread, then delivers results on the main thread.
    ///
    /// The algorithm:
    /// 1. Samples pixels from the app icon (up to 10,000 samples for performance)
    /// 2. Quantizes colors to group similar shades together
    /// 3. Filters out transparent, very dark, and very bright pixels
    /// 4. Sorts colors by frequency (most common first)
    /// 5. Removes colors that are too similar to already-selected colors
    ///
    /// - Parameter completion: Closure called on the main thread with an array of up to 4 prominent `Color` values.
    static func getProminentColorsFromAppIcon(completion: @escaping ([Color]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = extractProminentColors(count: 4)
            DispatchQueue.main.async {
                completion(colors)
            }
        }
    }

    /// Extracts the most prominent colors from the app icon using async/await.
    ///
    /// This is an async wrapper around `getProminentColorsFromAppIcon(completion:)`.
    /// See that method for details on the extraction algorithm.
    ///
    /// - Returns: An array of up to 4 prominent `Color` values from the app icon.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    static func getProminentColorsFromAppIcon() async -> [Color] {
        await withCheckedContinuation { continuation in
            getProminentColorsFromAppIcon { colors in
                continuation.resume(returning: colors)
            }
        }
    }

    /// Performs the actual color extraction from the app icon.
    ///
    /// This method:
    /// 1. Gets the app icon as a `CGImage`
    /// 2. Creates a bitmap context to access raw pixel data
    /// 3. Samples pixels at regular intervals (for performance)
    /// 4. Quantizes each pixel's color to reduce the color space
    /// 5. Counts occurrences of each quantized color
    /// 6. Selects the most frequent colors that are visually distinct
    ///
    /// - Parameter count: The maximum number of colors to return.
    /// - Returns: An array of distinct prominent colors, sorted by frequency.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func extractProminentColors(count: Int, image: CGImage? = getPlatformAppIconCGImage()) -> [Color] {
        guard let cgImage = image else {
            return []
        }

        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return [] }

        // Create a bitmap context to access raw pixel data in RGBA format
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: ColorExtractionConstants.bitsPerComponent,
            bytesPerRow: width * ColorExtractionConstants.bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return []
        }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: totalPixels * ColorExtractionConstants.bytesPerPixel)

        // Dictionary to count occurrences of each quantized color
        // Key: packed RGB value (R << 16 | G << 8 | B), Value: count
        var colorCounts: [UInt32: Int] = [:]

        // Calculate step size to sample approximately maxPixelSamples pixels
        let sampleStep = max(1, totalPixels / ColorExtractionConstants.maxPixelSamples)

        for pixel in stride(from: 0, to: totalPixels, by: sampleStep) {
            let offset = pixel * ColorExtractionConstants.bytesPerPixel
            let red = data[offset]
            let green = data[offset + 1]
            let blue = data[offset + 2]
            let alpha = data[offset + 3]

            // Skip pixels that are mostly transparent
            guard alpha > ColorExtractionConstants.minimumAlphaThreshold else { continue }

            // Quantize colors by reducing precision (groups similar colors together)
            let quantizationDivisor = ColorExtractionConstants.colorQuantizationDivisor
            let quantizedR = (red / quantizationDivisor) * quantizationDivisor
            let quantizedG = (green / quantizationDivisor) * quantizationDivisor
            let quantizedB = (blue / quantizationDivisor) * quantizationDivisor

            // Calculate simple brightness as sum of RGB components
            let brightness = Int(quantizedR) + Int(quantizedG) + Int(quantizedB)

            // Skip very dark (near-black) and very bright (near-white) colors
            if brightness < ColorExtractionConstants.minimumBrightnessThreshold ||
               brightness > ColorExtractionConstants.maximumBrightnessThreshold {
                continue
            }

            // Pack RGB into a single UInt32 for use as dictionary key
            let key = (UInt32(quantizedR) << 16) | (UInt32(quantizedG) << 8) | UInt32(quantizedB)
            colorCounts[key, default: 0] += 1
        }

        // Sort colors by frequency (most common first)
        let sortedColors = colorCounts.sorted { $0.value > $1.value }

        var prominentColors: [Color] = []
        // Reference colors for black/white distance check
        let black = (0.0, 0.0, 0.0)
        let white = (1.0, 1.0, 1.0)

        for (colorKey, _) in sortedColors {
            // Unpack RGB values from the key and normalize to 0-1 range
            let red = Double((colorKey >> 16) & 0xFF) / 255.0
            let green = Double((colorKey >> 8) & 0xFF) / 255.0
            let blue = Double(colorKey & 0xFF) / 255.0

            let colorTuple = (red, green, blue)

            // Skip colors that are too close to pure black or pure white
            let distanceFromBlack = colorDistance(color1: colorTuple, color2: black)
            let distanceFromWhite = colorDistance(color1: colorTuple, color2: white)

            if distanceFromBlack < ColorExtractionConstants.minimumDistanceFromBlackWhite ||
               distanceFromWhite < ColorExtractionConstants.minimumDistanceFromBlackWhite {
                continue
            }

            let newColor = Color(red: red, green: green, blue: blue)

            // Check if this color is too similar to any already-selected color
            let isTooSimilar = prominentColors.contains { existingColor in
                colorDistance(
                    color1: colorTuple,
                    color2: extractRGB(from: existingColor)
                ) < ColorExtractionConstants.minimumColorDistance
            }

            if !isTooSimilar {
                prominentColors.append(newColor)
                if prominentColors.count >= count {
                    break
                }
            }
        }

        return prominentColors
    }

    /// Retrieves the app icon as a `CGImage` using platform-specific APIs.
    ///
    /// - On macOS: Converts the `NSImage` from `NSApplication.shared.applicationIconImage`.
    /// - On iOS/tvOS: Loads the icon by name using `UIImage(named:)`.
    ///
    /// - Returns: The app icon as a `CGImage`, or `nil` if unavailable.
    private static func getPlatformAppIconCGImage() -> CGImage? {
        #if os(macOS)
        if let nsImage = NSApplication.shared.applicationIconImage {
            var rect = NSRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
            return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
        #elseif canImport(UIKit)
        guard let uiImage = UIImage(named: appIconName()) else { return nil }
        return uiImage.cgImage
        #endif
        return nil
    }

    /// Extracts RGB components from a SwiftUI `Color`.
    ///
    /// Uses platform-specific APIs to convert the color to RGB values.
    ///
    /// - Parameter color: The SwiftUI `Color` to extract components from.
    /// - Returns: A tuple of (red, green, blue) values in the range 0-1.
    private static func extractRGB(from color: Color) -> (Double, Double, Double) {
        #if os(macOS)
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return (0, 0, 0)
        }
        return (Double(rgbColor.redComponent), Double(rgbColor.greenComponent), Double(rgbColor.blueComponent))
        #elseif canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
        #else
        return (0, 0, 0)
        #endif
    }

    /// Calculates the Euclidean distance between two colors in RGB space.
    ///
    /// This measures how "different" two colors appear. The distance is calculated
    /// in normalized RGB space (0-1 per channel), so the maximum possible distance
    /// is √3 ≈ 1.73 (from black to white).
    ///
    /// Note: This is a simple RGB distance, not perceptually uniform. For more
    /// accurate perceptual difference, consider using LAB color space.
    ///
    /// - Parameters:
    ///   - color1: First color as (red, green, blue) tuple, values 0-1.
    ///   - color2: Second color as (red, green, blue) tuple, values 0-1.
    /// - Returns: The Euclidean distance between the colors.
    private static func colorDistance(color1: (Double, Double, Double), color2: (Double, Double, Double)) -> Double {
        let dred = color1.0 - color2.0
        let dgreen = color1.1 - color2.1
        let dblue = color1.2 - color2.2
        return sqrt(dred * dred + dgreen * dgreen + dblue * dblue)
    }
}

// MARK: - Contrast Calculation Functions

/// Selects the color with the best contrast ratio against a background color.
///
/// Uses WCAG 2.1 contrast ratio calculation to determine which color from the
/// provided array will be most readable/visible against the specified background.
///
/// WCAG contrast ratio guidelines:
/// - 3:1 minimum for large text (18pt+ or 14pt+ bold)
/// - 4.5:1 minimum for normal text (AA compliance)
/// - 7:1 minimum for enhanced contrast (AAA compliance)
///
/// - Parameters:
///   - colors: Array of candidate colors to choose from.
///   - againstColor: The background color to calculate contrast against.
/// - Returns: The color from the array with the highest contrast ratio,
///            or `.black` if the array is empty.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func selectColorWithBestContrast(from colors: [Color], againstColor: Color) -> Color {
    guard !colors.isEmpty else {
        return .black
    }

    let backgroundLuminance = relativeLuminance(of: againstColor)

    var bestColor = colors[0]
    var bestRatio = contrastRatio(luminance1: relativeLuminance(of: colors[0]), luminance2: backgroundLuminance)

    for color in colors.dropFirst() {
        let colorLuminance = relativeLuminance(of: color)
        let ratio = contrastRatio(luminance1: colorLuminance, luminance2: backgroundLuminance)

        if ratio > bestRatio {
            bestRatio = ratio
            bestColor = color
        }
    }

    return bestColor
}

/// Calculates the relative luminance of a color per WCAG 2.1 specification.
///
/// Relative luminance is a measure of the brightness of a color as perceived
/// by the human eye, taking into account that we're more sensitive to green
/// light than red or blue.
///
/// The calculation:
/// 1. Converts sRGB values to linear RGB (removes gamma correction)
/// 2. Applies luminance coefficients based on human eye sensitivity
///
/// - Parameter color: The color to calculate luminance for.
/// - Returns: Relative luminance value between 0 (black) and 1 (white).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private func relativeLuminance(of color: Color) -> Double {
    let rgb = extractRGBComponents(from: color)

    // Convert from sRGB to linear RGB
    let red = linearize(rgb.0)
    let green = linearize(rgb.1)
    let blue = linearize(rgb.2)

    // Apply luminance coefficients (human eye sensitivity)
    return WCAGConstants.redLuminanceCoefficient * red +
           WCAGConstants.greenLuminanceCoefficient * green +
           WCAGConstants.blueLuminanceCoefficient * blue
}

/// Converts an sRGB color component to linear RGB.
///
/// sRGB uses a gamma curve to encode colors in a way that matches human
/// perception. This function reverses that encoding to get the actual
/// light intensity (linear) value.
///
/// The sRGB transfer function has two parts:
/// - A linear section for very dark values (value <= 0.04045)
/// - A gamma curve for the rest (approximately gamma 2.4)
///
/// - Parameter value: sRGB color component value (0-1).
/// - Returns: Linear RGB value (0-1).
private func linearize(_ value: Double) -> Double {
    if value <= WCAGConstants.linearizationThreshold {
        return value / WCAGConstants.linearDivisor
    } else {
        return pow((value + WCAGConstants.gammaOffset) / WCAGConstants.gammaDivisor, WCAGConstants.gammaExponent)
    }
}

/// Calculates the contrast ratio between two luminance values.
///
/// The contrast ratio is defined by WCAG as:
/// (L1 + 0.05) / (L2 + 0.05)
/// where L1 is the lighter luminance and L2 is the darker luminance.
///
/// The 0.05 offset accounts for ambient light and prevents division by zero.
///
/// Contrast ratio ranges from 1:1 (no contrast, same color) to 21:1 (max contrast, black on white).
///
/// - Parameters:
///   - luminance1: Relative luminance of the first color (0-1).
///   - luminance2: Relative luminance of the second color (0-1).
/// - Returns: The contrast ratio (1.0 to 21.0).
private func contrastRatio(luminance1: Double, luminance2: Double) -> Double {
    let lighter = max(luminance1, luminance2)
    let darker = min(luminance1, luminance2)
    return (lighter + WCAGConstants.contrastOffset) / (darker + WCAGConstants.contrastOffset)
}

/// Extracts RGB components from a SwiftUI `Color` using platform-specific APIs.
///
/// - Parameter color: The SwiftUI `Color` to extract components from.
/// - Returns: A tuple of (red, green, blue) values in the range 0-1.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private func extractRGBComponents(from color: Color) -> (Double, Double, Double) {
    #if os(macOS)
    let nsColor = NSColor(color)
    guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
        return (0, 0, 0)
    }
    return (Double(rgbColor.redComponent), Double(rgbColor.greenComponent), Double(rgbColor.blueComponent))
    #elseif canImport(UIKit)
    let uiColor = UIColor(color)
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return (Double(red), Double(green), Double(blue))
    #else
    return (0, 0, 0)
    #endif
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct DefaultProductCell: View {
    let product: Package
    let accentColor: Color
    let selectedFontColor: Color
    @Binding var selected: Package?

    private var isSelected: Bool {
        selected == product
    }

    var body: some View {
        Button {
            withAnimation {
                selected = product
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .opacity(isSelected ? 1 : 0.5)
                    .accessibilityHidden(true)
                Text(product.storeProduct.localizedTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(product.localizedPriceString)
                    .font(.subheadline)
                    .monospacedDigit()
            }
            .foregroundColor(isSelected ? selectedFontColor : Color.primary)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? accentColor : .secondary.opacity(0.3))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .frame(maxWidth: 560)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct DefaultPaywallWarning: View {
    let warning: PaywallWarning
    let hasProducts: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 16) {

            Image("default-paywall")
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: 8) {
                Text(warning.title)
                    .font(.title3)
                    .bold()
                Text(warning.bodyText)
                    .font(.subheadline)
            }
            if hasProducts {
                Text("This Paywall will not be available in production.")
                    .font(.subheadline.bold())
            }
            if let url = warning.helpURL {
                Link(destination: url) {
                    Text("Go to Dashboard")
                        .bold()
                }
                .tint(.revenueCatBrandRed)
                .buttonStyle(.bordered)
            }

        }
        .multilineTextAlignment(.center)
    }
}

extension View {
    // centers content but doesn't allow it to get too wide, this looks better on full screens like an ipad
    func fillWithReadableContentWidth() -> some View {
        self
        // UIKit used to have readable content guides, they started around 624 pixels and scaled up with dynamic fonts
        // This is just a sensible default that is close to the readable guide
            .frame(maxWidth: 630)
            .frame(maxWidth: .infinity)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum PaywallWarning {
    case noOffering
    case noProducts(Error)
    case noPaywall(String)
    case missingLocalization
    case missingTiers
    case missingTier(String)
    case missingTierName(String)
    case invalidTemplate(String)
    case invalidVariables(Set<String>)
    case invalidIcons(Set<String>)

    var title: String {
        switch self {
        case .noPaywall:
            return "No Paywall configured"
        case .noOffering:
            return "No Offering found"
        case .noProducts:
            return "Could not fetch products"
        case .missingLocalization:
            return "Missing localization"
        case .missingTiers:
            return "No Tiers"
        case .missingTier:
            return "Tier is missing localization"
        case .missingTierName(let tier):
            return "Tier \(tier) is missing a name"
        case .invalidTemplate:
            return "Unkown Template"
        case .invalidVariables:
            return "Unrecognized variables"
        case .invalidIcons:
            return "Invalid icon names"
        }
    }

    // swiftlint:disable line_length

    var bodyText: String {
        switch self {
        case .noPaywall(let offeringID):
            return "Your `\(offeringID)` offering has no configured paywalls. Set one up in the RevenueCat Dashboard to begin."
        case .noOffering:
            return "We could not detect any offerings. Set one up in the RevenueCat Dashboard to begin."
        case .noProducts(let error):
            return "We could not fetch any products: \(error.localizedDescription)"
        case .missingLocalization:
            return "Your paywall is missing a localization. Add a localization in the RevenueCat Dashboard to begin."
        case .missingTiers:
            return "Your paywall is missing any tiers. Add some tiers in the RevenueCat Dashboard to begin."
        case .missingTier(let tierID):
            return "The tier with ID: \(tierID) is missing a localization. Add a localization in the RevenueCat Dashboard to begin."
        case .missingTierName(let tier):
            return "The tier: \(tier) is missing a name. Add a name in the RevenueCat Dashboard to continue."
        case .invalidTemplate(let string):
            return "The template with ID: `\(string)` does not exist for this version of the SDK. Please make sure to update your SDK to the latest version and try again."
        case .invalidVariables(let set):
            return "The following variables are not recognized: \(set.joined(separator: ", ")). Please check the docs for a list of valid variables."
        case .invalidIcons(let set):
            return "The following icon names are not valid: \(set.joined(separator: ", ")). Please check `PaywallIcon` for the list of valid icon names."
        }
    }

    // swiftlint:enable line_length

    var helpURL: URL? {
        switch self {
        case .noPaywall, .missingTierName, .missingTier, .missingTiers:
            return URL(string: "https://www.revenuecat.com/docs/tools/paywalls")
        case .noOffering:
            return URL(string: "https://www.revenuecat.com/docs/offerings/overview")
        case .noProducts:
            return URL(string: "https://www.revenuecat.com/docs/offerings/products-overview")
        case .invalidVariables:
            return URL(string: "https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/variables")
        default:
            return nil
        }
    }

    static func from(_ from: Offering.PaywallValidationError) -> PaywallWarning {
        switch from {
        case .missingPaywall(let offering):
            return .noPaywall(offering.id)
        case .missingLocalization:
            return .missingLocalization
        case .missingTiers:
            return .missingTiers
        case .missingTier(let tier):
            return .missingTier(tier.id)
        case .missingTierName(let tier):
            return .missingTierName(tier.id)
        case .invalidTemplate(let string):
            return .invalidTemplate(string)
        case .invalidVariables(let set):
            return .invalidVariables(set)
        case .invalidIcons(let set):
            return .invalidIcons(set)
        }
    }
}
