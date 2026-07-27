//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

typealias PresentedWebViewPartial = PaywallComponent.PartialWebViewComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewModel: Hashable {

    let componentID: String

    private let component: PaywallComponent.WebViewComponent
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedWebViewPartial>?

    init(
        component: PaywallComponent.WebViewComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool = false
    ) {
        self.component = component
        self.componentID = component.id
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

    /// Resolves the component's rendered properties for the current presentation context, applying any
    /// matching overrides on top of the base component values.
    // swiftlint:disable:next function_parameter_count
    func style(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        stateValues: [String: PaywallComponent.ConditionValue] = [:],
        stateDefaults: [String: PaywallComponent.ConditionValue] = [:]
    ) -> WebViewComponentStyle {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables,
            stateValues: stateValues,
            stateDefaults: stateDefaults
        )

        let partial = PresentedWebViewPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        return WebViewComponentStyle(
            componentID: self.component.id,
            urlString: self.component.url,
            size: self.component.size,
            visible: partial?.visible ?? self.component.visible ?? true
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.component)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.component == rhs.component
    }
}

extension PresentedWebViewPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialWebViewComponent?,
        with other: PaywallComponent.PartialWebViewComponent?
    ) -> Self {
        return .init(visible: other?.visible ?? base?.visible)
    }

}

/// The resolved rendering inputs of a ``PaywallComponent/WebViewComponent`` for a given presentation
/// context. Only ``visible`` can be adjusted by overrides; the derived, validated values (``url``,
/// ``origin``, ``isRenderable``) are computed from the component's ``urlString``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewComponentStyle: Equatable {

    let componentID: String
    let urlString: String
    let size: PaywallComponent.Size
    let visible: Bool

    /// The resolved URL, or `nil` when the resolved ``urlString`` is not a valid static HTTPS URL.
    let url: URL?

    #if canImport(WebKit)
    /// Canonical origin derived from ``url``. `nil` when there is no valid URL or it has no host.
    let origin: WebViewOrigin?

    /// Whether to mount the web view: visible, with a non-empty id and a URL that resolves an origin.
    var isRenderable: Bool {
        self.visible && !self.componentID.isEmpty && self.url != nil && self.origin != nil
    }
    #endif

    init(
        componentID: String,
        urlString: String,
        size: PaywallComponent.Size,
        visible: Bool
    ) {
        self.componentID = componentID
        self.urlString = urlString
        self.size = size
        self.visible = visible

        let resolvedURL = PaywallComponent.WebViewComponent.validatedHTTPSURL(from: urlString)
        self.url = resolvedURL

        #if canImport(WebKit)
        self.origin = resolvedURL.flatMap { WebViewOrigin(url: $0) }
        #endif
    }

}

#endif
