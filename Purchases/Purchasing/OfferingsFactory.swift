//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsFactory.swift
//
//  Created by César de la Vega on 7/13/21.
//

import Foundation
import StoreKit

class OfferingsFactory {

    func createOfferings(fromProductDetailsByID productDetailsByID: [String: ProductDetails],
                         data: [String: Any]) -> Offerings? {
        guard let offeringsData = data["offerings"] as? [[String: Any]] else {
            return nil
        }

        let offerings = offeringsData.reduce([String: Offering]()) { (dict, offeringData) -> [String: Offering] in
            var dict = dict
            if let offering = createOffering(fromProductDetailsByID: productDetailsByID,
                                             offeringData: offeringData) {
                dict[offering.identifier] = offering
            }
            return dict
        }
        let currentOfferingID = data["current_offering_id"] as? String

        return Offerings(offerings: offerings, currentOfferingID: currentOfferingID)
    }

    func createOffering(fromProductDetailsByID productDetailsByID: [String: ProductDetails],
                        offeringData: [String: Any]) -> Offering? {
        guard let offeringIdentifier = offeringData["identifier"] as? String,
              let packagesData = offeringData["packages"] as? [[String: Any]],
              let serverDescription = offeringData["description"] as? String else {
            return nil
        }

        let availablePackages = packagesData.compactMap { packageData -> Package? in
            createPackage(withData: packageData,
                          productDetailsByID: productDetailsByID,
                          offeringIdentifier: offeringIdentifier)
        }
        guard !availablePackages.isEmpty else {
            return nil
        }

        return Offering(identifier: offeringIdentifier, serverDescription: serverDescription,
                availablePackages: availablePackages)
    }

    func createPackage(withData data: [String: Any],
                       productDetailsByID: [String: ProductDetails],
                       offeringIdentifier: String) -> Package? {
        guard let platformProductIdentifier = data["platform_product_identifier"] as? String,
              let product = productDetailsByID[platformProductIdentifier],
              let identifier = data["identifier"] as? String else {
            return nil
        }

        let packageType = Package.packageType(from: identifier)
        return Package(identifier: identifier,
                       packageType: packageType,
                       productDetails: product,
                       offeringIdentifier: offeringIdentifier)
    }

}
