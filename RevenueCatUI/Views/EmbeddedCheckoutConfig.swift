//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Host-app Web Billing (`rcb_`) key + identity for the bundled purchases-js checkout page.
/// Unset key → callers keep using `webCheckoutUrl`.
struct EmbeddedCheckoutConfig: Equatable {

    let apiKey: String
    let appUserID: String
    let offeringId: String
    let packageId: String?

    private static let infoDictionaryKey = "WEB_BILLING_API_KEY"
    private static let unresolvedPlaceholder = "$(WEB_BILLING_API_KEY)"
    private static let htmlResourceName = "index"
    private static let htmlResourceExtension = "html"
    private static let umdResourceName = "Purchases.umd"
    private static let umdResourceExtension = "js"
    private static let resourceSubdirectory = "EmbeddedCheckout"

    static let pageBaseURL = URL(string: "http://localhost") ?? URL(fileURLWithPath: "/")

    static func resolvedWebBillingAPIKey(
        from raw: String? = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
    ) -> String? {
        guard let raw else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != unresolvedPlaceholder else {
            return nil
        }
        return trimmed
    }

    static var resourcesAreBundled: Bool {
        htmlResourceURL != nil && umdResourceURL != nil
    }

    static func make(offeringId: String, packageId: String?) -> EmbeddedCheckoutConfig? {
        guard let apiKey = resolvedWebBillingAPIKey() else {
            let raw = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            Logger.error(Strings.embedded_checkout_skipped(
                "WEB_BILLING_API_KEY missing in Info.plist (saw \(raw ?? "nil")). " +
                "Rebuild after setting it in Local.xcconfig."
            ).description)
            return nil
        }
        guard resourcesAreBundled else {
            Logger.error(Strings.embedded_checkout_skipped(
                "index.html / Purchases.umd.js not found in \(Bundle.revenueCatUI.bundleURL.path). " +
                "Clean build RevenueCatUI."
            ).description)
            return nil
        }
        guard Purchases.isConfigured else {
            Logger.error(Strings.embedded_checkout_skipped("Purchases is not configured.").description)
            return nil
        }

        Logger.error(Strings.embedded_checkout_using_bundle.description)
        return EmbeddedCheckoutConfig(
            apiKey: apiKey,
            appUserID: Purchases.shared.appUserID,
            offeringId: offeringId,
            packageId: packageId
        )
    }

    /// Sentinel URL used to present the in-app browser sheet. The web view loads assembled HTML, not this URL.
    var checkoutURL: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.path = "/embedded-checkout/\(self.appUserID)"

        var queryItems = [
            URLQueryItem(name: "offeringId", value: self.offeringId)
        ]
        if let packageId = self.packageId {
            queryItems.append(URLQueryItem(name: "packageId", value: packageId))
        }
        components.queryItems = queryItems

        return components.url ?? Self.pageBaseURL
    }

    static func isBundledCheckoutURL(_ url: URL) -> Bool {
        return url.scheme == "http"
            && url.host == "localhost"
            && url.path.contains("embedded-checkout")
    }

    static func make(from url: URL) -> EmbeddedCheckoutConfig? {
        guard isBundledCheckoutURL(url),
              let apiKey = resolvedWebBillingAPIKey() else {
            return nil
        }

        let pathParts = url.path.split(separator: "/").map(String.init)
        guard pathParts.count >= 2 else {
            return nil
        }
        let appUserID = pathParts[1]

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func query(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        guard let offeringId = query("offeringId"), !offeringId.isEmpty else {
            return nil
        }

        return EmbeddedCheckoutConfig(
            apiKey: apiKey,
            appUserID: appUserID,
            offeringId: offeringId,
            packageId: query("packageId")
        )
    }

    func assembledHTML() -> String? {
        guard let htmlURL = Self.htmlResourceURL,
              let umdURL = Self.umdResourceURL,
              var html = try? String(contentsOf: htmlURL, encoding: .utf8),
              let umd = try? String(contentsOf: umdURL, encoding: .utf8),
              let configJSON = self.jsonObjectString() else {
            return nil
        }

        let escapedUMD = umd.replacingOccurrences(
            of: "</script",
            with: "<\\/script",
            options: .caseInsensitive
        )
        html = html.replacingOccurrences(of: "__RC_EMBEDDED_CHECKOUT_JSON__", with: configJSON)
        html = html.replacingOccurrences(of: "__PURCHASES_JS_UMD__", with: escapedUMD)
        return html
    }

    func jsonObjectString() -> String? {
        var object: [String: Any] = [
            "apiKey": self.apiKey,
            "appUserId": self.appUserID,
            "offeringId": self.offeringId
        ]
        object["packageId"] = self.packageId as Any? ?? NSNull()

        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private static var htmlResourceURL: URL? {
        Self.resourceURL(name: htmlResourceName, ext: htmlResourceExtension)
    }

    private static var umdResourceURL: URL? {
        Self.resourceURL(name: umdResourceName, ext: umdResourceExtension)
    }

    private static func resourceURL(name: String, ext: String) -> URL? {
        let filename = "\(name).\(ext)"
        for bundle in [Bundle.revenueCatUI, Bundle.main] {
            if let url = bundle.url(
                forResource: name,
                withExtension: ext,
                subdirectory: resourceSubdirectory
            ) {
                return url
            }
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
            let nested = bundle.bundleURL
                .appendingPathComponent(resourceSubdirectory)
                .appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: nested.path) {
                return nested
            }
        }
        return nil
    }

}

#endif
