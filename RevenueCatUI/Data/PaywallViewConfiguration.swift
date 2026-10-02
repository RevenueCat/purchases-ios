//
//  PaywallViewConfiguration.swift
//
//
//  Created by Nacho Soto on 1/19/24.
//

import Combine
import Foundation

@_spi(Internal) import RevenueCat

/// Parameters needed to configure a ``PaywallView``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallViewConfiguration {

    var content: Content
    var mode: PaywallViewMode
    var fonts: PaywallFontProvider

    /// This is a configuration value that is for V1 paywalls and the fallback paywall. V2 paywalls
    /// can have their own close buttons configured via the dashboard, so it's not used by the
    /// PaywallsV2View success path.
    var displayCloseButton: Bool
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler
    var promoOfferCache: PaywallPromoOfferCache?
    /// Whether the paywall presents purchase and restore errors instead of delegating presentation to its host.
    var displaysPurchaseAndRestoreErrors: Bool
    #if !os(tvOS)
    var workflowBackNavigationBridge = WorkflowBackNavigationBridge()
    /// Receives a workflow configuration error so checkpoint presentation can report an error outcome.
    var workflowPresentationErrorHandler: ((NSError) -> Void)?
    /// A pre-built workflow context to seed directly (injection/preview path), bypassing the
    /// backend fetch. When set, `PaywallView` renders the workflow paywall immediately. Set by the
    /// `PaywallView(workflowContext:)` initializer; tvOS has no workflow paywall UI.
    var injectedWorkflowContext: WorkflowContext?
    #endif

    init(
        content: Content,
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler,
        promoOfferCache: PaywallPromoOfferCache? = nil,
        displaysPurchaseAndRestoreErrors: Bool = true,
        workflowPresentationErrorHandler: ((NSError) -> Void)? = nil
    ) {
        self.content = content
        self.mode = mode
        self.fonts = fonts
        self.displayCloseButton = displayCloseButton
        self.introEligibility = introEligibility
        self.purchaseHandler = purchaseHandler
        self.promoOfferCache = promoOfferCache
        self.displaysPurchaseAndRestoreErrors = displaysPurchaseAndRestoreErrors
        #if !os(tvOS)
        self.workflowPresentationErrorHandler = workflowPresentationErrorHandler
        #endif

        PurchasesUIService.activateIfNeeded()
    }

}

#if !os(tvOS)
final class WorkflowBackNavigationBridge: ObservableObject {

    @Published private(set) var hasPendingBackNavigationRequest = false
    private(set) var hasActiveWorkflow = false

    func workflowDidAppear() {
        self.hasActiveWorkflow = true
    }

    func workflowDidDisappear() {
        self.hasActiveWorkflow = false
        self.hasPendingBackNavigationRequest = false
    }

    @discardableResult
    func navigateBack() -> Bool {
        guard self.hasActiveWorkflow else { return false }
        self.hasPendingBackNavigationRequest = true
        return true
    }

    func takePendingBackNavigationRequest(isTransitioning: Bool) -> Bool {
        guard !isTransitioning,
              self.hasPendingBackNavigationRequest else {
            return false
        }

        self.hasPendingBackNavigationRequest = false
        return true
    }

}
#endif

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
        mode: PaywallViewMode = .default,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        displayCloseButton: Bool = false,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler = PurchaseHandler.default(),
        promoOfferCache: PaywallPromoOfferCache? = nil
    ) {
        let handler = purchaseHandler

        self.init(
            content: .optionalOffering(offering),
            mode: mode,
            fonts: fonts,
            displayCloseButton: displayCloseButton,
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

}
