//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPreviewRenderer.swift
//
//  Renders a Paywalls V2 preview from a local JSON string. This entire file is compiled only in
//  DEBUG (non-release) SDK builds so dashboard fixtures can be pasted into previews without
//  shipping in production.

import Foundation
@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

#if DEBUG && !os(tvOS)

/// Loads `PaywallComponentsData` JSON and builds a preview `Offering`.
///
/// Usage in a future PR:
/// ```swift
/// struct MyFeature_Previews: PreviewProvider {
///     static var previews: some View {
///         PaywallPreviewFromJSON(json: Self.json)
///             .previewLayout(.fixed(width: 402, height: 800))
///             .previewDisplayName("My feature")
///     }
///
///     static let json = #"""
///     { ... paywall components JSON ... }
///     """#
/// }
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
enum PaywallPreviewRenderer {

    struct Fixture {
        let offering: Offering
        let paywallComponents: Offering.PaywallComponents
    }

    enum LoadingError: LocalizedError {
        case decoding(Error)
        case paywallErrors(String)

        var errorDescription: String? {
            switch self {
            case .decoding(let error):
                return "Unable to decode paywall preview JSON: \(error.localizedDescription)"
            case .paywallErrors(let details):
                return "Unable to decode paywall preview JSON:\n\(details)"
            }
        }
    }

    /// Dashboard-shaped `PaywallComponentsData` JSON for the sample preview and unit tests.
    /// Includes required fields (`revision`, `padding`, `margin`) so the resilient decoder
    /// does not record `errorInfo` and fall back to the default paywall.
    static let sampleJSON = """
    {
      "template_name": "components",
      "asset_base_url": "https://assets.pawwalls.com",
      "revision": 1,
      "default_locale": "en_US",
      "components_config": {
        "base": {
          "background": {
            "type": "color",
            "value": {
              "light": { "type": "hex", "value": "#ffffffff" }
            }
          },
          "stack": {
            "type": "stack",
            "components": [
              {
                "type": "text",
                "text_lid": "title",
                "color": {
                  "light": { "type": "hex", "value": "#111111ff" }
                },
                "font_size": 24,
                "font_weight": "bold",
                "horizontal_alignment": "center",
                "size": {
                  "width": { "type": "fit" },
                  "height": { "type": "fit" }
                },
                "padding": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 },
                "margin": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 }
              }
            ],
            "size": {
              "width": { "type": "fill" },
              "height": { "type": "fit" }
            },
            "dimension": {
              "type": "vertical",
              "alignment": "center",
              "distribution": "center"
            },
            "padding": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 },
            "margin": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 }
          }
        }
      },
      "components_localizations": {
        "en_US": { "title": "JSON paywall preview" }
      }
    }
    """

    static func load(
        json: String,
        offeringIdentifier: String = "json-preview",
        serverDescription: String = "JSON paywall preview",
        packages: [Package]? = nil,
        uiConfig: UIConfig = PreviewUIConfig.make()
    ) throws -> Fixture {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let jsonData = Data(json.utf8)
        let data: PaywallComponentsData
        do {
            data = try decoder.decode(PaywallComponentsData.self, from: jsonData)
        } catch {
            throw LoadingError.decoding(error)
        }

        if let errorInfo = data.errorInfo, !errorInfo.isEmpty {
            let details = errorInfo
                .map { "\($0.key): \($0.value)" }
                .sorted()
                .joined(separator: "\n")
            throw LoadingError.paywallErrors(details)
        }

        let paywallComponents = Offering.PaywallComponents(uiConfig: uiConfig, data: data)
        let resolvedPackages = packages ?? self.defaultPackages(offeringIdentifier: offeringIdentifier)
        let offering = Offering(
            identifier: offeringIdentifier,
            serverDescription: serverDescription,
            paywallComponents: paywallComponents,
            availablePackages: resolvedPackages,
            webCheckoutUrl: nil
        )

        return Fixture(offering: offering, paywallComponents: paywallComponents)
    }

    static func defaultPackages(offeringIdentifier: String) -> [Package] {
        return [
            self.package(
                identifier: "$rc_weekly",
                type: .weekly,
                price: 4.99,
                period: .week,
                title: "Weekly",
                offeringIdentifier: offeringIdentifier
            ),
            self.package(
                identifier: "$rc_monthly",
                type: .monthly,
                price: 12.99,
                period: .month,
                title: "Monthly",
                offeringIdentifier: offeringIdentifier
            ),
            self.package(
                identifier: "$rc_annual",
                type: .annual,
                price: 69.99,
                period: .year,
                title: "Annual",
                offeringIdentifier: offeringIdentifier
            )
        ]
    }

    // swiftlint:disable:next function_parameter_count
    private static func package(
        identifier: String,
        type: PackageType,
        price: NSDecimalNumber,
        period: SKProduct.PeriodUnit,
        title: String,
        offeringIdentifier: String
    ) -> Package {
        return Package(
            identifier: identifier,
            packageType: type,
            storeProduct: .init(sk1Product: PreviewMock.Product(
                price: price,
                unit: period,
                localizedTitle: title
            )),
            offeringIdentifier: offeringIdentifier,
            webCheckoutUrl: nil
        )
    }

}

/// SwiftUI preview host that decodes local paywall JSON and renders `PaywallsV2View`.
@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct PaywallPreviewFromJSON: View {

    let json: String
    var offeringIdentifier: String = "json-preview"
    var serverDescription: String = "JSON paywall preview"
    var packages: [Package]?
    var colorScheme: ColorScheme = .light
    var expandForEmerge: Bool = true

    var body: some View {
        Group {
            switch Result(catching: {
                try PaywallPreviewRenderer.load(
                    json: json,
                    offeringIdentifier: offeringIdentifier,
                    serverDescription: serverDescription,
                    packages: packages
                )
            }) {
            case .success(let fixture):
                PaywallsV2View(
                    paywallComponents: fixture.paywallComponents,
                    offering: fixture.offering,
                    purchaseHandler: PurchaseHandler.default(),
                    introEligibilityChecker: .default(),
                    showZeroDecimalPlacePrices: true,
                    onDismiss: { },
                    failedToLoadFont: { _ in },
                    colorScheme: colorScheme
                )
                .previewRequiredPaywallsV2Properties()
                .emergeExpansion(expandForEmerge)

            case .failure(let error):
                Text("Unable to load JSON paywall preview:\n\(error.localizedDescription)")
                    .padding()
            }
        }
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct PaywallPreviewRenderer_Previews: PreviewProvider {

    static var previews: some View {
        PaywallPreviewFromJSON(json: PaywallPreviewRenderer.sampleJSON)
            .previewDisplayName("JSON paywall preview")
    }

}

#endif
