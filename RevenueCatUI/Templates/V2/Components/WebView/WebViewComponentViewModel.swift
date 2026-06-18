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
    private let htmlFileRepository: InMemoryHTMLFileRepositoryType

    let size: PaywallComponent.Size
    let visible: Bool

    /// Stack rendered when the web content cannot be displayed (e.g. the resolved URL is invalid).
    let fallbackStackViewModel: StackComponentViewModel?

    init(
        component: PaywallComponent.WebViewComponent,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        fallbackStackViewModel: StackComponentViewModel? = nil,
        htmlFileRepository: InMemoryHTMLFileRepositoryType = InMemoryHTMLFileRepository.shared
    ) {
        self.urlTemplate = component.url
        self.size = component.size
        self.visible = component.visible ?? true
        self.fallbackStackViewModel = fallbackStackViewModel
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.htmlFileRepository = htmlFileRepository
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

    /// Returns the locally-cached file URL for a given resolved URL, or `nil` if not cached.
    func cachedURL(for resolvedURL: URL) -> URL? {
        htmlFileRepository.getCachedFileURL(for: resolvedURL)
    }

    /// Convenience: resolves using only dashboard default variables, then checks the file cache.
    /// Useful for cache pre-warming checks and tests using non-template URLs.
    var displayURL: URL? {
        resolvedURL(customVariables: [:]).flatMap { cachedURL(for: $0) }
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
