//
//  LocalReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 6/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import TPInAppReceipt

internal enum LocalReceiptParserErrorCode: Int {
    case ReceiptNotFound,
         UnknownError
}

internal class LocalReceiptParser {
    private let receiptData: Data
    
    init(receiptData: Data) {
        self.receiptData = receiptData
    }
    
    func purchasedIntroOfferProductIdentifiers() -> Set<String> {
        do {
            let receipt = try TPInAppReceipt.InAppReceipt(receiptData: receiptData)
            
            let productIdentifiers = receipt.purchases
                .filter { $0.subscriptionTrialPeriod || $0.subscriptionIntroductoryPricePeriod }
                .map{ $0.productIdentifier }
            return productIdentifiers
        } catch let error {
            print("couldn't parse the receipt, error: \(error.localizedDescription)")
        }
        
        return [:]
    }
}
