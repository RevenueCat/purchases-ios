//
//  PaywallViewConfiguration.swift
//
//
//  Created by Nacho Soto on 1/19/24.
//

import Foundation

@_spi(Internal) import RevenueCat

/// Parameters needed to configure a ``PaywallView``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallViewConfiguration {

    var content: Content
    var customerInfo: CustomerInfo?
    var mode: PaywallViewMode
    var fonts: PaywallFontProvider

    /// This is a configuration value that is for V1 paywalls and the fallback paywall. V2 paywalls
    /// can have their own close buttons configured via the dashboard, so it's not used by the
    /// PaywallsV2View success path.
    var displayCloseButton: Bool
    let useDraftPaywall: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler
    var promoOfferCache: PaywallPromoOfferCache?

    init(
        content: Content,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        useDraftPaywall: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler,
        promoOfferCache: PaywallPromoOfferCache? = nil
    ) {
        self.content = content
        self.customerInfo = customerInfo
        self.mode = mode
        self.fonts = fonts
        self.displayCloseButton = displayCloseButton
        self.useDraftPaywall = useDraftPaywall
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.promoOfferCache = promoOfferCache
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    /// Offering selection for the paywall.
    enum Content {

        case defaultOffering
        case offering(Offering)
        case offeringIdentifier(String, presentedOfferingContext: PresentedOfferingContext?)

    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    init(
        offering: Offering? = nil,
        customerInfo: CustomerInfo? = nil,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        useDraftPaywall: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler = PurchaseHandler.default(),
        promoOfferCache: PaywallPromoOfferCache? = nil
    ) {
        let handler = purchaseHandler

        self.init(
            content: .optionalOffering(offering),
            customerInfo: customerInfo,
            mode: mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
            useDraftPaywall: useDraftPaywall,
            introEligibility: introEligibility,
            purchaseHandler: handler,
            promoOfferCache: promoOfferCache
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration.Content {

    /// - Returns: `Content.offering` or `Content.defaultOffering` if `nil`.
    static func optionalOffering(_ offering: Offering?) -> Self {
        return offering.map(Self.offering) ?? .defaultOffering
    }

    /// Returns a cached offering to display immediately while the fully resolved offering loads.
    func cachedInitialOffering(purchases: any PaywallPurchasesType) -> Offering? {
        switch self {
        case let .offering(offering):
            return offering
        case .defaultOffering:
            return purchases.cachedOfferings?.current
        case let .offeringIdentifier(identifier, presentedOfferingContext):
            #if ENABLE_WORKFLOWS_ENDPOINT
            return nil
            #else
            let offering = purchases.cachedOfferings?.offering(identifier: identifier)

            if let presentedOfferingContext {
                return offering?.withPresentedOfferingContext(presentedOfferingContext)
            }

            return offering
            #endif
        }
    }

    /// Resolves the content to an `Offering` by fetching from the backend if needed.
    /// - Returns: The resolved `Offering`, or `nil` if it couldn't be fetched.
    func resolveOffering(purchases: any PaywallPurchasesType) async -> Offering? {
        if case let .offering(offering) = self {
            return offering
        }
        do {
            return try await resolveOfferingOrThrow(purchases: purchases)
        } catch {
            Logger.error(Strings.errorFetchingOfferings(error))
            return nil
        }
    }

    func resolveOfferingOrThrow(purchases: any PaywallPurchasesType) async throws -> Offering {
        switch self {
        case let .offering(offering):
            return offering
        case .defaultOffering:
            return try await purchases.offerings().current.orThrow(PaywallError.noCurrentOffering)
        case let .offeringIdentifier(identifier, presentedOfferingContext):
            return try await Self.resolveOfferingIdentifier(
                identifier: identifier,
                presentedOfferingContext: presentedOfferingContext,
                purchases: purchases
            )
        }
    }

    private static func resolveOfferingIdentifier(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext?,
        purchases: any PaywallPurchasesType
    ) async throws -> Offering {
        #if ENABLE_WORKFLOWS_ENDPOINT && !os(tvOS)
        return try await Self.resolveWorkflowOfferingIdentifier(
            identifier: identifier,
            presentedOfferingContext: presentedOfferingContext,
            purchases: purchases
        )
        #else
        let offering = try await purchases.offerings()
            .offering(identifier: identifier)
            .orThrow(PaywallError.offeringNotFound(identifier: identifier))

        if let presentedOfferingContext {
            return offering.withPresentedOfferingContext(presentedOfferingContext)
        }

        return offering
        #endif
    }

    #if ENABLE_WORKFLOWS_ENDPOINT && !os(tvOS)
    private static func resolveWorkflowOfferingIdentifier(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext?,
        purchases: any PaywallPurchasesType
    ) async throws -> Offering {
        async let fetchResultTask = purchases.workflow(forOfferingIdentifier: identifier)
        async let allOfferingsTask = purchases.offerings()

        let (fetchResult, allOfferings) = try await (fetchResultTask, allOfferingsTask)
        let workflow = fetchResult.workflow

        guard let step = workflow.steps[workflow.initialStepId],
              let screenID = step.screenId,
              let screen = workflow.screens[screenID] else {
            throw PaywallError.offeringNotFound(identifier: identifier)
        }

        let baseOffering = try allOfferings
            .offering(identifier: screen.offeringId)
            .orThrow(PaywallError.offeringNotFound(identifier: screen.offeringId ?? identifier))

        let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
            screen: screen,
            uiConfig: workflow.uiConfig
        )

        let offering = baseOffering.withPaywallComponents(paywallComponents)

        if let presentedOfferingContext {
            return offering.withPresentedOfferingContext(presentedOfferingContext)
        }

        return offering
    }
    #endif

}
