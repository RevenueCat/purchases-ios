//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptParser.swift
//
//  Created by Andrés Boedo on 7/22/20.
//

import Foundation

class ReceiptParser {

    static let `default`: ReceiptParser = .init()

    private let containerBuilder: ASN1ContainerBuilder
    private let receiptBuilder: AppleReceiptBuilder

    init(containerBuilder: ASN1ContainerBuilder = ASN1ContainerBuilder(),
         receiptBuilder: AppleReceiptBuilder = AppleReceiptBuilder()) {
        self.containerBuilder = containerBuilder
        self.receiptBuilder = receiptBuilder
    }

    func receiptHasTransactions(receiptData: Data) -> Bool {
        Logger.info(Strings.receipt.parsing_receipt)
        if let receipt = try? parse(from: receiptData) {
            return receipt.inAppPurchases.count > 0
        }

        Logger.warn(Strings.receipt.parsing_receipt_failed(fileName: #fileID, functionName: #function))
        return true
    }

    func parse(from receiptData: Data) throws -> AppleReceipt {
        let intData = [UInt8](receiptData)

        let asn1Container = try containerBuilder.build(fromPayload: ArraySlice(intData))
        guard let receiptASN1Container = try findASN1Container(withObjectId: ASN1ObjectIdentifier.data,
                                                               inContainer: asn1Container) else {
            Logger.error(Strings.receipt.data_object_identifer_not_found_receipt)
            throw ReceiptReadingError.dataObjectIdentifierMissing
        }
        let receipt = try receiptBuilder.build(fromContainer: receiptASN1Container)
        Logger.info(Strings.receipt.parsing_receipt_success)
        return receipt
    }
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ReceiptParser: @unchecked Sendable {}

// MARK: -

private extension ReceiptParser {

    func findASN1Container(withObjectId objectId: ASN1ObjectIdentifier,
                           inContainer container: ASN1Container) throws -> ASN1Container? {
        if container.encodingType == .constructed {
            for (index, internalContainer) in container.internalContainers.enumerated() {
                if internalContainer.containerIdentifier == .objectIdentifier {
                    let objectIdentifier = try ASN1ObjectIdentifierBuilder.build(
                        fromPayload: internalContainer.internalPayload)
                    if objectIdentifier == objectId && index < container.internalContainers.count - 1 {
                        // the container that holds the data comes right after the one with the object identifier
                        return container.internalContainers[index + 1]
                    }
                } else {
                    let receipt = try findASN1Container(withObjectId: objectId, inContainer: internalContainer)
                    if receipt != nil {
                        return receipt
                    }
                }
            }
        }
        return nil
    }

}
