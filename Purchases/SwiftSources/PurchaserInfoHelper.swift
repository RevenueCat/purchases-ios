//
//  PurchaserInfoHelper.swift
//  Purchases
//
//  Created by César de la Vega  on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfoHelper: NSObject {

    @objc public class func nonConsumableTransactionsList(withNonSubscriptionsTransactionsDictionary data: Dictionary<String, Array<Transaction>>) -> Array<Transaction> {
        data.flatMap { $0.value }.sorted { (t1: Transaction, t2: Transaction) -> Bool in
            t1.purchaseDate < t2.purchaseDate
        }
    }

    @objc public class func nonConsumableTransactionsList(withNonSubscriptionsDictionary data: Dictionary<String, Array<Dictionary<String, Any>>>, dateFormatter: DateFormatter) -> Array<Transaction> {
        data.flatMap { (key: String, value: Array<Dictionary<String, Any>>) -> Array<Transaction> in
            value.compactMap { (dictionary: Dictionary<String, Any>) -> Transaction? in
                if let dateString = dictionary["purchase_date"] as? String {
                    if let date = parseDate(dateFormatter: dateFormatter, string: dateString) {
                        return Transaction(transactionId: dictionary["id"] as! String, productId: key, purchaseDate: date)
                    }
                }
                return nil
            }
        }.sorted { (t1: Transaction, t2: Transaction) -> Bool in
            t1.purchaseDate < t2.purchaseDate
        }
    }

    @objc public class func nonConsumableTransactionsMap(withNonSubscriptionsDictionary data: Dictionary<String, Array<Dictionary<String, Any>>>, dateFormatter: DateFormatter) -> Dictionary<String, Array<Transaction>> {
        let tupleArray = data.map { key, array in
            (key, array.compactMap { (dictionary: Dictionary<String, Any>) -> Transaction? in
                if let dateString = dictionary["purchase_date"] as? String {
                    if let date = parseDate(dateFormatter: dateFormatter, string: dateString) {
                        return Transaction(transactionId: dictionary["id"] as! String, productId: key, purchaseDate: date)
                    }
                }
                return nil
            })
        }
        return Dictionary(uniqueKeysWithValues: tupleArray)
    }

    private class func parseDate(dateFormatter: DateFormatter, string: String) -> Date? {
        dateFormatter.date(from: string)
    }

}
