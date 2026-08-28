//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Host-app Web Billing (`rcb_`) key + identity for the bundled purchases-js checkout page.
/// Missing key, bundle files, or Purchases config → no web checkout.
struct EmbeddedCheckoutConfig: Equatable {

    let apiKey: String
    let appUserID: String
    let offeringId: String
    let packageId: String?

    private static let infoDictionaryKey = "WEB_BILLING_API_KEY"
    private static let unresolvedPlaceholder = "$(WEB_BILLING_API_KEY)"
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
                "Set it in Local.xcconfig and rebuild."
            ))
            return nil
        }
        guard resourcesAreBundled else {
            Logger.error(Strings.embedded_checkout_skipped(
                "index.html / Purchases.umd.js not found in \(Bundle.revenueCatUI.bundleURL.path). " +
                "Clean build RevenueCatUI."
            ))
            return nil
        }
        guard Purchases.isConfigured else {
            Logger.error(Strings.embedded_checkout_skipped("Purchases is not configured."))
            return nil
        }

        Logger.debug(Strings.embedded_checkout_using_bundle)
        return EmbeddedCheckoutConfig(
            apiKey: apiKey,
            appUserID: Purchases.shared.appUserID,
            offeringId: offeringId,
            packageId: packageId
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
        Bundle.revenueCatUI.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: resourceSubdirectory
        )
    }

    private static var umdResourceURL: URL? {
        Bundle.revenueCatUI.url(
            forResource: "Purchases.umd",
            withExtension: "js",
            subdirectory: resourceSubdirectory
        )
    }

}

#endif
