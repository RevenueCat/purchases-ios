//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesReceiptParser.swift
//
//  Created by Andrés Boedo on 7/22/20.
//

import Foundation

/// A type that can parse Apple receipts from a device.
/// This implements parsing based on [Apple's documentation](https://rev.cat/apple-receipt-fields).
///
/// To use this class you must access ``PurchasesReceiptParser/default``:
/// ```swift
/// let parser = PurchasesReceiptParser.default
/// let receipt = try parser.parse(from: data)
/// ```
public class PurchasesReceiptParser: NSObject {

    private let logger: LoggerType
    private let containerBuilder: ASN1ContainerBuilder
    private let receiptBuilder: AppleReceiptBuilder

    internal init(logger: LoggerType,
                  containerBuilder: ASN1ContainerBuilder = ASN1ContainerBuilder(),
                  receiptBuilder: AppleReceiptBuilder = AppleReceiptBuilder()) {
        self.logger = logger
        self.containerBuilder = containerBuilder
        self.receiptBuilder = receiptBuilder
    }

    /// Returns the result of parsing the receipt from `receiptData`
    /// - Throws: ``PurchasesReceiptParser/Error``.
    public func parse(from receiptData: Data) throws -> AppleReceipt {
        #if DEBUG
        Self.ensureRunningOutsideOfMainThread()
        #endif

        self.logger.info(ReceiptStrings.parsing_receipt)

        let asn1Container = try self.containerBuilder.build(fromPayload: ArraySlice(receiptData))
        guard let receiptASN1Container = try self.findASN1Container(withObjectId: ASN1ObjectIdentifier.data,
                                                                    inContainer: asn1Container) else {
            self.logger.error(ReceiptStrings.data_object_identifier_not_found_receipt)
            throw Error.dataObjectIdentifierMissing
        }

        let receipt = try self.receiptBuilder.build(fromContainer: receiptASN1Container)
        self.logger.info(ReceiptStrings.parsing_receipt_success)
        return receipt
    }

}

public extension PurchasesReceiptParser {

    /// Returns the result of parsing the receipt from a base64 encoded string.
    /// - Throws: ``PurchasesReceiptParser/Error``.
    func parse(base64String string: String) throws -> AppleReceipt {
        guard let data = Data(base64Encoded: string) else {
            throw Error.failedToDecodeBase64String
        }

        return try self.parse(from: data)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension PurchasesReceiptParser: @unchecked Sendable {}

// MARK: - Internal

extension PurchasesReceiptParser {

    @objc
    func receiptHasTransactions(receiptData: Data) -> Bool {
        if let receipt = try? self.parse(from: receiptData) {
            return !receipt.inAppPurchases.isEmpty
        }

        self.logger.warn(ReceiptStrings.parsing_receipt_failed(fileName: #fileID, functionName: #function))
        return true
    }

}

// MARK: - Private

private extension PurchasesReceiptParser {

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
                    let receipt = try self.findASN1Container(withObjectId: objectId, inContainer: internalContainer)
                    if receipt != nil {
                        return receipt
                    }
                }
            }
        }
        return nil
    }

    #if DEBUG
    static func ensureRunningOutsideOfMainThread() {
        // Only checking on integration tests.
        // Unit tests might run on the main thread when testing this class directly.
        if ProcessInfo.processInfo.environment["RCRunningIntegrationTests"] == "1" {
            precondition(
                !Thread.isMainThread,
                "Receipt parsing should not run on the main thread."
            )
        }
    }
    #endif

}
