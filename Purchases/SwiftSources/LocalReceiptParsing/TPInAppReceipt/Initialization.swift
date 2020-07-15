//
//  Initialization.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 05/02/17.
//  Copyright © 2017-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

/// An InAppReceipt extension helps to initialize the receipt
extension InAppReceipt
{
    /// Creates and returns the 'InAppReceipt' instance from data object
    ///
    /// - Returns: 'InAppReceipt' instance
    /// - throws: An error in the InAppReceipt domain, if `InAppReceipt` cannot be created.
    static func receipt(from data: Data) throws -> InAppReceipt
    {
        return try InAppReceipt(receiptData: data)
    }
    
    /// Creates and returns the 'InAppReceipt' instance using local receipt
    ///
    /// - Returns: 'InAppReceipt' instance
    /// - throws: An error in the InAppReceipt domain, if `InAppReceipt` cannot be created.
    static func localReceipt() throws -> InAppReceipt
    {
        let data = try Bundle.main.appStoreReceiptData()
        return try InAppReceipt.receipt(from: data)
    }
    
}

/// A Bundle extension helps to retrieve receipt data
extension Bundle
{
    /// Retrieve local App Store Receip Data
    ///
    /// - Returns: 'Data' object that represents local receipt
    /// - throws: An error if receipt file not found or 'Data' can't be created
    func appStoreReceiptData() throws -> Data
    {
        guard let receiptUrl = appStoreReceiptURL,
            try receiptUrl.checkResourceIsReachable() else
        {
            throw IARError.initializationFailed(reason: .appStoreReceiptNotFound)
        }
        
        return try Data(contentsOf: receiptUrl)
    }
    
    /// Retrieve local App Store Receip Data in base64 string
    ///
    /// - Returns: 'Data' object that represents local receipt
    /// - throws: An error if receipt file not found or 'Data' can't be created
    func appStoreReceiptBase64() throws -> String
    {
        return try appStoreReceiptData().base64EncodedString()
    }
    
    class func lookUp(forResource name: String, ofType ext: String?) -> String?
    {
        if let p = Bundle(for: _TPInAppReceipt.self).path(forResource: name, ofType: ext)
        {
            return p
        }
        
        if let p = Bundle.main.path(forResource: name, ofType: ext)
        {
            return p
        }
        
        for f in Bundle.allFrameworks
        {
            if let identifier = f.bundleIdentifier, identifier.contains("TPInAppReceipt"),
                let p = f.path(forResource: name, ofType: ext)
            {
                return p
            }
        }
        
        return nil
    }
}

fileprivate class _TPInAppReceipt {}
