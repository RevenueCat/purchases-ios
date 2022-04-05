//
// Created by Andrés Boedo on 8/6/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class ContainerFactory {
    private let objectIdentifierEncoder = ASN1ObjectIdentifierEncoder()

    func simpleDataContainer() -> ASN1Container {
        let length = 55
        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: length, bytesUsedForLength: 1, definition: .definite),
                             internalPayload: ArraySlice(Array(repeating: UInt8(0b1), count: length)),
                             internalContainers: [])
    }

    func stringContainer(string: String) -> ASN1Container {
        let stringAsBytes = string.utf8
        guard stringAsBytes.count < 128 else { fatalError("this method is intended for short strings only") }
        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: stringAsBytes.count,
                                                bytesUsedForLength: 1,
                                                definition: .definite),
                             internalPayload: ArraySlice(Array(stringAsBytes)),
                             internalContainers: [])
    }

    func dateContainer(date: Date) -> ASN1Container {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"

        let dateString = dateFormatter.string(from: date)
        guard let stringAsData = (dateString.data(using: .ascii)) else { fatalError() }
        let stringAsBytes = [UInt8](stringAsData)
        guard stringAsBytes.count < 128 else { fatalError("this method is intended for short strings only") }

        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: stringAsBytes.count,
                                                bytesUsedForLength: 1,
                                                definition: .definite),
                             internalPayload: ArraySlice(stringAsBytes),
                             internalContainers: [])
    }

    func boolContainer(bool: Bool) -> ASN1Container {
        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: 1, bytesUsedForLength: 1, definition: .definite),
                             internalPayload: ArraySlice([UInt8(booleanLiteral: bool)]),
                             internalContainers: [])
    }

    func intContainer(int: Int) -> ASN1Container {
        let intAsBytes = intToBytes(int: int)
        let bytesUsedForLength = intAsBytes.count < 128 ? 1 : intToBytes(int: intAsBytes.count).count + 1

        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: intAsBytes.count,
                                                bytesUsedForLength: bytesUsedForLength,
                                                definition: .definite),
                             internalPayload: ArraySlice(intAsBytes),
                             internalContainers: [])
    }

    func int64Container(int64: Int64) -> ASN1Container {
        let intAsBytes = int64ToBytes(int: int64)
        let bytesUsedForLength = intAsBytes.count < 128 ? 1 : intToBytes(int: intAsBytes.count).count + 1

        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: .primitive,
                             length: ASN1Length(value: intAsBytes.count,
                                                bytesUsedForLength: bytesUsedForLength,
                                                definition: .definite),
                             internalPayload: ArraySlice(intAsBytes),
                             internalContainers: [])
    }

    func constructedContainer(containers: [ASN1Container],
                              encodingType: ASN1EncodingType = .constructed) -> ASN1Container {
        let payload = containers.flatMap { self.headerBytes(forContainer: $0) + $0.internalPayload }
        let bytesUsedForLength = payload.count < 128 ? 1 : intToBytes(int: payload.count).count + 1
        return ASN1Container(containerClass: .application,
                             containerIdentifier: .octetString,
                             encodingType: encodingType,
                             length: ASN1Length(value: payload.count,
                                                bytesUsedForLength: bytesUsedForLength,
                                                definition: .definite),
                             internalPayload: ArraySlice(payload),
                             internalContainers: containers)
    }

    func receiptDataAttributeContainer(attributeType: BuildableReceiptAttributeType) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = simpleDataContainer()

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptAttributeContainer(attributeType: BuildableReceiptAttributeType, _ value: Int) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = constructedContainer(containers: [intContainer(int: value)])

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptAttributeContainer(attributeType: BuildableReceiptAttributeType, _ value: Int64) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = constructedContainer(containers: [int64Container(int64: value)])

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptAttributeContainer(attributeType: BuildableReceiptAttributeType, _ date: Date) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = constructedContainer(containers: [dateContainer(date: date)])

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptAttributeContainer(attributeType: BuildableReceiptAttributeType, _ bool: Bool) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = constructedContainer(containers: [boolContainer(bool: bool)])

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptAttributeContainer(attributeType: BuildableReceiptAttributeType,
                                   _ string: String) -> ASN1Container {
        let typeContainer = intContainer(int: attributeType.rawValue)
        let versionContainer = intContainer(int: 1)
        let valueContainer = constructedContainer(containers: [stringContainer(string: string)])

        return constructedContainer(containers: [typeContainer, versionContainer, valueContainer])
    }

    func receiptContainerFromContainers(containers: [ASN1Container]) -> ASN1Container {
        let attributesContainer = constructedContainer(containers: containers)

        let receiptWrapper = constructedContainer(containers: [attributesContainer],
                                                  encodingType: .primitive)
        return constructedContainer(containers: [receiptWrapper],
                                    encodingType: .constructed)
    }

    func inAppPurchaseContainerFromContainers(containers: [ASN1Container]) -> ASN1Container {
        return constructedContainer(containers: containers,
                                    encodingType: .constructed)
    }

    func objectIdentifierContainer(_ objectIdentifier: ASN1ObjectIdentifier) -> ASN1Container {
        let payload = objectIdentifierEncoder.objectIdentifierPayload(objectIdentifier)
        let bytesUsedForLength = payload.count < 128 ? 1 : intToBytes(int: payload.count).count + 1

        return ASN1Container(containerClass: .application,
                             containerIdentifier: .objectIdentifier,
                             encodingType: .primitive,
                             length: ASN1Length(value: payload.count,
                                                bytesUsedForLength: bytesUsedForLength,
                                                definition: .definite),
                             internalPayload: payload,
                             internalContainers: [])
    }
}

private extension ContainerFactory {
    func intToBytes(int: Int) -> [UInt8] {
        let intAsBytes = withUnsafeBytes(of: int.bigEndian, Array.init)
        let arrayWithoutInsignificantBytes = Array(intAsBytes.drop(while: { $0 == 0 }))
        return arrayWithoutInsignificantBytes
    }

    func int64ToBytes(int: Int64) -> [UInt8] {
        let intAsBytes = withUnsafeBytes(of: int.bigEndian, Array.init)
        let arrayWithoutInsignificantBytes = Array(intAsBytes.drop(while: { $0 == 0 }))
        return arrayWithoutInsignificantBytes
    }

    func headerBytes(forContainer container: ASN1Container) -> [UInt8] {
        let identifierHeader = (container.containerClass.rawValue << 6
                                    | container.encodingType.rawValue << 5
                                    | container.containerIdentifier.rawValue)
        if container.length.value < 128 {
            return [identifierHeader] + [UInt8(container.length.value)]
        } else {
            var lengthHeader = intToBytes(int: container.length.value)
            let firstByte = 0b10000000 | UInt8(container.length.bytesUsedForLength - 1)
            lengthHeader.insert(firstByte, at: 0)
            return [identifierHeader] + lengthHeader
        }
    }
}

protocol BuildableReceiptAttributeType {
    var rawValue: Int { get }
}
extension InAppPurchaseAttributeType: BuildableReceiptAttributeType {}
extension ReceiptAttributeType: BuildableReceiptAttributeType {}
