//
//  ASN1Object+ValueReading.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 24/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

//Value Data Types we expect from ASN1
protocol ASN1ExtractableValueTypes {}

extension ASN1Object: ASN1ExtractableValueTypes { }
extension Bool: ASN1ExtractableValueTypes { }
extension Data: ASN1ExtractableValueTypes { }
extension String: ASN1ExtractableValueTypes { }
extension Date: ASN1ExtractableValueTypes { }
extension Int: ASN1ExtractableValueTypes { }

struct ASN1
{
    @inlinable
    static func readInt(from asn1obj: inout Data) -> Int
    {
        var d = try! ASN1Object.extractData(from: &asn1obj)
        return readInt(from: &d, l: d.count)
    }
    
    static func readInt(from data: inout Data, l: Int) -> Int
    {
        var r: UInt64 = 0
        
        let start = data.startIndex
        let end = start + l
        
        for i in start..<end
        {
            r = r << 8
            r |= UInt64(data[i])
        }
        
        if r >= Int.max
        {
            return -1 //Invalid data
        }
        
        return Int(r)
    }
    
    @inlinable
    static func readOid(from asn1obj: inout Data) -> String
    {
        var d = try! ASN1Object.extractData(from: &asn1obj)
        return readOid(from: &d)
    }
    
    /// https://docs.microsoft.com/en-us/windows/desktop/seccertenroll/about-object-identifier
    static func readOid(contentData: inout Data) -> String
    {
        if contentData.isEmpty { return "" }
        
        var oid: [UInt64] = [UInt64]()
        
        var shifted: UInt8 = 0x00
        var value: UInt64 = 0x00
        
        for (i, bit) in contentData.enumerated()
        {
            if i == 0
            {
                oid.append(UInt64(bit/40))
                oid.append(UInt64(bit%40))
            }else if (bit & 0x80) == 0
            {
                let v = UInt64((bit & 0x7F) | shifted)
                value |= v
                oid.append(value)
                
                shifted = 0x00
                value = 0x00
            }else
            {
                if value > 0 { value >>= 1 }
                
                let v = UInt64(((bit & 0x7F) | shifted) >> 1)
                value |= v
                value <<= 8
                
                shifted = bit << 7
            }
        }
        
        return oid.map { String($0) }.joined(separator: ".")
    }
    
    @inlinable
    static func readString(from asn1obj: inout Data, encoding: String.Encoding) -> String
    {
        var d = try! ASN1Object.extractData(from: &asn1obj)
        return readString(from: &d, d.count, encoding: encoding)
    }
    
    @inlinable
    static func readString(from data: inout Data, _ l: Int, encoding: String.Encoding) -> String
    {
        return String(data: data, encoding: encoding) ?? ""
    }
    
    @inlinable
    static func readUTF8String(from data: inout Data, _ l: Int) -> String?
    {
        return readString(from: &data, l, encoding: .utf8)
    }
    
    @inlinable
    static func readASCIIString(from data: inout Data, _ l: Int) -> String?
    {
        return readString(from: &data, l, encoding: .ascii)
    }
}

extension ASN1Object
{
    var valueData: Data?
    {
        let l = length.value
        
        if l == 0 { return nil }
        
        let valueOffset = ASN1Object.identifierLenght + length.offset //Identifier + length
        return Data(rawData[valueOffset..<(l + valueOffset)])
    }
    
    func extractValue() -> Any?
    {
        return value()
    }
    
    fileprivate func value() -> ASN1ExtractableValueTypes?
    {
        let type = identifier.type
        
        guard type != .unknown else
        {
            return nil
        }
        
        let l = length.value
        
        guard l > 0, var valueData: Data = valueData else
        {
            return nil
        }
        
        switch type
        {
        case .integer:
            return ASN1.readInt(from: &valueData, l: l)
        case .octetString:
            return valueData
        case .endOfContent: //Treat it as unknown type of some constructed type
            if identifier.isConstructed
            {
                return ASN1Object.isDataValid(&valueData) ? ASN1Object(data: valueData) : valueData
            }else{
                return nil
            }
        case .boolean:
            return true
        case .bitString:
            // remove unused first bit
            if valueData.count > 0 {
                _ = valueData.remove(at: 0)
            }
            return valueData
        case .null:
            return nil
        case .objectIdentifier:
            return ASN1.readOid(contentData: &valueData)
        case .objectDescriptor:
            return "objectIdentifier"
        case .external:
            return valueData
        case .real:
            return "real"
        case .enumerated:
            return "enumerated"
        case .embeddedPdv:
            return "embeddedPdv"
        case .utf8String,
             .printableString,
             .numericString,
             .generalString,
             .universalString,
             .characterString,
             .t61String:
            return ASN1.readString(from: &valueData, l, encoding: .utf8)
        case .relativeOid:
            return ASN1.readOid(contentData: &valueData)
        case .sequence, .set:
            return ASN1Object.isDataValid(&valueData) ? ASN1Object(data: valueData) : valueData
        case .videotexString:
            return "videotexString"
        case .ia5String:
            return ASN1.readString(from: &valueData, l, encoding: .ascii)
        case .utcTime:
            return ASN1.readString(from: &valueData, l, encoding: .ascii).utcTime()
        case .generalizedTime:
            return ASN1.readString(from: &valueData, l, encoding: .ascii).rfc3339date()
        case .graphicString:
            return "graphicString"
        case .visibleString:
            return "visibleString"
        case .bmpString:
            return "bmpString"
        default:
            return nil
        }
    }
}
