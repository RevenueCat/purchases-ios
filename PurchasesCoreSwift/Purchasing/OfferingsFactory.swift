//
//  OfferingsFactory.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 7/13/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

// TODO (Post-migration): Remove @objc and make it internal again.
@objc(RCOfferingsFactory) public class OfferingsFactory: NSObject {

    @objc public func createOfferings(withProducts products: [String: SKProduct],
                                      data: [String: Any]) -> Offerings? {
        guard let offeringsData = data["offerings"] as? [[String: Any]] else {
            return nil
        }

        let offerings = offeringsData.reduce([String: Offering]()) { (dict, offeringData) -> [String: Offering] in
            var dict = dict
            if let offering = createOffering(withProducts: products, offeringData: offeringData) {
                dict[offering.identifier] = offering
            }
            return dict
        }
        let currentOfferingID = data["current_offering_id"] as? String

        return Offerings(offerings: offerings, currentOfferingID: currentOfferingID)
    }

    @objc public func createOffering(withProducts products: [String: SKProduct],
                                     offeringData: [String: Any]) -> Offering? {
        guard let offeringIdentifier = offeringData["identifier"] as? String,
              let packagesData = offeringData["packages"] as? [[String: Any]],
              let serverDescription = offeringData["description"] as? String else {
            return nil
        }

        let availablePackages = packagesData.compactMap { packageData -> Package? in
            createPackage(withData: packageData, products: products, offeringIdentifier: offeringIdentifier)
        }
        if availablePackages.count != 0 {
            return Offering(identifier: offeringIdentifier, serverDescription: serverDescription,
                            availablePackages: availablePackages)
        }
        return nil
    }

    @objc public func createPackage(withData data: [String: Any],
                                    products: [String: SKProduct],
                                    offeringIdentifier: String) -> Package? {
        guard let platformProductIdentifier = data["platform_product_identifier"] as? String,
              let product = products[platformProductIdentifier],
              let identifier = data["identifier"] as? String else {
            return nil
        }

        let packageType = Package.packageType(from: identifier)
        return Package(identifier: identifier,
                       packageType: packageType,
                       product: product,
                       offeringIdentifier: offeringIdentifier)
    }

}
