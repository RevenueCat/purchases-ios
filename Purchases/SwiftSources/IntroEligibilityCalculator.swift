//
//  IntroEligibilityCalculator.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

internal enum IntroEligibilityStatus: Int {
    case unknown,
         ineligible,
         eligible
}

public class IntroEligibilityCalculator: NSObject {

    @objc public func checkTrialOrIntroductoryPriceEligibility(withData receiptData: Data,
                                                               productIdentifiers candidateProductIdentifiers: [String],
                                                               completion: ([String: Int], Error?) -> Void) {
        if #available(iOS 12.0, *) {

            var result: [String: Int] = candidateProductIdentifiers.reduce(into: [:]) { resultDict, productId in
                resultDict[productId] = IntroEligibilityStatus.unknown.rawValue
            }

            let productsManager = ProductsManager()
            let localReceiptParser = LocalReceiptParser(receiptData: receiptData)

            let transactionsByProductIdentifier = localReceiptParser.introPricingTransactionsByProductIdentifier()
            let candidateProducts = productsManager.products(withIdentifiers: Set(candidateProductIdentifiers))
            let purchasedProductsWithIntroOffers = productsManager.products(withIdentifiers:
                                                                           transactionsByProductIdentifier.keys)

            for candidate in candidateProducts {
                let usedIntroForProductIdentifier = purchasedProductsWithIntroOffers
                    .contains { purchased in
                    let foundByProductId = candidate.productIdentifier == purchased.productIdentifier
                    let foundByGroupId = candidate.subscriptionGroupIdentifier == purchased.subscriptionGroupIdentifier
                    return foundByProductId || foundByGroupId
                }
                result[candidate.productIdentifier] = usedIntroForProductIdentifier
                                                             ? IntroEligibilityStatus.ineligible.rawValue
                                                             : IntroEligibilityStatus.eligible.rawValue
            }

            completion(result, NSError(domain: "This method hasn't been implemented yet",
                                       code: LocalReceiptParserErrorCode.UnknownError.rawValue,
                                       userInfo: nil))
        } else {
            completion([:], NSError(domain: "intro availability isn't available",
                                    code: LocalReceiptParserErrorCode.UnknownError.rawValue,
                                    userInfo: nil))
        }
    }
}
