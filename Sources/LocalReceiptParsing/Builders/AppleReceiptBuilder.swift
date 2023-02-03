//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppleReceiptBuilder.swift
//
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

class AppleReceiptBuilder {

    private let containerBuilder: ASN1ContainerBuilder
    private let inAppPurchaseBuilder: InAppPurchaseBuilder

    private let typeContainerIndex = 0
    private let versionContainerIndex = 1 // unused
    private let attributeTypeContainerIndex = 2
    private let expectedInternalContainersCount = 3 // type + version + attribute

    init(containerBuilder: ASN1ContainerBuilder = ASN1ContainerBuilder(),
         inAppPurchaseBuilder: InAppPurchaseBuilder = InAppPurchaseBuilder()) {
        self.containerBuilder = containerBuilder
        self.inAppPurchaseBuilder = inAppPurchaseBuilder
    }

    /// - Throws: ``PurchasesReceiptParser/Error``
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func build(fromContainer container: ASN1Container) throws -> AppleReceipt {
        var bundleId: String?
        var applicationVersion: String?
        var originalApplicationVersion: String?
        var opaqueValue: Data?
        var sha1Hash: Data?
        var creationDate: Date?
        var expirationDate: Date?
        var inAppPurchases: [AppleReceipt.InAppPurchase] = []

        guard let internalContainer = container.internalContainers.first else {
            throw PurchasesReceiptParser.Error.receiptParsingError
        }
        var receiptContainer = try containerBuilder.build(fromPayload: internalContainer.internalPayload)

        // StoreKitTest receipts have their data embedded into 2 levels of octetString containers,
        // Regular receipts have it in only one. At this point we've already unwrapped the upper level
        // so we check whether we need to go one deeper.
        let isStoreKitTestReceipt = receiptContainer.encodingType == .primitive
                                    && receiptContainer.containerIdentifier == .octetString
        if isStoreKitTestReceipt {
            receiptContainer = try containerBuilder.build(fromPayload: receiptContainer.internalPayload)
        }

        for receiptAttribute in receiptContainer.internalContainers {
            guard receiptAttribute.internalContainers.count == expectedInternalContainersCount else {
                throw PurchasesReceiptParser.Error.receiptParsingError
            }
            let typeContainer = receiptAttribute.internalContainers[typeContainerIndex]
            let valueContainer = receiptAttribute.internalContainers[attributeTypeContainerIndex]

            guard let attributeType = AppleReceipt.Attribute.AttributeType(
                rawValue: typeContainer.internalPayload.toInt()
            ) else { continue }

            let payload = valueContainer.internalPayload

            switch attributeType {
            case .opaqueValue:
                opaqueValue = payload.toData()
            case .sha1Hash:
                sha1Hash = payload.toData()
            case .applicationVersion:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                applicationVersion = internalContainer.internalPayload.toString()
            case .originalApplicationVersion:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                originalApplicationVersion = internalContainer.internalPayload.toString()
            case .bundleId:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                bundleId = internalContainer.internalPayload.toString()
            case .creationDate:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                creationDate = internalContainer.internalPayload.toDate()
            case .expirationDate:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                expirationDate = internalContainer.internalPayload.toDate()
            case .inAppPurchase:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                inAppPurchases.append(try inAppPurchaseBuilder.build(fromContainer: internalContainer))
            }
        }

        guard let nonOptionalBundleId = bundleId,
            let nonOptionalApplicationVersion = applicationVersion,
            let nonOptionalOpaqueValue = opaqueValue,
            let nonOptionalSha1Hash = sha1Hash,
            let nonOptionalCreationDate = creationDate else {
            throw PurchasesReceiptParser.Error.receiptParsingError
        }

        let receipt = AppleReceipt(bundleId: nonOptionalBundleId,
                                   applicationVersion: nonOptionalApplicationVersion,
                                   originalApplicationVersion: originalApplicationVersion,
                                   opaqueValue: nonOptionalOpaqueValue,
                                   sha1Hash: nonOptionalSha1Hash,
                                   creationDate: nonOptionalCreationDate,
                                   expirationDate: expirationDate,
                                   inAppPurchases: inAppPurchases)
        return receipt
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension AppleReceiptBuilder: @unchecked Sendable {}

// swiftlint:disable nesting

extension AppleReceipt {

    /// See docs: https://rev.cat/apple-receipt-fields
    struct Attribute {

        enum AttributeType: Int {

            case bundleId = 2,
                 applicationVersion = 3,
                 opaqueValue = 4,
                 sha1Hash = 5,
                 creationDate = 12,
                 inAppPurchase = 17,
                 originalApplicationVersion = 19,
                 expirationDate = 21

        }

        let type: AttributeType
        let version: Int
        let value: String

    }

}
