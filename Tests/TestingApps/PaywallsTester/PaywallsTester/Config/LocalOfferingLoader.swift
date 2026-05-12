//
//  LocalOfferingLoader.swift
//  PaywallsTester
//
//  Hermetic loader for paywall offerings from a local `offerings.json` file.
//

import Foundation
import StoreKit
@_spi(Internal) import RevenueCat
#if DEBUG
@testable import RevenueCatUI
#else
import RevenueCatUI
#endif

/// Loads a single paywall offering from a local `offerings.json` file, without contacting
/// the RevenueCat backend or requiring an API key.
///
/// **Asset URL rewriting** — to keep the load fully offline, remote asset URLs in the JSON
/// are rewritten to `file://` URLs pointing at directories adjacent to the JSON file. This
/// matches the convention used by `Tests/RevenueCatUITests/PaywallsV2/PaywallPreviewResourcesLoader`:
///
/// ```
/// my-fixture/
/// ├── offerings.json
/// ├── pawwalls/
/// │   ├── assets/      ← images, hero art, etc.
/// │   └── icons/       ← icon library files
/// ```
///
/// When an asset file does not exist locally, image/icon loading silently fails and the paywall
/// renders without it. The accessibility tree is still captured correctly.
///
/// **Mock packages** — the loader injects a standard set of mock packages
/// (`$rc_annual`, `$rc_monthly`, etc.) backed by `PreviewMock.Product` instances. Real
/// `SKProduct`s are not required to render the paywall component graph; only package
/// resolution matters.
enum LocalOfferingLoader {

    enum LoaderError: Swift.Error, CustomStringConvertible {
        case fileNotReadable(path: String)
        case malformedJSON
        case offeringNotFound(id: String, availableIds: [String])
        case paywallComponentsDecodeFailed(offeringId: String, underlying: Swift.Error)

        var description: String {
            switch self {
            case .fileNotReadable(let path):
                return "LocalOfferingLoader: could not read file at \(path)"
            case .malformedJSON:
                return "LocalOfferingLoader: top-level JSON is not a dictionary"
            case .offeringNotFound(let id, let availableIds):
                return "LocalOfferingLoader: offering '\(id)' not found. Available: \(availableIds)"
            case .paywallComponentsDecodeFailed(let offeringId, let underlying):
                return "LocalOfferingLoader: failed to decode paywall_components for \(offeringId): \(underlying)"
            }
        }
    }

    /// Reads `offerings.json` at `path`, locates the offering whose `identifier` matches
    /// `offeringId`, and returns a fully constructed `Offering` with a `PaywallComponents`
    /// payload and a standard set of mock packages.
    static func loadOffering(from path: String, matching offeringId: String) throws -> Offering {
        let fileURL = URL(fileURLWithPath: path)
        let baseDir = fileURL.deletingLastPathComponent()

        guard let raw = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw LoaderError.fileNotReadable(path: path)
        }

        // Rewrite remote asset URLs → local file:// URLs adjacent to the JSON.
        let assetsBase = baseDir.appendingPathComponent("pawwalls/assets").absoluteString
        let iconsBase = baseDir.appendingPathComponent("pawwalls/icons").absoluteString
        let rewritten = raw
            .replacingOccurrences(of: "https://assets.pawwalls.com", with: assetsBase)
            .replacingOccurrences(of: "https://icons.pawwalls.com", with: iconsBase)

        guard let data = rewritten.data(using: .utf8),
              let top = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LoaderError.malformedJSON
        }

        let offeringsArray = (top["offerings"] as? [[String: Any]]) ?? []
        guard let offeringDict = offeringsArray.first(where: { $0["identifier"] as? String == offeringId }) else {
            let availableIds = offeringsArray.compactMap { $0["identifier"] as? String }
            throw LoaderError.offeringNotFound(id: offeringId, availableIds: availableIds)
        }

        // Decode the `paywall_components` sub-tree.
        // Inject sensible defaults for required keys that are commonly absent from
        // hand-curated fixture files. Missing keys would otherwise accumulate decode
        // errors and trigger the PaywallFallbackError view instead of the real paywall.
        var pcDict = offeringDict["paywall_components"] as? [String: Any] ?? [:]
        pcDict["template_name"] = pcDict["template_name"] ?? "components"
        pcDict["asset_base_url"] = pcDict["asset_base_url"] ?? assetsBase
        pcDict["default_locale"] = pcDict["default_locale"] ?? "en_US"
        pcDict["revision"] = pcDict["revision"] ?? 0
        // Note: don't inject `zero_decimal_place_countries` — the decoder expects a
        // nested struct `{ "apple": [...] }`, not a plain array. Leaving it absent lets
        // `decodeIfPresent` default to `[]`.
        let decoder = Self.makeDecoder()
        let pcData: PaywallComponentsData
        do {
            let pcJSON = try JSONSerialization.data(withJSONObject: pcDict)
            pcData = try decoder.decode(PaywallComponentsData.self, from: pcJSON)
        } catch {
            throw LoaderError.paywallComponentsDecodeFailed(offeringId: offeringId, underlying: error)
        }

        // UIConfig is optional at the response level. When absent, fall back to a
        // sensible default that includes English localization keys for `% OFF`, etc.
        let uiConfig: UIConfig = {
            if let dict = top["ui_config"] as? [String: Any],
               let json = try? JSONSerialization.data(withJSONObject: dict),
               let decoded = try? decoder.decode(UIConfig.self, from: json) {
                return decoded
            }
            return PreviewUIConfig.make()
        }()

        let serverDescription = offeringDict["description"] as? String ?? ""

        return Offering(
            identifier: offeringId,
            serverDescription: serverDescription,
            metadata: [:],
            paywall: nil,
            paywallComponents: .init(uiConfig: uiConfig, data: pcData),
            availablePackages: makeStandardPackages(offeringId: offeringId),
            webCheckoutUrl: nil
        )
    }

    // MARK: - Decoder

    /// Decoder matching the SDK's `JSONDecoder.default` snake_case strategy.
    /// We can't reach the internal `JSONDecoder.default` extension from this target,
    /// so we replicate the relevant part here.
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Mock packages

    /// Standard set of mock packages covering the common `$rc_*` identifiers.
    /// All-in-one so any offering referencing them via `package_id` resolves cleanly.
    private static func makeStandardPackages(offeringId: String) -> [Package] {
        let specs: [(id: String, type: PackageType, unit: SKProduct.PeriodUnit, title: String, price: Double)] = [
            ("$rc_lifetime",    .lifetime,   .year,  "Lifetime", 99.99),
            ("$rc_annual",      .annual,     .year,  "Annual",   49.99),
            ("$rc_six_month",   .sixMonth,   .month, "6 Month",  29.99),
            ("$rc_three_month", .threeMonth, .month, "3 Month",  14.99),
            ("$rc_two_month",   .twoMonth,   .month, "2 Month",  9.99),
            ("$rc_monthly",     .monthly,    .month, "Monthly",  4.99),
            ("$rc_weekly",      .weekly,     .week,  "Weekly",   1.99)
        ]
        return specs.map { spec in
            Package(
                identifier: spec.id,
                packageType: spec.type,
                storeProduct: .init(sk1Product: PreviewMock.Product(
                    price: NSDecimalNumber(value: spec.price),
                    unit: spec.unit,
                    localizedTitle: spec.title
                )),
                offeringIdentifier: offeringId,
                webCheckoutUrl: nil
            )
        }
    }
}
