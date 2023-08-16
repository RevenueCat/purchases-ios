import RevenueCat
import SwiftUI

/// A SwiftUI view for displaying a `PaywallData` for an `Offering`.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable, message: "RevenueCatUI does not support watchOS yet")
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(macCatalyst, unavailable, message: "RevenueCatUI does not support Catalyst yet")
public struct PaywallView: View {

    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider
    private let introEligibility: TrialOrIntroEligibilityChecker?
    private let purchaseHandler: PurchaseHandler?

    @State
    private var offering: Offering?
    @State
    private var error: NSError?

    /// Create a view that loads the `Offerings.current`.
    /// - Note: If loading the current `Offering` fails (if the user is offline, for example),
    /// an error will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    /// If you want to handle that, you can use ``init(offering:mode:)`` instead.
    public init(
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider()
    ) {
        self.init(
            offering: nil,
            mode: mode,
            fonts: fonts,
            introEligibility: .default(),
            purchaseHandler: .default()
        )
    }

    /// Create a view for the given `Offering`.
    /// - Note: if `offering` does not have a current paywall, or it fails to load due to invalid data,
    /// a default paywall will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(
        offering: Offering,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider()
    ) {
        self.init(
            offering: offering,
            mode: mode,
            fonts: fonts,
            introEligibility: .default(),
            purchaseHandler: .default()
        )
    }

    init(
        offering: Offering?,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self._offering = .init(initialValue: offering)
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.mode = mode
        self.fonts = fonts
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
            if let checker = self.introEligibility, let purchaseHandler = self.purchaseHandler {
                if let offering = self.offering {
                    self.paywallView(for: offering,
                                     fonts: self.fonts,
                                     checker: checker,
                                     purchaseHandler: purchaseHandler)
                    .transition(Self.transition)
                } else {
                    LoadingPaywallView(mode: self.mode)
                        .transition(Self.transition)
                        .task {
                            do {
                                guard Purchases.isConfigured else {
                                    throw PaywallError.purchasesNotConfigured
                                }

                                guard let offering = try await Purchases.shared.offerings().current else {
                                    throw PaywallError.noCurrentOffering
                                }

                                self.offering = offering
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
        fonts: PaywallFontProvider,
        checker: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) -> some View {
        let (paywall, error) = offering.validatedPaywall()

        let paywallView = LoadedOfferingPaywallView(
            offering: offering,
            paywall: paywall,
            mode: self.mode,
            fonts: fonts,
            introEligibility: checker,
            purchaseHandler: purchaseHandler
        )

        if let error {
            DebugErrorView(
                "\(error.description)\n" +
                "You can fix this by editing the paywall in the RevenueCat dashboard.\n" +
                "The displayed paywall contains default configuration.\n" +
                "This error will be hidden in production.",
                releaseBehavior: .replacement(AnyView(paywallView))
            )
        } else {
            paywallView
        }
    }

    private static let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct LoadedOfferingPaywallView: View {

    private let offering: Offering
    private let paywall: PaywallData
    private let mode: PaywallViewMode
    private let fonts: PaywallFontProvider

    @StateObject
    private var introEligibility: IntroEligibilityViewModel
    @ObservedObject
    private var purchaseHandler: PurchaseHandler

    @Environment(\.locale)
    private var locale

    init(
        offering: Offering,
        paywall: PaywallData,
        mode: PaywallViewMode,
        fonts: PaywallFontProvider,
        introEligibility: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) {
        self.offering = offering
        self.paywall = paywall
        self.mode = mode
        self.fonts = fonts
        self._introEligibility = .init(
            wrappedValue: .init(introEligibilityChecker: introEligibility)
        )
        self._purchaseHandler = .init(initialValue: purchaseHandler)
    }

    var body: some View {
        let view = self.paywall
            .createView(for: self.offering,
                        mode: self.mode,
                        fonts: self.fonts,
                        introEligibility: self.introEligibility,
                        locale: self.locale)
            .environmentObject(self.introEligibility)
            .environmentObject(self.purchaseHandler)
            .preference(key: PurchasedCustomerInfoPreferenceKey.self,
                        value: self.purchaseHandler.purchasedCustomerInfo)
            .disabled(self.purchaseHandler.actionInProgress)

        switch self.mode {
        case .fullScreen:
            view

        case .card, .condensedCard:
            view
                .fixedSize(horizontal: false, vertical: true)
                .edgesIgnoringSafeArea(.bottom)
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(macCatalyst, unavailable)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(Self.offerings, id: \.self) { offering in
            ForEach(Self.modes, id: \.self) { mode in
                PaywallView(
                    offering: offering,
                    mode: mode,
                    introEligibility: PreviewHelpers.introEligibilityChecker,
                    purchaseHandler: PreviewHelpers.purchaseHandler
                )
                .previewLayout(mode.layout)
                .previewDisplayName("\(offering.paywall?.template.name ?? "")-\(mode)")
            }
        }
    }

    private static let offerings: [Offering] = [
        TestData.offeringWithIntroOffer,
        TestData.offeringWithMultiPackagePaywall,
        TestData.offeringWithSinglePackageFeaturesPaywall
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
        case .card, .condensedCard: return .sizeThatFits
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallTemplate {

    var name: String {
        switch self {
        case .template1: return "Minimalist"
        case .template2: return "Bold Packages"
        case .template3: return "Feature List"
        case .template4: return "Horizontal"
        }
    }

}

#endif
