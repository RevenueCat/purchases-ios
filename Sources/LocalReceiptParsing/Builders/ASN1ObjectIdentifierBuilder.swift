//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ASN1ObjectIdentifierBuilder.swift
//
//  Created by Andrés Boedo on 7/28/20.
//

import Foundation

enum ASN1ObjectIdentifierBuilder {

    // info on the format: https://docs.microsoft.com/en-us/windows/win32/seccertenroll/about-object-identifier
    static func build(fromPayload payload: ArraySlice<UInt8>) throws -> ASN1ObjectIdentifier? {
        guard let firstByte = payload.first else { return nil }

        var objectIdentifierNumbers: [UInt] = []
        objectIdentifierNumbers.append(UInt(firstByte / 40))
        objectIdentifierNumbers.append(UInt(firstByte % 40))

        let trailingPayload = payload.dropFirst()
        let variableLengthQuantityNumbers = try decodeVariableLengthQuantity(payload: trailingPayload)
        objectIdentifierNumbers += variableLengthQuantityNumbers

        let objectIdentifierString = objectIdentifierNumbers.map { String($0) }
                                                            .joined(separator: ".")
        return ASN1ObjectIdentifier(rawValue: objectIdentifierString)
    }
}

private extension ASN1ObjectIdentifierBuilder {

    // https://en.wikipedia.org/wiki/Variable-length_quantity
    static func decodeVariableLengthQuantity(payload: ArraySlice<UInt8>) throws -> [UInt] {
        var decodedNumbers = [UInt]()

        var currentBuffer: UInt = 0
        var isShortLength = false
        for byte in payload {
            isShortLength = try byte.bitAtIndex(0) == 0
            let byteValue = UInt(try byte.valueInRange(from: 1, to: 7))

            currentBuffer = (currentBuffer << 7) | byteValue
            if isShortLength {
                decodedNumbers.append(currentBuffer)
                currentBuffer = 0
            }
        }
        return decodedNumbers
    }
}
