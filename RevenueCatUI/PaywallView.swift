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
    private var paywall: PaywallData?

    /// Create a view that loads the `Offerings.current`.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(mode: PaywallViewMode = .default) {
        self.init(
            offering: nil,
            paywall: nil,
            mode: mode,
            introEligibility: Purchases.isConfigured ? .init() : nil,
            purchaseHandler: Purchases.isConfigured ? .init() : nil
        )
    }

    /// Create a view for the given offering and paywal.
    /// - Warning: `Purchases` must have been configured prior to displaying it.
    public init(offering: Offering,
                paywall: PaywallData,
                mode: PaywallViewMode = .default) {
        self.init(
            offering: offering,
            paywall: paywall,
            mode: mode,
            introEligibility: Purchases.isConfigured ? .init() : nil,
            purchaseHandler: Purchases.isConfigured ? .init() : nil
        )
    }

    init(
        offering: Offering?,
        paywall: PaywallData?,
        mode: PaywallViewMode = .default,
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self._offering = .init(initialValue: offering)
        self._paywall = .init(initialValue: paywall)
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.mode = mode
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        if let checker = self.introEligibility, let purchaseHandler = self.purchaseHandler {
            if let offering = self.offering {
                if let paywall = self.paywall {
                    LoadedOfferingPaywallView(
                        offering: offering,
                        paywall: paywall,
                        mode: mode,
                        introEligibility: checker,
                        purchaseHandler: purchaseHandler
                    )
                } else {
                    DebugErrorView("Offering '\(offering.identifier)' has no configured paywall",
                                   releaseBehavior: .emptyView)
                }
            } else {
                self.loadingView
                    .task {
                        // TODO: error handling
                        self.offering = try? await Purchases.shared.offerings().current
                        self.paywall = self.offering?.paywall
                    }
            }
        } else {
            DebugErrorView("Purchases has not been configured.", releaseBehavior: .fatalError)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct LoadedOfferingPaywallView: View {

    private let offering: Offering
    private let paywall: PaywallData
    private let mode: PaywallViewMode
    private let introEligibility: TrialOrIntroEligibilityChecker
    private let purchaseHandler: PurchaseHandler

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
            .createView(for: self.offering, mode: self.mode)
            .environmentObject(self.introEligibility)
            .environmentObject(self.purchaseHandler)

        if let aspectRatio = self.mode.aspectRatio {
            view.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            view
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
        let offering = TestData.offeringWithNoIntroOffer

        if let paywall = offering.paywall {
            ForEach(PaywallViewMode.allCases, id: \.self) { mode in
                PaywallView(
                    offering: offering,
                    paywall: paywall,
                    mode: mode,
                    introEligibility: Self.introEligibility,
                    purchaseHandler: Self.purchaseHandler
                )
                .previewLayout(mode.layout)
            }
        } else {
            Text("Preview not correctly setup, offering has no paywall!")
        }
    }

    private static let introEligibility: TrialOrIntroEligibilityChecker = .producing(eligibility: .eligible)
        .with(delay: .seconds(1))
    private static let purchaseHandler: PurchaseHandler = .mock()
        .with(delay: .seconds(1))

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
