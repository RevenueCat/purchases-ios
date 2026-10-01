//
//  PaywallWebViewStaticContext.swift
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Created by Jacob Zivan Rakidzich on 8/28/26.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Page-level inputs that are shared by every web view in a rendered paywall.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewStaticContext {

    struct Workflow {
        let id: String
        let stepID: String
        let stepType: String?
        let screenType: [String]?
    }

    let offeringIdentifier: String
    let offeringDisplayName: String
    let packages: [Package]
    let workflow: Workflow?
    let store: String
    let storefrontCountryCode: String?

    // inputs are not yet supported. However the contract requires this data.
    let inputs: [String: String] = [:]

    init(
        offering: Offering,
        packages: [Package],
        workflow: Workflow?,
        store: String,
        storefrontCountryCode: String?
    ) {
        var identifiers = Set<String>()

        self.offeringIdentifier = offering.identifier
        self.offeringDisplayName = offering.serverDescription
        self.packages = packages.filter { identifiers.insert($0.identifier).inserted }
        self.workflow = workflow
        self.store = store
        self.storefrontCountryCode = storefrontCountryCode
    }

    func snapshot(
        package: Package?,
        selectedPackageID: String?,
        customVariables: [String: CustomVariableValue],
        locale: Locale,
        isDarkMode: Bool
    ) -> PaywallWebViewContext {
        let selectedPackage = selectedPackageID.flatMap { identifier in
            self.packages.first { $0.identifier == identifier }
        }

        return .init(
            custom: .object(customVariables.mapValues(Self.webValue)),
            inputs: .object(self.inputs.mapValues(PaywallWebViewValue.string)),
            offering: .object([
                "identifier": .string(self.offeringIdentifier),
                "display_name": .string(self.offeringDisplayName)
            ]),
            packages: .array(self.packages.map(self.packageValue)),
            package: package.map(self.packageValue) ?? .null,
            selectedPackage: selectedPackage.map(self.packageValue) ?? .null,
            workflow: self.workflow.map(Self.workflowValue),
            localeIdentifier: Self.bcp47Identifier(for: locale),
            isDarkMode: isDarkMode
        )
    }

    private func packageValue(_ package: Package) -> PaywallWebViewValue {
        let product = package.storeProduct
        let period = product.subscriptionPeriod.flatMap(Self.isoPeriod)
        var store: [String: PaywallWebViewValue] = [
            "store_type": .string(self.store)
        ]
        if let storefrontCountryCode = self.storefrontCountryCode {
            store["country"] = .string(storefrontCountryCode)
        }

        var price: [String: PaywallWebViewValue] = [
            "amount": .number(Self.doubleValue(product.price))
        ]
        if let currencyCode = product.currencyCode {
            price["currency"] = .string(currencyCode)
        }

        var productValue: [String: PaywallWebViewValue] = [
            "identifier": .string(product.productIdentifier),
            "store": .object(store),
            "display_name": .string(product.localizedTitle),
            "is_subscription": .bool(product.productCategory == .subscription),
            "is_family_shareable": .bool(product.isFamilyShareable),
            "is_auto_renewing": .bool(product.subscriptionPeriod != nil), // accounts for both sk1 and sk2
            "price": .object(price)
        ]
        if let period {
            productValue["period"] = .string(period)
        }

        return .object([
            "identifier": .string(package.identifier),
            "products": .array([
                .object(productValue)
            ])
        ])
    }

    private static func workflowValue(_ workflow: Workflow) -> PaywallWebViewValue {
        return .object([
            "workflow_id": .string(workflow.id),
            "step_id": .string(workflow.stepID),
            "step_type": workflow.stepType.map(PaywallWebViewValue.string) ?? .null,
            "screen_type": workflow.screenType.map {
                .array($0.map(PaywallWebViewValue.string))
            } ?? .array([])
        ])
    }

    private static func webValue(_ value: CustomVariableValue) -> PaywallWebViewValue {
        return value.map(
            string: PaywallWebViewValue.string,
            number: PaywallWebViewValue.number,
            boolean: PaywallWebViewValue.bool
        )
    }

    private static func doubleValue(_ value: Decimal) -> Double {
        // Converting through the decimal string avoids visible JSON artifacts such as
        // `53.989999999999995`. The result remains a `Double` because JavaScript uses `Number`.
        let decimalNumber = NSDecimalNumber(decimal: value)
        return Double(decimalNumber.stringValue) ?? decimalNumber.doubleValue
    }

    private static func bcp47Identifier(for locale: Locale) -> String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return Locale.identifier(.bcp47, from: locale.identifier)
        } else {
            return Locale.canonicalLanguageIdentifier(from: locale.identifier)
        }
    }

    private static func isoPeriod(_ period: SubscriptionPeriod) -> String? {
        let unit: String
        switch period.unit {
        case .day: unit = "D"
        case .week: unit = "W"
        case .month: unit = "M"
        case .year: unit = "Y"
        @unknown default: return nil
        }
        return "P\(period.value)\(unit)"
    }

}

/// Semantic context delivered to a web view. `updated_at` is added only when the packet is sent.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewContext: Equatable {

    let custom: PaywallWebViewValue
    let inputs: PaywallWebViewValue
    let offering: PaywallWebViewValue
    let packages: PaywallWebViewValue
    let package: PaywallWebViewValue
    let selectedPackage: PaywallWebViewValue
    let workflow: PaywallWebViewValue?
    let localeIdentifier: String
    let isDarkMode: Bool

    func payload(updatedAt date: Date) -> [String: PaywallWebViewValue] {
        let updatedAtMilliseconds = floor(date.timeIntervalSince1970 * 1_000)

        var payload: [String: PaywallWebViewValue] = [
            "custom": self.custom,
            "inputs": self.inputs,
            "offering": self.offering,
            "packages": self.packages,
            "package": self.package,
            "selected_package": self.selectedPackage,
            "device_meta": .object([
                "is_preview": .bool(false),
                "locale": .string(self.localeIdentifier),
                "dark_mode": .bool(self.isDarkMode),
                "updated_at": .number(updatedAtMilliseconds)
            ])
        ]
        if let workflow = self.workflow {
            payload["workflow"] = workflow
        }
        return payload
    }

    func payloadJSON(updatedAt date: Date = .now, encoder: JSONEncoder = .init()) -> String? {
        do {
            let data = try encoder.encode(payload(updatedAt: date))
            return String(data: data, encoding: .utf8)
        } catch {
            Logger.debug(Strings.web_view_context_encoding_failed(error))
            return nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallWebViewStaticContextKey: EnvironmentKey {
    static let defaultValue: PaywallWebViewStaticContext? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallWebViewStaticContext: PaywallWebViewStaticContext? {
        get { self[PaywallWebViewStaticContextKey.self] }
        set { self[PaywallWebViewStaticContextKey.self] = newValue }
    }

}

#endif
