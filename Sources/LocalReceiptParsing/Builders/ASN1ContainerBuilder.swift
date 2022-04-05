//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ASN1ContainerBuilder.swift
//
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

class ASN1ContainerBuilder {

    func build(fromPayload payload: ArraySlice<UInt8>) throws -> ASN1Container {
        guard payload.count >= 2,
            let firstByte = payload.first else {
            throw ReceiptReadingError.asn1ParsingError(description: "payload needs to be at least 2 bytes long")
        }
        let containerClass = try extractClass(byte: firstByte)
        let encodingType = try extractEncodingType(byte: firstByte)
        let containerIdentifier = try extractIdentifier(byte: firstByte)
        let length = try extractLength(data: payload.dropFirst(), isConstructed: encodingType == .constructed)
        let bytesUsedForIdentifier = 1
        let bytesUsedForMetadata = bytesUsedForIdentifier + length.bytesUsedForLength

        guard payload.count - bytesUsedForMetadata >= length.value else {
            throw ReceiptReadingError.asn1ParsingError(description: "payload is shorter than length value")
        }

        let internalPayload = payload.dropFirst(bytesUsedForMetadata).prefix(length.value)

        var internalContainers: [ASN1Container] = []
        if encodingType == .constructed {
            internalContainers = try buildInternalContainers(payload: internalPayload)
        }
        return ASN1Container(containerClass: containerClass,
                             containerIdentifier: containerIdentifier,
                             encodingType: encodingType,
                             length: length,
                             internalPayload: internalPayload,
                             internalContainers: internalContainers)
    }
}

private extension ASN1ContainerBuilder {

    func buildInternalContainers(payload: ArraySlice<UInt8>) throws -> [ASN1Container] {
        var internalContainers = [ASN1Container]()
        var currentPayload = payload
        while currentPayload.count > 0 {
            let internalContainer = try build(fromPayload: currentPayload)
            internalContainers.append(internalContainer)
            if internalContainer.containerIdentifier == .endOfContent {
                break
            }
            currentPayload = currentPayload.dropFirst(internalContainer.totalBytesUsed)
        }
        return internalContainers
    }

    func extractClass(byte: UInt8) throws -> ASN1Class {
        let firstTwoBits = try byte.valueInRange(from: 0, to: 1)
        guard let asn1Class = ASN1Class(rawValue: firstTwoBits) else {
            throw ReceiptReadingError.asn1ParsingError(description: "couldn't determine asn1 class")
        }
        return asn1Class
    }

    func extractEncodingType(byte: UInt8) throws -> ASN1EncodingType {
        let thirdBit = try byte.bitAtIndex(2)
        guard let encodingType = ASN1EncodingType(rawValue: thirdBit) else {
            throw ReceiptReadingError.asn1ParsingError(description: "couldn't determine encoding type")
        }
        return encodingType
    }

    func extractIdentifier(byte: UInt8) throws -> ASN1Identifier {
        let lastFiveBits = try byte.valueInRange(from: 3, to: 7)
        guard let asn1Identifier = ASN1Identifier(rawValue: lastFiveBits) else {
            throw ReceiptReadingError.asn1ParsingError(description: "couldn't determine identifier")
        }
        return asn1Identifier
    }

    func extractLength(data: ArraySlice<UInt8>, isConstructed: Bool) throws -> ASN1Length {
        guard let firstByte = data.first else {
            throw ReceiptReadingError.asn1ParsingError(description: "length needs to be at least one byte")
        }

        let lengthBit = try firstByte.bitAtIndex(0)
        let isShortLength = lengthBit == 0

        let firstByteValue = Int(try firstByte.valueInRange(from: 1, to: 7))

        var bytesUsedForLength = 1

        var lengthValue: Int
        if isShortLength {
            lengthValue = firstByteValue
        } else {
            let totalLengthBytes = firstByteValue
            bytesUsedForLength += totalLengthBytes
            let lengthBytes = data.dropFirst().prefix(totalLengthBytes)
            lengthValue = lengthBytes.toInt()
        }
        // StoreKitTest receipts report a length of zero for Constructed elements.
        // This is called indefinite-length in ASN1 containers.
        // When length == 0, the element's contents end when there's a container with .endOfContent identifier
        // To get the length, we build the internal containers until we run into .endOfContent
        let lengthDefinition: ASN1Length.LengthDefinition = (isConstructed && lengthValue == 0)
                                                            ? .indefinite : .definite

        if lengthDefinition == .indefinite {
            let innerContainers = try buildInternalContainers(payload: data.dropFirst(bytesUsedForLength))
            let innerContainersOverallLength = innerContainers.map { $0.totalBytesUsed }.reduce(0, +)
            lengthValue = innerContainersOverallLength
        }
        return ASN1Length(value: lengthValue, bytesUsedForLength: bytesUsedForLength, definition: lengthDefinition)
    }

}
