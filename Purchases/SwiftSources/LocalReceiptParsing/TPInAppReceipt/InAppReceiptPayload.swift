//
//  InAppReceiptPayload.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 20/01/17.
//  Copyright © 2017-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

struct InAppReceiptPayload
{
    /// In-app purchase's receipts
    let purchases: [InAppPurchase]
    
    /// The app’s bundle identifier
    let bundleIdentifier: String
    
    /// The app’s version number
    let appVersion: String
    
    /// The version of the app that was originally purchased.
    let originalAppVersion: String
    
    /// The date that the app receipt expires
    let expirationDate: String?
    
    /// Used to validate the receipt
    let bundleIdentifierData: Data
    
    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    let opaqueValue: Data
    
    /// A SHA-1 hash, used to validate the receipt.
    let receiptHash: Data
    
    /// The date when the app receipt was created.
    let creationDate: String
    
	/// Receipt's environment
	let environment: String
	
    /// Initialize a `InAppReceipt` passing all values
    ///
	init(bundleIdentifier: String, appVersion: String, originalAppVersion: String, purchases: [InAppPurchase], expirationDate: String?, bundleIdentifierData: Data, opaqueValue: Data, receiptHash: Data, creationDate: String, environment: String)
    {
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.originalAppVersion = originalAppVersion
        self.purchases = purchases
        self.expirationDate = expirationDate
        self.bundleIdentifierData = bundleIdentifierData
        self.opaqueValue = opaqueValue
        self.receiptHash = receiptHash
        self.creationDate = creationDate
		self.environment = environment
    }
}


extension InAppReceiptPayload
{
    /// Initialize a `InAppReceipt` with asn1 payload
    ///
    /// - parameter asn1Data: `Data` object that represents receipt's payload
    init(asn1Data: Data)
    {
        var bundleIdentifier = ""
        var appVersion = ""
        var originalAppVersion = ""
        var purchases = [InAppPurchase]()
        var bundleIdentifierData = Data()
        var opaqueValue = Data()
        var receiptHash = Data()
        var expirationDate: String? = ""
        var receiptCreationDate: String = ""
		var environment: String = ""
		
        let payload = ASN1Object(data: asn1Data)
        payload.enumerateInAppReceiptAttributes { (attribute) in
            if let field = InAppReceiptField(rawValue: attribute.type), var value = attribute.value.extractValue() as? Data
            {
                switch (field)
                {
                case .bundleIdentifier:
                    let obj = ASN1Object(data: value)
                    bundleIdentifier = obj.extractValue() as! String
                    bundleIdentifierData = value
                case .appVersion:
                    appVersion = ASN1.readString(from: &value, encoding: .utf8)
                case .opaqueValue:
                    opaqueValue = value
                case .receiptHash:
                    receiptHash = value
                case .inAppPurchaseReceipt:
                    purchases.append(InAppPurchase(asn1Data: value))
                    break
                case .originalAppVersion:
                    originalAppVersion = ASN1.readString(from: &value, encoding: .utf8)
                case .expirationDate:
                    expirationDate = ASN1.readString(from: &value, encoding: .ascii)
                case .receiptCreationDate:
                    receiptCreationDate = ASN1.readString(from: &value, encoding: .ascii)
				case .environment:
					environment = ASN1.readString(from: &value, encoding: .utf8)
                default:
                    print("attribute.type = \(String(describing: attribute.type)))")
                }
            }            
        }
        
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.originalAppVersion = originalAppVersion
        self.purchases = purchases
        self.expirationDate = expirationDate
        self.bundleIdentifierData = bundleIdentifierData
        self.opaqueValue = opaqueValue
        self.receiptHash = receiptHash
        self.creationDate = receiptCreationDate
		self.environment = environment
    }
}
