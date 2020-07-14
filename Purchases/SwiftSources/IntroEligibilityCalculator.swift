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

@available(iOS 12.0, *)
public class IntroEligibilityCalculator: NSObject {
    
    @objc public func checkTrialOrIntroductoryPriceEligibility(withData receiptData: Data,
                                                               productIdentifiers candidateProductIdentifiers: [String],
                                                               completion: @escaping ([String: Int], Error?) -> Void) {
        var result: [String: Int] = candidateProductIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibilityStatus.unknown.rawValue
        }
        
        let productsManager = ProductsManager()
        let localReceiptParser = LocalReceiptParser(receiptData: receiptData)
        
        let transactionsByProductIdentifier = localReceiptParser.purchasedIntroOfferProductIdentifiers()
        productsManager.products(withIdentifiers: Set(candidateProductIdentifiers)) { [weak self] candidateProducts in
            productsManager.products(withIdentifiers: transactionsByProductIdentifier) { [weak self] purchasedProductsWithIntroOffers in
                guard let `self` = self else { return }
                
                let eligibility: [String: Int] = self.checkIntroEligibility(candidateProducts: candidateProducts,
                                                                            purchasedProductsWithIntroOffers: purchasedProductsWithIntroOffers)
                result.merge(eligibility) { (_, new) in new }
                
                completion(result, NSError(domain: "This method hasn't been implemented yet",
                                           code: LocalReceiptParserErrorCode.UnknownError.rawValue,
                                           userInfo: nil))
            }
        }
    }
}

@available(iOS 12.0, *)
private extension IntroEligibilityCalculator {
    
    func checkIntroEligibility(candidateProducts: Set<SKProduct>,
                               purchasedProductsWithIntroOffers: Set<SKProduct>) -> [String: Int] {
        var result: [String: Int] = [:]
        for candidate in candidateProducts {
            let usedIntroForProductIdentifier = purchasedProductsWithIntroOffers
                .contains { purchased in
                    let foundByProductId = candidate.productIdentifier == purchased.productIdentifier
                    let foundByGroupId = candidate.subscriptionGroupIdentifier == purchased.subscriptionGroupIdentifier
                        && candidate.subscriptionGroupIdentifier != nil
                    return foundByProductId || foundByGroupId
                }
            result[candidate.productIdentifier] = usedIntroForProductIdentifier
                ? IntroEligibilityStatus.ineligible.rawValue
                : IntroEligibilityStatus.eligible.rawValue
        }
        return result
    }
}
