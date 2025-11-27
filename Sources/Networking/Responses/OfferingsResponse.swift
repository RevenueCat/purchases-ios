//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsResponse.swift
//
//  Created by Nacho Soto on 3/31/22.

import Foundation

struct OfferingsResponse {

    struct Offering {

        // swiftlint:disable:next nesting
        struct Package {

            let identifier: String
            let platformProductIdentifier: String
            let webCheckoutUrl: URL?

        }

        let identifier: String
        let description: String
        let packages: [Package]
        @IgnoreDecodeErrors<PaywallData?>
        var paywall: PaywallData?
        @DefaultDecodable.EmptyDictionary
        var metadata: [String: AnyDecodable]
        var paywallComponents: PaywallComponentsData?
        var draftPaywallComponents: PaywallComponentsData?
        let webCheckoutUrl: URL?
    }

    struct Placements {
        let fallbackOfferingId: String?
        @DefaultDecodable.EmptyDictionary
        var offeringIdsByPlacement: [String: String?]
    }

    struct Targeting {
        let revision: Int
        let ruleId: String
    }

    struct Config {
        @DefaultDecodable.EmptyDictionary
        var priceFormattingRuleSets: [
            // storefront country code -> ruleset
            String: PriceFormattingRuleSet
        ]

        init(priceFormattingRuleSets: [String: PriceFormattingRuleSet]) {
            self.priceFormattingRuleSets = priceFormattingRuleSets
        }
    }

    let currentOfferingId: String?
    let offerings: [Offering]
    let placements: Placements?
    let targeting: Targeting?
    let uiConfig: UIConfig?
    let config: Config?
}

extension OfferingsResponse {

    var productIdentifiers: Set<String> {
        return Set(
            self.offerings
                .lazy
                .flatMap { $0.packages }
                .map { $0.platformProductIdentifier }
        )
    }

    var hasAnyWebCheckoutUrl: Bool {
        return self.offerings
            .lazy
            .contains { $0.webCheckoutUrl != nil }
    }

    var packages: [Offering.Package] {
        return self.offerings.flatMap { $0.packages }
    }
}

extension OfferingsResponse.Offering.Package: Codable, Equatable {}
extension OfferingsResponse.Offering: Codable, Equatable {}
extension OfferingsResponse.Placements: Codable, Equatable {}
extension OfferingsResponse.Targeting: Codable, Equatable {}
extension OfferingsResponse.Config: Codable, Equatable {}
extension OfferingsResponse: Codable, Equatable {}

extension OfferingsResponse: HTTPResponseBody {}

/*
 Contains a set of rules that will be used when formatting a price
 Currrently only supports overriding the currencySymbol per currency
 */
struct PriceFormattingRuleSet: Sendable {

    // currencyCode: CurrencySymbolOverride
    private var currencySymbolOverrides: [String: CurrencySymbolOverride]

    init(currencySymbolOverrides: [String: CurrencySymbolOverride]) {
        self.currencySymbolOverrides = currencySymbolOverrides
    }

    func currencySymbolOverride(
        currencyCode: String
    ) -> CurrencySymbolOverride? {
        return self.currencySymbolOverrides[currencyCode]
    }

    /*
     Contains a set of currencySymbol overrides for different pluralization rules
     */
    struct CurrencySymbolOverride: Sendable {
        let zero: String
        let one: String
        let two: String
        let few: String
        let many: String
        let other: String

        func value(for rule: PluralRule) -> String {
            switch rule {
            case .zero:
                return self.zero
            case .one:
                return self.one
            case .two:
                return self.two
            case .few:
                return self.few
            case .many:
                return self.many
            case .other:
                return self.other
            }
        }

        // swiftlint:disable:next nesting
        public enum PluralRule {
            case zero, one, two, few, many, other
        }
    }
}

extension PriceFormattingRuleSet: Codable, Equatable {}
extension PriceFormattingRuleSet.CurrencySymbolOverride: Codable, Equatable {}
