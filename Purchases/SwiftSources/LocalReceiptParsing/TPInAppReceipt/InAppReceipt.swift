//
//  InAppReceipt.swift
//  TPReceiptValidator
//
//  Created by Pavel Tikhonenko on 28/09/16.
//  Copyright © 2016-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

enum InAppReceiptField: Int
{
	case environment = 0 // Sandbox, Production, ProductionSandbox
    case bundleIdentifier = 2
    case appVersion = 3
    case opaqueValue = 4
    case receiptHash = 5 // SHA-1 Hash
	case receiptCreationDate = 12
    case inAppPurchaseReceipt = 17 // The receipt for an in-app purchase.
	//TODO: case originalPurchaseDate = 18
    case originalAppVersion = 19
    case expirationDate = 21
    
    
    case quantity = 1701
    case productIdentifier = 1702
    case transactionIdentifier = 1703
    case purchaseDate = 1704
    case originalTransactionIdentifier = 1705
    case originalPurchaseDate = 1706
	case productType = 1707
    case subscriptionExpirationDate = 1708
    case webOrderLineItemID = 1711
    case cancellationDate = 1712
    case subscriptionTrialPeriod = 1713
    case subscriptionIntroductoryPricePeriod = 1719
	case promotionalOfferIdentifier = 1721
}

struct InAppReceipt
{
    /// Raw pkcs7 container
    internal var pkcs7Container: PKCS7Wrapper
    
    /// Payload of the receipt.
    /// Payload object contains all meta information.
    internal var payload: InAppReceiptPayload
    
    /// root certificate path, used to check signature
    /// added for testing purpose , as unit test can't read main bundle
    internal var rootCertificatePath: String?
    
    /// Initialize a `InAppReceipt` with asn1 payload
    ///
    /// - parameter receiptData: `Data` object that represents receipt
    init(receiptData: Data, rootCertPath: String? = nil) throws
    {
        let pkcs7 = try PKCS7Wrapper(receipt: receiptData)
        self.init(pkcs7: pkcs7, rootCertPath: rootCertPath)
    }
    
    /// Initialize a `InAppReceipt` with asn1 payload
    ///
    /// - parameter pkcs7: `PKCS7Wrapper` pkcs7 container of the receipt 
    init(pkcs7: PKCS7Wrapper, rootCertPath: String? = nil)
    {
        self.init(pkcs7: pkcs7, payload: InAppReceiptPayload(asn1Data: pkcs7.extractInAppPayload()!), rootCertPath: rootCertPath)
    }
    
    init(pkcs7: PKCS7Wrapper, payload: InAppReceiptPayload, rootCertPath: String?)
    {
        self.pkcs7Container = pkcs7
        self.payload = payload
        
        if(rootCertPath != nil)
		{
            self.rootCertificatePath = rootCertPath
        } else {
            self.rootCertificatePath = Bundle.lookUp(forResource: "AppleIncRootCertificate", ofType: "cer")
        }
    }
}

extension InAppReceipt
{
    /// The app’s bundle identifier
    var bundleIdentifier: String
    {
        return payload.bundleIdentifier
    }
    
    /// The app’s version number
    var appVersion: String
    {
        return payload.appVersion
    }
    
    /// The version of the app that was originally purchased.
    var originalAppVersion: String
    {
        return payload.originalAppVersion
    }
    
    /// In-app purchase's receipts
    var purchases: [InAppPurchase]
    {
        return payload.purchases
    }
    
    /// Returns all auto renewable `InAppPurchase`s,
    var autoRenewablePurchases: [InAppPurchase]
    {
        return purchases.filter({ $0.isRenewableSubscription })
    }
    
    /// Returns all ACTIVE auto renewable `InAppPurchase`s,
    ///
    var activeAutoRenewableSubscriptionPurchases: [InAppPurchase]
    {
        return purchases.filter({ $0.isRenewableSubscription && $0.isActiveAutoRenewableSubscription(forDate: Date()) })
        
    }
    
    /// The date that the app receipt expires
    var expirationDate: String?
    {
        return payload.expirationDate
    }
    
    /// Returns `true` if any purchases exist, `false` otherwise
    var hasPurchases: Bool
    {
        return purchases.count > 0
    }
    
    /// Returns `true` if any Active Auto Renewable purchases exist, `false` otherwise
    var hasActiveAutoRenewablePurchases: Bool
    {
        return activeAutoRenewableSubscriptionPurchases.count > 0
    }
    
    /// The date when the app receipt was created.
    var creationDate: String
    {
        return payload.creationDate
    }
    
    /// In App Receipt in base64
    var base64: String
    {
        return pkcs7Container.base64
    }
    
    /// Return original transaction identifier if there is a purchase for a specific product identifier
    ///
    /// - parameter productIdentifier: Product name
    func originalTransactionIdentifier(ofProductIdentifier productIdentifier: String) -> String?
    {
        return purchases(ofProductIdentifier: productIdentifier).first?.originalTransactionIdentifier
    }
    
    /// Returns `true` if there is a purchase for a specific product identifier, `false` otherwise
    ///
    /// - parameter productIdentifier: Product name
    func containsPurchase(ofProductIdentifier productIdentifier: String) -> Bool
    {
        for item in purchases
        {
            if item.productIdentifier == productIdentifier
            {
                return true
            }
        }
        
        return false
    }
    
    /// Returns `[InAppPurchase]` if there are purchases for a specific product identifier,
    /// empty array otherwise
    ///
    /// - parameter productIdentifier: Product name
    /// - parameter sort: Sorting block
    func purchases(ofProductIdentifier productIdentifier: String,
                          sortedBy sort: ((InAppPurchase, InAppPurchase) -> Bool)? = nil) -> [InAppPurchase]
    {
        let filtered: [InAppPurchase] = purchases.filter({
            return $0.productIdentifier == productIdentifier
        })
        
        if let sort = sort
        {
            return filtered.sorted(by: {
                return sort($0, $1)
            })
        }else{
            return filtered.sorted(by: {
                return $0.purchaseDate > $1.purchaseDate
            })
        }
        
        
    }
    
    /// Returns `InAppPurchase` if there is a purchase for a specific product identifier,
    /// `nil` otherwise
    ///
    /// - parameter productIdentifier: Product name
    func activeAutoRenewableSubscriptionPurchases(ofProductIdentifier productIdentifier: String, forDate date: Date) -> InAppPurchase?
    {
        let filtered = purchases(ofProductIdentifier: productIdentifier)
        
        for purchase in filtered
        {
            if purchase.isActiveAutoRenewableSubscription(forDate: date)
            {
                return purchase
            }
        }

        return nil

    }

    /// Returns the last `InAppPurchase` if there is one for a specific product identifier,
    /// `nil` otherwise
    ///
    /// - parameter productIdentifier: Product name
    func lastAutoRenewableSubscriptionPurchase(ofProductIdentifier productIdentifier: String) -> InAppPurchase?
    {
        
        var purchase: InAppPurchase? = nil
        let filtered = purchases(ofProductIdentifier: productIdentifier)
        
        var lastInterval: TimeInterval = 0
        for iap in filtered
		{
            if !(iap.productIdentifier == productIdentifier) {
                continue
            }
            
            if let thisInterval = iap.subscriptionExpirationDate?.timeIntervalSince1970 {
                if purchase == nil || thisInterval > lastInterval {
                    purchase = iap
                    lastInterval = thisInterval
                }
            }
        }
        return purchase
    }
    
    /// Returns true if there is an active subscription for a specific product identifier on the date specified,
    /// false otherwise
    ///
    /// - parameter productIdentifier: Product name
    /// - parameter date: Date to check subscription against
    func hasActiveAutoRenewableSubscription(ofProductIdentifier productIdentifier: String, forDate date: Date) -> Bool
    {
        return activeAutoRenewableSubscriptionPurchases(ofProductIdentifier: productIdentifier, forDate: date) != nil
    }
}

internal extension InAppReceipt
{
    /// Used to validate the receipt
    var bundleIdentifierData: Data
    {
        return payload.bundleIdentifierData
    }
    
    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    var opaqueValue: Data
    {
        return payload.opaqueValue
    }
    
    /// A SHA-1 hash, used to validate the receipt.
    var receiptHash: Data
    {
        return payload.receiptHash
    }
    
    /// signature for validation
    var signature: Data?
    {
        return pkcs7Container.extractSignature()
    }
}
