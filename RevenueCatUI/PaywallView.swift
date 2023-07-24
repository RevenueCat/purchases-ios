import RevenueCat
import SwiftUI

/// A full-screen SwiftUI view for displaying a `PaywallData` for an `Offering`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable, message: "RevenueCatUI does not support watchOS yet")
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(macCatalyst, unavailable, message: "RevenueCatUI does not support Catalyst yet")
public struct PaywallView: View {

    private let mode: PaywallViewMode
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
    public init(mode: PaywallViewMode = .default) {
        self.init(
            offering: nil,
            mode: mode,
            introEligibility: Purchases.isConfigured ? .init() : nil,
            purchaseHandler: Purchases.isConfigured ? .init() : nil
        )
    }

    /// Create a view for the given `Offering`.
    /// - Note: if `offering` does not have a current paywall, or it fails to load due to invalid data,
    /// a default paywall will be displayed.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(offering: Offering, mode: PaywallViewMode = .default) {
        self.init(
            offering: offering,
            mode: mode,
            introEligibility: Purchases.isConfigured ? .init() : nil,
            purchaseHandler: Purchases.isConfigured ? .init() : nil
        )
    }

    init(
        offering: Offering?,
        mode: PaywallViewMode = .default,
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self._offering = .init(initialValue: offering)
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.mode = mode
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        self.content
            .displayError(self.$error, dismissOnClose: true)
    }

    @ViewBuilder
    private var content: some View {
        if let checker = self.introEligibility, let purchaseHandler = self.purchaseHandler {
            if let offering = self.offering {
                self.paywallView(for: offering,
                                 checker: checker,
                                 purchaseHandler: purchaseHandler)
                .transition(Self.transition)
            } else {
                LoadingPaywallView()
                .transition(Self.transition)
                    .task {
                        do {
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

    @ViewBuilder
    private func paywallView(
        for offering: Offering,
        checker: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) -> some View {
        if let paywall = offering.paywall {
            LoadedOfferingPaywallView(
                offering: offering,
                paywall: paywall,
                mode: mode,
                introEligibility: checker,
                purchaseHandler: purchaseHandler
            )
        } else {
            DebugErrorView(
                "Offering '\(offering.identifier)' has no configured paywall.\n" +
                "The displayed paywall contains default configuration.\n" +
                "This error will be hidden in production.",
                releaseBehavior: .replacement(
                    AnyView(
                        LoadedOfferingPaywallView(
                            offering: offering,
                            paywall: .default,
                            mode: mode,
                            introEligibility: checker,
                            purchaseHandler: purchaseHandler
                        )
                    )
                )
            )
        }
    }

    private static let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct LoadedOfferingPaywallView: View {

    private let offering: Offering
    private let paywall: PaywallData
    private let mode: PaywallViewMode
    private let introEligibility: TrialOrIntroEligibilityChecker

    @ObservedObject
    private var purchaseHandler: PurchaseHandler

    @Environment(\.locale)
    private var locale

    init(
        offering: Offering,
        paywall: PaywallData,
        mode: PaywallViewMode,
        introEligibility: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) {
        self.offering = offering
        self.paywall = paywall
        self.mode = mode
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
    }

    var body: some View {
        let view = self.paywall
            .createView(for: self.offering, mode: self.mode, locale: self.locale)
            .environmentObject(self.introEligibility)
            .environmentObject(self.purchaseHandler)
            .hidden(if: self.shouldHidePaywall)

        if let aspectRatio = self.mode.aspectRatio {
            view.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            view
        }
    }

    private var shouldHidePaywall: Bool {
        switch self.mode {
        case .fullScreen:
            return false

        case .card, .banner:
            return self.purchaseHandler.purchased
        }
    }

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallViewMode {

    var aspectRatio: CGFloat? {
        switch self {
        case .fullScreen: return nil
        case .card: return 1
        case .banner: return 8
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
struct PaywallView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(Self.offerings, id: \.self) { offering in
            ForEach(Self.modes, id: \.self) { mode in
                PaywallView(
                    offering: offering,
                    mode: mode,
                    introEligibility: Self.introEligibility,
                    purchaseHandler: Self.purchaseHandler
                )
                .previewLayout(mode.layout)
                .previewDisplayName("\(offering.identifier)-\(mode)")
            }
        }
    }

    private static let introEligibility: TrialOrIntroEligibilityChecker =
        .producing(eligibility: .eligible)
        .with(delay: .seconds(1))
    private static let purchaseHandler: PurchaseHandler =
        .mock()
        .with(delay: .seconds(1))

    private static let offerings: [Offering] = [
        TestData.offeringWithIntroOffer,
        TestData.offeringWithMultiPackagePaywall
    ]

    private static let modes: [PaywallViewMode] = [
        .fullScreen
    ]

    private static let colors: PaywallData.Configuration.ColorInformation = .init(
        light: TestData.lightColors,
        dark: TestData.darkColors
    )

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallViewMode {

    var layout: PreviewLayout {
        switch self {
        case .fullScreen: return .device
        case .card, .banner: return .sizeThatFits
        }
    }

}

#endif
