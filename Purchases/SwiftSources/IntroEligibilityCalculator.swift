//
//  IntroEligibilityCalculator.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@available(iOS 12.0, *)
public class IntroEligibilityCalculator: NSObject {
    private let productsManager: ProductsManager
    private let localReceiptParser: LocalReceiptParser
    
    public override init() {
        self.productsManager = ProductsManager()
        self.localReceiptParser = LocalReceiptParser()
    }
    
    internal init(productsManager: ProductsManager,
                  localReceiptParser: LocalReceiptParser) {
        self.productsManager = productsManager
        self.localReceiptParser = localReceiptParser
    }
    
    @objc public func checkTrialOrIntroductoryPriceEligibility(withData receiptData: Data,
                                                               productIdentifiers candidateProductIdentifiers: [String],
                                                               completion: @escaping ([String: Int], Error?) -> Void) {
        var result: [String: Int] = candidateProductIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibilityStatus.unknown.rawValue
        }
                
        let transactionsByProductIdentifier = localReceiptParser.purchasedIntroOfferProductIdentifiers(receiptData: receiptData)
        productsManager.products(withIdentifiers: Set(candidateProductIdentifiers)) { [self] candidateProducts in
            self.productsManager.products(withIdentifiers: transactionsByProductIdentifier) { [self] purchasedProductsWithIntroOffers in
                
                let eligibility: [String: Int] = self.checkIntroEligibility(candidateProducts: candidateProducts,
                                                                            purchasedProductsWithIntroOffers: purchasedProductsWithIntroOffers)
                result.merge(eligibility) { (_, new) in new }
                
                completion(result, nil)
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

internal enum IntroEligibilityStatus: Int {
    case unknown,
         ineligible,
         eligible
}
