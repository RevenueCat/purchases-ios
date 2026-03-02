//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Offerings.swift
//
//  Created by Joshua Liebowitz on 7/12/21.
//

import Foundation

/**
 * This class contains all the offerings configured in RevenueCat dashboard.
 * Offerings let you control which products are shown to users without requiring an app update.
 *
 * Building paywalls that are dynamic and can react to different product
 * configurations gives you maximum flexibility to make remote updates.
 *
 * #### Related Articles
 * -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
 * - ``Offering``
 * - ``Package``
 */
@objc(RCOfferings) public final class Offerings: NSObject {

    internal struct Placements {
        let fallbackOfferingId: String?
        let offeringIdsByPlacement: [String: String?]
    }

    internal struct Targeting {
        let revision: Int
        let ruleId: String
    }

    /**
     Dictionary of all Offerings (``Offering``) objects keyed by their identifier. This dictionary can also be accessed
     by using an index subscript on ``Offerings``, e.g. `offerings["offering_id"]`. To access the current offering use
     ``Offerings/current``.
     */
    @objc public let all: [String: Offering]

    /**
     Current ``Offering`` configured in the RevenueCat dashboard.
     */
    @objc public var current: Offering? {
        guard let currentOfferingID = currentOfferingID else {
            return nil
        }
        return all[currentOfferingID]?.copyWith(targeting: self.targeting)
    }

    internal var response: OfferingsResponse {
        return self.contents.response
    }
    internal let contents: Offerings.Contents

    /// Indicates whether this ``Offerings`` object was loaded from the disk cache.
    ///
    /// `false` when loaded from memory cache or fetched from the network.
    internal let loadedFromDiskCache: Bool

    private let currentOfferingID: String?
    private let placements: Placements?
    private let targeting: Targeting?

    init(
        offerings: [String: Offering],
        currentOfferingID: String?,
        placements: Placements?,
        targeting: Targeting?,
        contents: Offerings.Contents,
        loadedFromDiskCache: Bool
    ) {
        self.all = offerings
        self.currentOfferingID = currentOfferingID
        self.placements = placements
        self.targeting = targeting
        self.contents = contents
        self.loadedFromDiskCache = loadedFromDiskCache
    }

}

extension Offerings.Placements: Sendable {}
extension Offerings.Targeting: Sendable {}
extension Offerings: Sendable {}

public extension Offerings {

    /**
     Retrieves a specific offering by its identifier, use this to access additional offerings configured in the
     RevenueCat dashboard, e.g. `offerings.offering(identifier: "offering_id")` or `offerings[@"offering_id"]`.
     To access the current offering use ``Offerings/current``.
     */
    @objc func offering(identifier: String?) -> Offering? {
        guard let identifier = identifier else {
            return nil
        }

        return all[identifier]
    }

    /// #### Related Symbols
    /// - ``offering(identifier:)``
    @objc subscript(key: String) -> Offering? {
        return offering(identifier: key)
    }

    @objc override var description: String {
        var description = "<Offerings {\n"
        for offering in all.values {
            description += "\t\(offering)\n"
        }
        description += "\tcurrentOffering=\(current?.description ?? "<none>")>"
        return description
    }

    /**
     Retrieves a current offering for a placement identifier, use this to access offerings defined by targeting
     placements configured in the RevenueCat dashboard, 
     e.g. `offerings.currentOffering(forPlacement: "placement_id")`.
     */
    @objc(currentOfferingForPlacement:)
    func currentOffering(forPlacement placementIdentifier: String) -> Offering? {
        guard let placements = self.placements else {
            return nil
        }

        let returnOffering: Offering?
        if let explicitOfferingId: String? = placements.offeringIdsByPlacement[placementIdentifier] {
            // Don't use fallback since placement id was explicity set in the dictionary
            returnOffering = explicitOfferingId.flatMap { self.all[$0] }
        } else {
            // Use fallback since the placement didn't exist
            returnOffering =  placements.fallbackOfferingId.flatMap { self.all[$0]}
        }

        return returnOffering?.copyWith(placementIdentifier: placementIdentifier,
                                        targeting: self.targeting)
    }
}

private extension Offering {
    func copyWith(
        placementIdentifier: String? = nil,
        targeting: Offerings.Targeting? = nil
    ) -> Offering {
        if placementIdentifier == nil && targeting == nil {
            return self
        }

        let updatedPackages = self.availablePackages.map { pkg in
            let oldContext = pkg.presentedOfferingContext

            let newContext = PresentedOfferingContext(
                offeringIdentifier: pkg.presentedOfferingContext.offeringIdentifier,
                placementIdentifier: placementIdentifier ?? oldContext.placementIdentifier,
                targetingContext: targeting.flatMap { .init(revision: $0.revision,
                                                            ruleId: $0.ruleId) } ?? oldContext.targetingContext
            )

            return Package(identifier: pkg.identifier,
                           packageType: pkg.packageType,
                           storeProduct: pkg.storeProduct,
                           presentedOfferingContext: newContext,
                           webCheckoutUrl: pkg.webCheckoutUrl
            )
        }

        return Offering(identifier: self.identifier,
                        serverDescription: self.serverDescription,
                        metadata: self.metadata,
                        paywall: self.paywall,
                        paywallComponents: self.paywallComponents,
                        availablePackages: updatedPackages,
                        webCheckoutUrl: self.webCheckoutUrl
        )
    }
}

extension Offerings {

    /// Internal enum representing the original source of the ``OfferingsResponse`` object.
    enum OriginalSource: String, Codable {
        /// Main server
        case main

        /// Load shedder server
        case loadShedder = "load_shedder"

        /// Fallback URL server
        case fallbackUrl = "fallback_url"

        init(httpResponseOriginalSource: HTTPResponseOriginalSource) {
            switch httpResponseOriginalSource {
            case .mainServer:
                self = .main
            case .loadShedder:
                self = .loadShedder
            case .fallbackUrl:
                self = .fallbackUrl
            }
        }
    }

}

extension Offerings {

    /// The actual contents of a ``Offerings``: the offerings response and other SDK-generated metadata.
    struct Contents {
        var response: OfferingsResponse
        var originalSource: Offerings.OriginalSource

        init(response: OfferingsResponse, httpResponseOriginalSource: HTTPResponseOriginalSource) {
            self.response = response
            self.originalSource = Offerings.OriginalSource(httpResponseOriginalSource: httpResponseOriginalSource)
        }
    }
}

/// `Codable` implementation that puts the content of`response` and `originalSource`
/// at the same level instead of nested.
extension Offerings.Contents: Codable {

    private enum CodingKeys: String, CodingKey {

        case response
        case originalSource

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try self.response.encode(to: encoder)
        try container.encode(self.originalSource, forKey: .originalSource)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.response = try OfferingsResponse(from: decoder)
        self.originalSource = try container.decodeIfPresent(Offerings.OriginalSource.self,
                                                            forKey: .originalSource) ?? .main
    }

}
