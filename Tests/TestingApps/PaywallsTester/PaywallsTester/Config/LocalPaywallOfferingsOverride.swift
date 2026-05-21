//
//  LocalPaywallOfferingsOverride.swift
//  PaywallsTester
//
//  Created by RevenueCat on 5/21/26.
//

import Foundation

struct LocalPaywallOfferingsOverrideSettings: Codable, Equatable {

    var paywallComponentsJSON: String
    var productIdentifiersByPackageIdentifier: [String: String]
    var uiConfigJSON: String

    var isActive: Bool {
        return !self.paywallComponentsJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var sanitizedProductIdentifiersByPackageIdentifier: [String: String] {
        return self.productIdentifiersByPackageIdentifier.reduce(into: [:]) { result, element in
            let packageIdentifier = element.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let productIdentifier = element.value.trimmingCharacters(in: .whitespacesAndNewlines)

            if !packageIdentifier.isEmpty, !productIdentifier.isEmpty {
                result[packageIdentifier] = productIdentifier
            }
        }
    }

    static let `default`: Self = .init(
        paywallComponentsJSON: "",
        productIdentifiersByPackageIdentifier: Self.defaultProductIdentifiersByPackageIdentifier,
        uiConfigJSON: Self.defaultUIConfigJSON
    )

    static let defaultProductIdentifiersByPackageIdentifier = [
        "$rc_weekly": "com.revenuecat.simpleapp.weekly",
        "$rc_monthly": "com.revenuecat.simpleapp.monthly",
        "$rc_annual": "com.revenuecat.simpleapp.yearly",
        "$rc_lifetime": "com.revenuecat.simpleapp.lifetime"
    ]

    static let defaultUIConfigJSON = """
    {
      "app": {
        "colors": {},
        "fonts": {}
      },
      "localizations": {
        "en_US": {}
      },
      "custom_variables": {
        "user_name": {
          "default_value": "anon",
          "type": "string"
        }
      },
      "variable_config": {
        "function_compatibility_map": {},
        "variable_compatibility_map": {}
      }
    }
    """

}

enum LocalPaywallOfferingsOverrideStore {

    private static let userDefaultsKey = "com.revenuecat.PaywallsTester.localPaywallOfferingsOverride"

    static var settings: LocalPaywallOfferingsOverrideSettings {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
                let settings = try? JSONDecoder().decode(LocalPaywallOfferingsOverrideSettings.self, from: data)
            else {
                return .default
            }

            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
            }
        }
    }

    static var isActive: Bool {
        return Self.settings.isActive
    }

}

enum LocalPaywallOfferingsResponseFactory {

    static func makeOfferingsResponseData(settings: LocalPaywallOfferingsOverrideSettings) throws -> Data {
        let payload = try Self.makeOfferingsResponseJSONObject(settings: settings)

        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    static func makeOfferingsResponseJSONObject(
        settings: LocalPaywallOfferingsOverrideSettings
    ) throws -> [String: Any] {
        let paywallComponents = try Self.loadJSONObject(
            from: settings.paywallComponentsJSON,
            emptyError: .missingPaywallComponentsJSON,
            invalidError: .invalidPaywallComponentsJSON
        )
        let offeringIdentifier = Self.offeringIdentifier(in: paywallComponents)
        let packages = Self.makePackages(from: paywallComponents, settings: settings)

        return [
            "current_offering_id": offeringIdentifier,
            "offerings": [
                [
                    "identifier": offeringIdentifier,
                    "description": "Local Paywalls Tester override",
                    "metadata": [:],
                    "packages": packages,
                    "paywall_components": paywallComponents
                ]
            ],
            "ui_config": try Self.uiConfigJSONObject(from: settings.uiConfigJSON)
        ]
    }

}

private extension LocalPaywallOfferingsResponseFactory {

    static func loadJSONObject(
        from jsonString: String,
        emptyError: LocalPaywallOfferingsOverrideError,
        invalidError: LocalPaywallOfferingsOverrideError
    ) throws -> [String: Any] {
        let trimmedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedJSON.isEmpty else {
            throw emptyError
        }

        let data = Data(trimmedJSON.utf8)
        let jsonObject = try JSONSerialization.jsonObject(with: data)

        guard let json = jsonObject as? [String: Any] else {
            throw invalidError
        }

        return json
    }

    static func uiConfigJSONObject(from jsonString: String) throws -> [String: Any] {
        if jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try Self.loadJSONObject(
                from: LocalPaywallOfferingsOverrideSettings.defaultUIConfigJSON,
                emptyError: .invalidUIConfigJSON,
                invalidError: .invalidUIConfigJSON
            )
        }

        return try Self.loadJSONObject(
            from: jsonString,
            emptyError: .invalidUIConfigJSON,
            invalidError: .invalidUIConfigJSON
        )
    }

    static func offeringIdentifier(in paywallComponents: [String: Any]) -> String {
        let rawIdentifier = paywallComponents["offering_id"] as? String
            ?? paywallComponents["offeringId"] as? String

        return rawIdentifier.flatMap { $0.isEmpty ? nil : $0 } ?? "debug_local_paywall"
    }

    static func makePackages(
        from paywallComponents: [String: Any],
        settings: LocalPaywallOfferingsOverrideSettings
    ) -> [[String: String]] {
        let mappings = settings.sanitizedProductIdentifiersByPackageIdentifier
        let extractedPackageIdentifiers = Array(Set(Self.packageIdentifiers(in: paywallComponents))).sorted()
        let packageIdentifiers = extractedPackageIdentifiers.isEmpty
            ? Array(mappings.keys).sorted()
            : extractedPackageIdentifiers
        let packages = packageIdentifiers.compactMap { identifier -> [String: String]? in
            guard let productIdentifier = mappings[identifier] else {
                return nil
            }

            return [
                "identifier": identifier,
                "platform_product_identifier": productIdentifier
            ]
        }

        if packages.isEmpty, !extractedPackageIdentifiers.isEmpty {
            return mappings.keys.sorted().map { identifier in
                [
                    "identifier": identifier,
                    "platform_product_identifier": mappings[identifier] ?? ""
                ]
            }
        }

        return packages
    }

    static func packageIdentifiers(in object: Any) -> [String] {
        if let dictionary = object as? [String: Any] {
            return dictionary.flatMap { key, value -> [String] in
                if (key == "package_id" || key == "packageId"), let identifier = value as? String {
                    return [identifier]
                }

                return Self.packageIdentifiers(in: value)
            }
        }

        if let array = object as? [Any] {
            return array.flatMap(Self.packageIdentifiers(in:))
        }

        return []
    }

}

enum LocalPaywallOfferingsOverrideError: LocalizedError {

    case invalidRequestURL
    case invalidResponse
    case missingPaywallComponentsJSON
    case invalidPaywallComponentsJSON
    case invalidUIConfigJSON

    var errorDescription: String? {
        switch self {
        case .invalidRequestURL:
            return "The intercepted RevenueCat request did not include a valid URL."
        case .invalidResponse:
            return "Failed to create a mock RevenueCat HTTP response."
        case .missingPaywallComponentsJSON:
            return "Paste paywall component JSON before enabling the local override."
        case .invalidPaywallComponentsJSON:
            return "Paywall component JSON must be a JSON object."
        case .invalidUIConfigJSON:
            return "UI config JSON must be a JSON object."
        }
    }

}
