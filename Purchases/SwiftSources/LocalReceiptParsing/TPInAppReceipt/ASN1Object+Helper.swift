//
//  ASN1Object+Helper.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 24/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

///
/// Utils methods
extension ASN1Object
{
    static let identifierLenght: Int = 1
    
    static func isDataValid(checkingLength: Bool = true, _ data: inout Data) -> Bool
    {
        let c = data.count
        
        if c == 0 { return false }
        
        guard let _ = try? extractIdentifier(from: &data),
            let length = try? ASN1Object.extractLenght(from: &data) else
        {
            return false
        }
        
        if checkingLength
        {
            return (identifierLenght + length.offset + length.value) == c
        }
        
        return true
    }

    static func extractIdentifier(from asn1data: inout Data) throws -> Identifier
    {
        guard asn1data.count > 0 else
        {
            throw ASN1Error.initializationFailed(reason: .dataIsInvalid)
        }
        
        let raw = asn1data[asn1data.startIndex]
        let tagNumber = raw & 0b11111
        
        guard let c = Identifier.Class(rawValue: (raw >> 6) & 0b11),
            let e = Identifier.EncodingType(rawValue: (raw >> 5) & 0b1) else
        {
            throw ASN1Error.initializationFailed(reason: .dataIsInvalid)
        }
        
        return Identifier(raw: raw, tagNumber: tagNumber, class: c, encodingType: e)
    }
    
    static func extractLenght(from asn1data: inout Data) throws -> Length
    {
        if asn1data.count < 2 { throw ASN1Error.initializationFailed(reason: .dataIsInvalid) } //invalid data
        
        let startIdx = asn1data.startIndex
        
        let lByte = asn1data[startIdx + identifierLenght] // Skip identifier
        
        if ((lByte & 0x80) != 0)
        {
            let l: Int = Int(lByte - 0x80)
            let offset = identifierLenght + 1 // Skip identifier and lenght header
            
            if (offset + l) > asn1data.endIndex
            {
                throw ASN1Error.initializationFailed(reason: .dataIsInvalid)
            }
            
            let start = startIdx + offset
        
            let end = start + l
            
            var d = asn1data[start..<end]
            
            let r = ASN1.readInt(from: &d, l: l)
            return Length.long(length: l, value: r)
        }else{
            return Length.short(value: Int(lByte))
        }
    }
    
    @inlinable
    static func extractData(from asn1data: inout Data) throws -> Data
    {
        let l = try extractLenght(from: &asn1data)
        
        let startIdx = asn1data.startIndex + identifierLenght + l.offset // Skip identifier and lenght
        let endIdx = startIdx + l.value
        let bytes = asn1data[startIdx..<endIdx]
        return bytes
    }
}
