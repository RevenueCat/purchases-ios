//
//  ASN1Object.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 24/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

extension ASN1Object
{
    var totalLength: Int { return bytesCount }
    var valueLength: Int { return length.value }
    
    var type: ASN1Object.Identifier.`Type`
    {
        return identifier.type
    }
}

struct ASN1Object
{
    let identifier: Identifier
    var length: Length
    
    var rawData: Data
    var bytesCount: Int
    
    enum Length
    {
        case short(value: Int)
        case long(length: Int, value: Int)
    }
    
    struct Identifier
    {
        enum Class: UInt8
        {
            case universal = 0
            case application = 1
            case contextSpecific = 2
            case `private` = 3
        }
        
        enum `Type`: UInt8
        {
            case endOfContent = 0x00
            case boolean = 1
            case integer = 2
            case bitString = 3
            case octetString = 4
            case null = 5
            case objectIdentifier = 6
            case objectDescriptor = 7
            case external = 8
            case real = 9
            case enumerated = 10
            case embeddedPdv = 11
            case utf8String = 12
            case relativeOid = 13
            case sequence = 16
            case set = 17
            case numericString = 18
            case printableString = 19
            case t61String = 20
            case videotexString = 21
            case ia5String = 22
            case utcTime = 23
            case generalizedTime = 24
            case graphicString = 25
            case visibleString = 26
            case generalString = 27
            case universalString = 28
            case characterString = 29
            case bmpString = 30
            case unknown = 126
        }
        
        enum EncodingType: UInt8
        {
            case primitive = 0
            case constructed = 1
        }
        
        let `class`: Class
        let encodingType: EncodingType
        var tagNumber: UInt8
        
        var type: `Type` { return Type(rawValue: tagNumber) ?? .unknown }
        
        let raw: UInt8
        
        init(raw: UInt8) throws
        {
            self.raw = raw
            self.tagNumber = raw & 0b11111
            
            guard let c = Class(rawValue: (raw >> 6) & 0b11),
                let e = EncodingType(rawValue: (raw >> 5) & 0b1) else
            {
                throw ASN1Error.initializationFailed(reason: .dataIsInvalid)
            }
            
            self.class = c
            self.encodingType = e
        }
        
        init(raw: UInt8, tagNumber: UInt8, class: Class, encodingType: EncodingType)
        {
            self.raw = raw
            self.tagNumber = tagNumber
            self.class = `class`
            self.encodingType = encodingType
        }
    }
}

extension ASN1Object
{
    /// Using this initialization method we assume that data contains a proper asn1 object as defined by ITU-T X.690
    init(data: Data)
    {
        var tempData = data
        
        identifier = try! ASN1Object.extractIdentifier(from: &tempData)
        length = try! ASN1Object.extractLenght(from: &tempData)
        bytesCount = ASN1Object.identifierLenght + length.offset + length.value
        
        let offset = data.startIndex
        rawData = Data(tempData[offset..<(offset+bytesCount)])
    }
}


extension ASN1Object.Identifier
{
    var isPrimitive: Bool
    {
        return encodingType == .primitive
    }
    
    var isConstructed: Bool
    {
        return encodingType == .constructed
    }
}

extension ASN1Object.Length
{
    var value: Int
    {
        switch self
        {
        case .long(_, let value):
            return value
        case .short(let value):
            return value
        }
    }
    
    var offset: Int
    {
        switch self
        {
            
        case .long(let length, _):
            return 1 + length
        default:
            return 1
        }
    }
}
