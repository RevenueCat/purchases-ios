//
//  PCKS7.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 22/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

struct PKC7
{
    enum OID: String
    {
        case data = "1.2.840.113549.1.7.1"
        case signedData = "1.2.840.113549.1.7.2"
        case envelopedData = "1.2.840.113549.1.7.3"
        case signedAndEnvelopedData = "1.2.840.113549.1.7.4"
        case digestedData = "1.2.840.113549.1.7.5"
        case encryptedData = "1.2.840.113549.1.7.6"
    }
}

class PKCS7Wrapper
{
    var rawBuffer: UnsafeMutableBufferPointer<UInt8>
    
    init(receipt: Data) throws
    {
        rawBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: receipt.count)
        let _ = rawBuffer.initialize(from: receipt)
    }
    
    deinit
    {
        rawBuffer.deallocate()
    }
}

extension PKCS7Wrapper
{
    /// Find content by pkcs7 oid
    ///
    /// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
    func extractContent(by oid: PKC7.OID) -> Data?
    {
        var raw = Data(bytesNoCopy: rawBuffer.baseAddress!, count: rawBuffer.count, deallocator: .none)
        return extractContent(by: oid, from: &raw)
    }
    
    /// Extract content by pkcs7 oid
    ///
    /// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
    func extractContent(by oid: PKC7.OID, from data: inout Data) -> Data?
    {
        if !ASN1Object.isDataValid(checkingLength: false, &data) { return nil }
        
        do
        {
            let r = checkContentExistance(by: oid, in: &data)
            
            guard r.0, let offset = r.offset else
            {
                return nil
            }
            
            var contentData = data[offset..<data.endIndex]
            let _ = try ASN1Object.extractIdentifier(from: &contentData)
            let contentDataLength = try ASN1Object.extractLenght(from: &contentData)
            let contentEnd = offset + ASN1Object.identifierLenght + contentDataLength.offset + contentDataLength.value
            return data[offset..<contentEnd]
        }catch{
            return nil
        }
    }
    
    /// Check if any data available for provided pkcs7 oid
    ///
    ///
    func checkContentExistance(by oid: PKC7.OID) -> Bool
    {
        var raw = Data(bytesNoCopy: rawBuffer.baseAddress!, count: rawBuffer.count, deallocator: .none)
        
        let r = checkContentExistance(by: oid, in: &raw)
        guard r.0, let _ = r.offset else
        {
            return false
        }
        
        return true
    }
    
    /// Extract content by pkcs7 oid
    ///
    /// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
    func checkContentExistance(by oid: PKC7.OID, in data: inout Data) -> (Bool, offset: Int?)
    {
        if !ASN1Object.isDataValid(checkingLength: false, &data) { return (false, nil) }
        
        do
        {
            let id = try ASN1Object.extractIdentifier(from: &data)
            let l = try ASN1Object.extractLenght(from: &data)
            
            var cStart = data.startIndex + ASN1Object.identifierLenght + l.offset
            let cEnd = data.endIndex
            
            if id.encodingType == .constructed
            {
                return checkContentExistance(by: oid, in: &data[cStart..<cEnd])
            }
            
            var foundedOid: String?
            
            if id.type == .objectIdentifier
            {
                let end = cStart + l.value
                var slice = data[cStart..<end]
                foundedOid = ASN1.readOid(contentData: &slice)
            }
            
            cStart += l.value
            
            guard let fOid = foundedOid, fOid == oid.rawValue else
            {
                return checkContentExistance(by: oid, in: &data[cStart..<cEnd])
            }
            
            var contentData = data[cStart..<cEnd]
            let _ = try ASN1Object.extractIdentifier(from: &contentData)
            let _ = try ASN1Object.extractLenght(from: &contentData)
            return (true, cStart)
        }catch{
            return (false, nil)
        }
    }
}

extension PKCS7Wrapper
{
    var base64: String
    {
        let raw = Data(bytesNoCopy: rawBuffer.baseAddress!, count: rawBuffer.count, deallocator: .none)
        return raw.base64EncodedString()
    }
}
