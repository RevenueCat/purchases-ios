//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Combine
import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

typealias PresentedWebViewPartial = PaywallComponent.PartialWebViewComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewModel: ObservableObject, Hashable {

    let componentID: String

    private let component: PaywallComponent.WebViewComponent
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedWebViewPartial>?

    #if !os(watchOS) && canImport(WebKit)
    @MainActor
    private var storedWebViewInstance: WebViewInstance?
    private var storeRetiredSubscription: AnyCancellable?
    #endif

    init(
        component: PaywallComponent.WebViewComponent,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool = false,
        storeRetired: AnyPublisher<Void, Never> = WebViewDataStoreManager.shared.storeRetired
    ) {
        self.component = component
        self.componentID = component.id
        self.uiConfigProvider = uiConfigProvider
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)

        #if !os(watchOS) && canImport(WebKit)
        self.storeRetiredSubscription = storeRetired
            .sink { [weak self] in
                Task { @MainActor in
                    self?.replaceInstanceAfterStoreRetirement()
                }
            }
        #else
        _ = storeRetired
        #endif
    }

    #if !os(watchOS) && canImport(WebKit)
    /// Canonical origin of the component's URL, or `nil` when it isn't a usable static HTTPS URL —
    /// the same condition that makes the component non-renderable.
    private var expectedOrigin: WebViewOrigin? {
        WebViewOrigin(url: PaywallComponent.WebViewComponent.validatedHTTPSURL(from: self.component.url))
    }

    /// The live web view for this component, created on first use. `nil` when the component has no
    /// resolvable origin to gate the bridge against.
    @MainActor
    func webViewInstance() -> WebViewInstance? {
        if let storedWebViewInstance = self.storedWebViewInstance {
            guard storedWebViewInstance.isUnusable else {
                return storedWebViewInstance
            }

            storedWebViewInstance.tearDown()
            self.storedWebViewInstance = nil
        }

        return self.mintInstance()
    }

    @MainActor
    private func replaceInstanceAfterStoreRetirement() {
        guard let storedWebViewInstance = self.storedWebViewInstance else {
            return
        }

        self.objectWillChange.send()
        storedWebViewInstance.retire()
        self.storedWebViewInstance = self.mintInstance()
    }

    @MainActor
    private func mintInstance() -> WebViewInstance? {
        guard let expectedOrigin = self.expectedOrigin else {
            return nil
        }

        let webViewInstance = WebViewInstance(
            componentID: self.componentID,
            expectedOrigin: expectedOrigin,
            fitsWidth: self.component.size.width.isFit,
            fitsHeight: self.component.size.height.isFit
        )
        self.storedWebViewInstance = webViewInstance
        return webViewInstance
    }
    #endif

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

private extension PaywallComponent.SizeConstraint {

    var isFit: Bool {
        if case .fit = self {
            return true
        }

        return false
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
