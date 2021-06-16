//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

class AppleReceiptBuilder {
    private let containerBuilder: ASN1ContainerBuilder
    private let inAppPurchaseBuilder: InAppPurchaseBuilder
    private let dateFormatter: ISO3601DateFormatter

    private let typeContainerIndex = 0
    private let versionContainerIndex = 1 // unused
    private let attributeTypeContainerIndex = 2
    private let expectedInternalContainersCount = 3 // type + version + attribute

    init(containerBuilder: ASN1ContainerBuilder = ASN1ContainerBuilder(),
         inAppPurchaseBuilder: InAppPurchaseBuilder = InAppPurchaseBuilder(),
         dateFormatter: ISO3601DateFormatter = ISO3601DateFormatter.shared) {
        self.containerBuilder = containerBuilder
        self.inAppPurchaseBuilder = inAppPurchaseBuilder
        self.dateFormatter = dateFormatter
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func build(fromContainer container: ASN1Container) throws -> AppleReceipt {
        var bundleId: String?
        var applicationVersion: String?
        var originalApplicationVersion: String?
        var opaqueValue: Data?
        var sha1Hash: Data?
        var creationDate: Date?
        var expirationDate: Date?
        var inAppPurchases: [InAppPurchase] = []

        guard let internalContainer = container.internalContainers.first else {
            throw ReceiptReadingError.receiptParsingError
        }
        let receiptContainer = try containerBuilder.build(fromPayload: internalContainer.internalPayload)
        for receiptAttribute in receiptContainer.internalContainers {
            guard receiptAttribute.internalContainers.count == expectedInternalContainersCount else {
                throw ReceiptReadingError.receiptParsingError
            }
            let typeContainer = receiptAttribute.internalContainers[typeContainerIndex]
            let valueContainer = receiptAttribute.internalContainers[attributeTypeContainerIndex]
            let attributeType = ReceiptAttributeType(rawValue: typeContainer.internalPayload.toInt())
            guard let nonOptionalType = attributeType else {
                continue
            }
            let payload = valueContainer.internalPayload

            switch nonOptionalType {
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
                creationDate = internalContainer.internalPayload.toDate(dateFormatter: dateFormatter)
            case .expirationDate:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                expirationDate = internalContainer.internalPayload.toDate(dateFormatter: dateFormatter)
            case .inAppPurchase:
                let internalContainer = try containerBuilder.build(fromPayload: payload)
                inAppPurchases.append(try inAppPurchaseBuilder.build(fromContainer: internalContainer))
            }
        }

        guard let nonOptionalBundleId = bundleId,
            let nonOptionalApplicationVersion = applicationVersion,
            let nonOptionalOriginalApplicationVersion = originalApplicationVersion,
            let nonOptionalOpaqueValue = opaqueValue,
            let nonOptionalSha1Hash = sha1Hash,
            let nonOptionalCreationDate = creationDate else {
            throw ReceiptReadingError.receiptParsingError
        }

        let receipt = AppleReceipt(bundleId: nonOptionalBundleId,
                                   applicationVersion: nonOptionalApplicationVersion,
                                   originalApplicationVersion: nonOptionalOriginalApplicationVersion,
                                   opaqueValue: nonOptionalOpaqueValue,
                                   sha1Hash: nonOptionalSha1Hash,
                                   creationDate: nonOptionalCreationDate,
                                   expirationDate: expirationDate,
                                   inAppPurchases: inAppPurchases)
        return receipt
    }
}
