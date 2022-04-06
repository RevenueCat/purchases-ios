//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ASN1Container.swift
//
//  Created by Andrés Boedo on 7/28/20.
//

import Foundation

enum ASN1Class: UInt8 {

    case universal, application, contextSpecific, `private`

}

enum ASN1Identifier: UInt8, CaseIterable {

    case endOfContent = 0
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

}

enum ASN1EncodingType: UInt8 {

    case primitive, constructed

}

struct ASN1Length: Equatable {

    let value: Int
    let bytesUsedForLength: Int
    let definition: LengthDefinition

    enum LengthDefinition: Int {

        case definite
        case indefinite

    }

}

struct ASN1Container: Equatable {

    let containerClass: ASN1Class
    let containerIdentifier: ASN1Identifier
    let encodingType: ASN1EncodingType
    let length: ASN1Length
    let internalPayload: ArraySlice<UInt8>
    let bytesUsedForIdentifier = 1
    var totalBytesUsed: Int { bytesUsedForIdentifier + length.value + length.bytesUsedForLength }
    let internalContainers: [ASN1Container]

}
