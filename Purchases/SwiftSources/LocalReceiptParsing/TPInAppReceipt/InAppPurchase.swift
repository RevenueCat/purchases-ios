//
//  InAppPurchase.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 19/01/17.
//  Copyright © 2017-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

struct InAppPurchase
{
    enum `Type`: Int
    {
        /// Type that we can't recognize for some reason
        case unknown = -1
        
        /// Type that customers purchase once. They don't expire.
        case nonConsumable
        
        /// Type that are depleted after one use. Customers can purchase them multiple times.
        case consumable
        
        /// Type that customers purchase once and that renew automatically on a recurring basis until customers decide to cancel.
        case nonRenewingSubscription
        
        /// Type that customers purchase and it provides access over a limited duration and don't renew automatically. Customers can purchase them again.
        case autoRenewableSubscription
    }
    
    /// The product identifier which purchase related to
    var productIdentifier: String
    
    /// Product type
    var productType: Type = .unknown
    
    /// Transaction identifier
    var transactionIdentifier: String
    
    /// Original Transaction identifier
    var originalTransactionIdentifier: String
    
    /// Purchase Date in string format
    var purchaseDateString: String
    
    /// Original Purchase Date in string format
    var originalPurchaseDateString: String
    
    /// Subscription Expiration Date in string format. Returns `nil` if the purchase is not a renewable subscription
    var subscriptionExpirationDateString: String? = nil
    
    /// Cancellation Date in string format. Returns `nil` if the purchase is not a renewable subscription
    var cancellationDateString: String? = nil
    
    /// This value is `true`if the customer’s subscription is currently in the free trial period, or `false` if not.
    var subscriptionTrialPeriod: Bool = false
    
    /// This value is `true` if the customer’s subscription is currently in an introductory price period, or `false` if not.
    var subscriptionIntroductoryPricePeriod: Bool = false
    
    /// A unique identifier for purchase events across devices, including subscription-renewal events. This value is the primary key for identifying subscription purchases.
    var webOrderLineItemID: Int? = nil
    
    /// The value is an identifier of the subscription offer that the user redeemed.
    /// Returns `nil` if  the user didn't use any subscription offers.
    var promotionalOfferIdentifier: String? = nil
    
    /// The number of consumable products purchased
    /// The default value is `1` unless modified with a mutable payment. The maximum value is 10.
    var quantity: Int = 1
    
    init()
    {
        originalTransactionIdentifier = ""
        productIdentifier = ""
        transactionIdentifier = ""
        purchaseDateString = ""
        originalPurchaseDateString = ""
    }
    
    init(asn1Data: Data)
    {
        self.init(asn1Obj: ASN1Object(data: asn1Data))
    }
    
    init(asn1Obj: ASN1Object)
    {
        self.init()
        
        asn1Obj.enumerateInAppReceiptAttributes { (attribute) in
            if let field = InAppReceiptField(rawValue: attribute.type), var value = attribute.value.extractValue() as? Data
            {
                switch field
                {
                case .quantity:
                    quantity = ASN1.readInt(from: &value)
                case .productIdentifier:
                    productIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .productType:
                    productType = Type(rawValue: ASN1.readInt(from: &value)) ?? .unknown
                case .transactionIdentifier:
                    transactionIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .purchaseDate:
                    purchaseDateString = ASN1.readString(from: &value, encoding: .ascii)
                case .originalTransactionIdentifier:
                    originalTransactionIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                case .originalPurchaseDate:
                    originalPurchaseDateString = ASN1.readString(from: &value, encoding: .ascii)
                case .subscriptionExpirationDate:
                    let str = ASN1.readString(from: &value, encoding: .ascii)
                    subscriptionExpirationDateString = str == "" ? nil : str
                case .cancellationDate:
                    let str = ASN1.readString(from: &value, encoding: .ascii)
                    cancellationDateString = str == "" ? nil : str
                case .webOrderLineItemID:
                    webOrderLineItemID = ASN1.readInt(from: &value)
                case .subscriptionTrialPeriod:
                    subscriptionTrialPeriod = ASN1.readInt(from: &value) != 0
                case .subscriptionIntroductoryPricePeriod:
                    subscriptionIntroductoryPricePeriod = ASN1.readInt(from: &value) != 0
                case .promotionalOfferIdentifier:
                    promotionalOfferIdentifier = ASN1.readString(from: &value, encoding: .utf8)
                default:
                    break
                }
            }
        }
    }
}

extension InAppPurchase
{
    /// Purchase Date representation as a 'Date' object
    var purchaseDate: Date
    {
        return purchaseDateString.rfc3339date()!
    }
    
    /// Subscription Expiration Date representation as a 'Date' object. Returns `nil` if the purchase has been expired (in some cases)
    var subscriptionExpirationDate: Date?
    {
        assert(isRenewableSubscription, "\(productIdentifier) is not an auto-renewable subscription.")
        
        return subscriptionExpirationDateString?.rfc3339date()
    }
    
    /// A Boolean value indicating whether the purchase is renewable subscription.
    var isRenewableSubscription: Bool
    {
        return self.subscriptionExpirationDateString != nil
    }
    
    /// Check whether the subscription is active for a specific date
    ///
    /// - Parameter date: The date in which the auto-renewable subscription should be active.
    /// - Returns: true if the latest auto-renewable subscription is active for the given date, false otherwise.
    func isActiveAutoRenewableSubscription(forDate date: Date) -> Bool
    {
        assert(isRenewableSubscription, "\(productIdentifier) is not an auto-renewable subscription.")
        
        if(self.cancellationDateString != nil && self.cancellationDateString != "")
        {
            return false
        }
        
        guard let expirationDate = subscriptionExpirationDate else
        {
            return false
        }
        
        return date >= purchaseDate && date < expirationDate
    }
}
