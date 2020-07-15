//
//  ASN1Object+Sequence.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 24/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

struct ASN1Iterator: IteratorProtocol
{
    typealias Element = ASN1Object
    
    let asn1: ASN1Object
    var lastItem: ASN1Object
    var bytesLeft: Int = 0
    var offset: Int = 0
    var bytes: Data
    
    init(_ asn1: ASN1Object)
    {
        self.asn1 = asn1
        self.bytes = asn1.valueData ?? Data()
        
        self.lastItem = asn1
        self.bytesLeft = asn1.length.value
    }
    
    mutating func next() -> Element?
    {
        guard bytes.count > 0, asn1.identifier.encodingType == .constructed, bytesLeft > 0 else
        {
            return nil
        }
        
        let valueData = bytes[offset ..< bytes.count]
        let asn1 = ASN1Object(data: valueData)
        lastItem = asn1
        
        bytesLeft -= asn1.bytesCount
        offset += asn1.bytesCount
        
        return asn1
    }
}

extension ASN1Object: Sequence
{
    func makeIterator() -> ASN1Iterator
    {
        return ASN1Iterator(self)
    }
    
    typealias Element = ASN1Object
}
