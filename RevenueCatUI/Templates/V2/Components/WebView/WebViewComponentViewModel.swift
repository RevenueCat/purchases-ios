//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentViewModel.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class WebViewComponentViewModel {

    private let urlTemplate: String
    private let localizationProvider: LocalizationProvider
    private let uiConfigProvider: UIConfigProvider

    let size: PaywallComponent.Size
    let visible: Bool

    /// The schema component identifier, used as the canonical `component_id` for the postMessage
    /// bridge. `nil` for legacy/partial configs that omit `id`, in which case the bridge is disabled.
    let componentID: String?

    /// The locale resolved for this paywall, exposed as an SDK-managed `locale` variable.
    var locale: Locale {
        self.localizationProvider.locale
    }

    init(
        component: PaywallComponent.WebViewComponent,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) {
        self.urlTemplate = component.url
        self.size = component.size
        self.visible = component.visible ?? true
        self.componentID = component.id
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
    }

    /// Resolves `{{ custom.* }}` template tokens in the URL using the provided custom variables,
    /// falling back to dashboard-configured defaults. Returns `nil` if the resolved string is
    /// not a valid URL.
    func resolvedURL(customVariables: [String: CustomVariableValue]) -> URL? {
        let handler = VariableHandlerV2(
            variableCompatibilityMap: uiConfigProvider.variableConfig.variableCompatibilityMap,
            functionCompatibilityMap: uiConfigProvider.variableConfig.functionCompatibilityMap,
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: customVariables,
            defaultCustomVariables: uiConfigProvider.defaultCustomVariables
        )
        let resolved = handler.processVariables(
            in: urlTemplate,
            with: nil,
            locale: localizationProvider.locale,
            localizations: [:],
            isEligibleForIntroOffer: false
        )
        guard let url = URL(string: resolved),
              url.isValidPaywallWebViewURL else {
            return nil
        }

        return url
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WebViewComponentViewModel: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(urlTemplate)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.urlTemplate == rhs.urlTemplate
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension URL {

    var isValidPaywallWebViewURL: Bool {
        return self.scheme?.lowercased() == "https" && self.host?.isEmpty == false
    }

}

#endif
