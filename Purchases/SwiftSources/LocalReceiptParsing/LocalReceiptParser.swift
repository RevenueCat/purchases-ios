//
//  LocalReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 6/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

internal enum LocalReceiptParserErrorCode: Int {
    case ReceiptNotFound,
         UnknownError
}

internal class LocalReceiptParser {
    
    func purchasedIntroOfferProductIdentifiers(receiptData: Data) -> Set<String> {
        do {
            let receipt = try InAppReceipt(receiptData: receiptData)
            
            let productIdentifiers = receipt.purchases
                .filter { $0.subscriptionTrialPeriod || $0.subscriptionIntroductoryPricePeriod }
                .map { $0.productIdentifier }
            return Set(productIdentifiers)
        } catch let error {
            print("couldn't parse the receipt, error: \(error.localizedDescription)")
        }
        
        return Set()
    }
}
