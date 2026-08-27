//
//  Copyright RevenueCat Inc. All Rights Reserved.
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
    let storefrontCountryCode: String?

    init(
        offering: Offering,
        packages: [Package],
        workflow: Workflow?,
        storefrontCountryCode: String?
    ) {
        var identifiers = Set<String>()

        self.offeringIdentifier = offering.identifier
        self.offeringDisplayName = offering.serverDescription
        self.packages = packages.filter { identifiers.insert($0.identifier).inserted }
        self.workflow = workflowreview
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
            offering: .object([
                "identifier": .string(self.offeringIdentifier),
                "display_name": .string(self.offeringDisplayName)
            ]),
            packages: .array(self.packages.map(self.packageValue)),
            package: package.map(self.packageValue) ?? .null,
            selectedPackage: selectedPackage.map(self.packageValue) ?? .null,
            workflow: self.workflow.map(Self.workflowValue) ?? .null,
            isPreview: false,
            localeIdentifier: locale.identifier,
            isDarkMode: isDarkMode
        )
    }

    private func packageValue(_ package: Package) -> PaywallWebViewValue {
        let product = package.storeProduct
        let period = product.subscriptionPeriod.map(Self.isoPeriod)

        return .object([
            "identifier": .string(package.identifier),
            "display_name": package.displayName.map(PaywallWebViewValue.string) ?? .null,
            "products": .array([
                .object([
                    "identifier": .string(product.productIdentifier),
                    "store": .object([
                        "store_type": .string("app_store"),
                        "country": self.storefrontCountryCode.map(PaywallWebViewValue.string) ?? .null
                    ]),
                    "display_name": .string(product.localizedTitle),
                    "is_subscription": .bool(product.productCategory == .subscription),
                    "period": period.map(PaywallWebViewValue.string) ?? .null,
                    "is_family_shareable": .bool(product.isFamilyShareable),
                    "is_auto_renewing": .bool(product.productType == .autoRenewableSubscription),
                    "price": .object([
                        "amount": .number(Self.doubleValue(product.price)),
                        "currency": product.currencyCode.map(PaywallWebViewValue.string) ?? .null
                    ])
                ])
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
            } ?? .null
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

    private static func isoPeriod(_ period: SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = "D"
        case .week: unit = "W"
        case .month: unit = "M"
        case .year: unit = "Y"
        @unknown default: unit = ""
        }
        return "P\(period.value)\(unit)"
    }

}

/// Semantic context delivered to a web view. `updated_at` is added only when the packet is sent.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewContext: Equatable {

    let custom: PaywallWebViewValue
    let offering: PaywallWebViewValue
    let packages: PaywallWebViewValue
    let package: PaywallWebViewValue
    let selectedPackage: PaywallWebViewValue
    let workflow: PaywallWebViewValue
    let localeIdentifier: String
    let isDarkMode: Bool

    func payload(updatedAt date: Date) -> [String: PaywallWebViewValue] {
        let updatedAtMilliseconds = floor(date.timeIntervalSince1970 * 1_000)

        return [
            "custom": self.custom,
            "offering": self.offering,
            "packages": self.packages,
            "package": self.package,
            "selected_package": self.selectedPackage,
            "workflow": self.workflow,
            "device_meta": .object([
                "is_preview": .bool(false),
                "locale": .string(self.localeIdentifier),
                "dark_mode": .bool(self.isDarkMode),
                "updated_at": .number(updatedAtMilliseconds)
            ])
        ]
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
