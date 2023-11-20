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

// swiftlint:disable nesting

struct OfferingsResponse {

    struct Offering {

        struct Package {

            let identifier: String
            let platformProductIdentifier: String

        }

        let identifier: String
        let description: String
        let packages: [Package]
        @IgnoreDecodeErrors<PaywallData?>
        var paywall: PaywallData?
        @DefaultDecodable.EmptyDictionary
        var metadata: [String: AnyDecodable]

    }

    let currentOfferingId: String?
    let offerings: [Offering]

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

}

extension OfferingsResponse.Offering.Package: Codable, Equatable {}
extension OfferingsResponse.Offering: Codable, Equatable {}
extension OfferingsResponse: Codable, Equatable {}

// @unchecked becasue `metadata` contains `AnyDecodable`.
extension OfferingsResponse.Offering: @unchecked Sendable {}
extension OfferingsResponse: Sendable {}

extension OfferingsResponse: HTTPResponseBody {}
