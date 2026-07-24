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

    enum DecodingMode: Hashable, Sendable {
        case withPaywallComponents
        case withoutPaywallComponents
    }

    // The non-empty static key cannot fail construction.
    // swiftlint:disable force_unwrapping
    fileprivate static let decodingModeUserInfoKey = CodingUserInfoKey(
        rawValue: "com.revenuecat.offerings-response-decoding-mode"
    )!
    // swiftlint:enable force_unwrapping

    struct Offering {

        // swiftlint:disable:next nesting
        struct Package {

            let identifier: String
            let platformProductIdentifier: String
            let platformProductPlanIdentifier: String?
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
        var hasPaywallComponents: Bool?
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

    let currentOfferingId: String?
    let offerings: [Offering]
    let placements: Placements?
    let targeting: Targeting?
    let uiConfig: UIConfig?

}

extension OfferingsResponse {

    static func create(with data: Data, decodingMode: DecodingMode) throws -> Self {
        return try self.makeDecoder(decodingMode: decodingMode).decode(jsonData: data)
    }

    static func makeDecoder(decodingMode: DecodingMode) -> JSONDecoder {
        let decoder = JSONDecoder.makeDefault()
        decoder.userInfo[Self.decodingModeUserInfoKey] = decodingMode
        return decoder
    }

    var productIdentifiers: Set<String> {
        return Set(
            self.offerings
                .lazy
                .flatMap { $0.packages }
                .map(\.compoundProductIdentifier)
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

extension OfferingsResponse.Offering.Package {
    var compoundProductIdentifier: String {
        let productPlanIdentifier = BillingPlanType.compoundProductIDPlanComponent(
            from: self.platformProductPlanIdentifier
        )

        return CompoundProductIdentifier(
            productIdentifier: self.platformProductIdentifier,
            productPlanIdentifier: productPlanIdentifier
        )?.compoundProductIdentifier ?? self.platformProductIdentifier
    }
}

extension OfferingsResponse.Offering.Package: Codable, Equatable {}
extension OfferingsResponse.Offering: Codable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case identifier
        case description
        case packages
        case paywall
        case metadata
        case paywallComponents
        case hasPaywallComponents
        case webCheckoutUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.description = try container.decode(String.self, forKey: .description)
        self.packages = try container.decode([Package].self, forKey: .packages)
        self._paywall = container.decode(IgnoreDecodeErrors<PaywallData?>.self, forKey: .paywall)
        self._metadata = try container.decode(
            DefaultDecodable.EmptyDictionary<[String: AnyDecodable]>.self,
            forKey: .metadata
        )
        self.webCheckoutUrl = try container.decodeIfPresent(URL.self, forKey: .webCheckoutUrl)

        let explicitHasPaywallComponents = try container.decodeIfPresent(
            Bool.self,
            forKey: .hasPaywallComponents
        )
        let decodingMode = decoder.userInfo[OfferingsResponse.decodingModeUserInfoKey]
            as? OfferingsResponse.DecodingMode ?? .withPaywallComponents
        let inferredHasPaywallComponents = decodingMode == .withoutPaywallComponents
            ? Self.hasNonNullValue(in: container, forKey: .paywallComponents)
            : nil

        switch decodingMode {
        case .withPaywallComponents:
            self.paywallComponents = try container.decodeIfPresent(
                PaywallComponentsData.self,
                forKey: .paywallComponents
            )

        case .withoutPaywallComponents:
            self.paywallComponents = nil
        }

        self.hasPaywallComponents = explicitHasPaywallComponents ?? inferredHasPaywallComponents
    }

    private static func hasNonNullValue(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Bool? {
        guard container.contains(key) else { return nil }
        return (try? container.decodeNil(forKey: key)) == false
    }

}
extension OfferingsResponse.Placements: Codable, Equatable {}
extension OfferingsResponse.Targeting: Codable, Equatable {}
extension OfferingsResponse: Codable, Equatable {}

extension OfferingsResponse: HTTPResponseBody {}
