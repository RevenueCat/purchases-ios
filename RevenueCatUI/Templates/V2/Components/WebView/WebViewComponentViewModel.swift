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

    private let urlString: String
    private let localizationProvider: LocalizationProvider

    let size: PaywallComponent.Size
    let visible: Bool

    /// The schema component identifier, used as the canonical `component_id` for the postMessage
    /// bridge. `nil` for legacy/partial configs that omit `id`, in which case the bridge is disabled.
    let componentID: String?

    /// The schema-declared `protocol_version`. Defaults to `1` when omitted.
    let protocolVersion: Int

    /// The locale resolved for this paywall, exposed as an SDK-managed `locale` variable.
    var locale: Locale {
        self.localizationProvider.locale
    }

    /// The static HTTPS URL to load. Variables never touch the URL.
    var url: URL? {
        guard let url = URL(string: self.urlString),
              url.isValidPaywallWebViewURL else {
            return nil
        }

        return url
    }

    init(
        component: PaywallComponent.WebViewComponent,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) {
        self.urlString = component.url
        self.size = component.size
        self.visible = component.visible ?? true
        self.componentID = component.id
        self.protocolVersion = component.protocolVersion
        self.localizationProvider = localizationProvider
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WebViewComponentViewModel: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.urlString)
        hasher.combine(self.componentID)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.urlString == rhs.urlString && lhs.componentID == rhs.componentID
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension URL {

    var isValidPaywallWebViewURL: Bool {
        return self.scheme?.lowercased() == "https" && self.host?.isEmpty == false
    }

}

#endif
