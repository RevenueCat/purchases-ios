//
//  ASN1Helper.swift
//  TPReceiptValidator
//
//  Created by Pavel Tikhonenko on 29/09/16.
//  Copyright © 2016-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

struct InAppReceiptAttribute
{
    var type: Int!
    var version: Int!
    var value: ASN1Object!
}

extension ASN1Object
{
    func enumerateInAppReceiptAttributes(with block: (InAppReceiptAttribute) -> Void)
    {
        for item in enumerated()
        {
            var attr = InAppReceiptAttribute()
            
            for i in item.element.enumerated()
            {
                let elmnt = i.element
                let type = elmnt.identifier.type
                
                if type == .unknown { continue }
                
                switch type
                {
                case .integer:
                    if let value = elmnt.extractValue() as? Int
                    {
                        if attr.type == nil
                        {
                            attr.type = value
                        }else{
                            attr.version = value
                        }
                    }
                    break
                case .octetString:
                    attr.value = elmnt
                default:
                    continue
                }
            }
            
            block(attr)
        }
    }
}
