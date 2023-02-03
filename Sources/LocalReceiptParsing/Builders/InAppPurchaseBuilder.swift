//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

class InAppPurchaseBuilder {

    typealias InAppPurchase = AppleReceipt.InAppPurchase

    // swiftlint:disable:next line_length
    // https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
    enum AttributeType: Int {

        case quantity = 1701,
             productId = 1702,
             transactionId = 1703,
             purchaseDate = 1704,
             originalTransactionId = 1705,
             originalPurchaseDate = 1706,
             productType = 1707,
             expiresDate = 1708,
             webOrderLineItemId = 1711,
             cancellationDate = 1712,
             isInTrialPeriod = 1713,
             isInIntroOfferPeriod = 1719,
             promotionalOfferIdentifier = 1721

    }

    private let containerBuilder: ASN1ContainerBuilder
    private let typeContainerIndex = 0
    private let versionContainerIndex = 1 // unused
    private let attributeTypeContainerIndex = 2
    private let expectedInternalContainersCount = 3 // type + version + attribute

    init() {
        self.containerBuilder = ASN1ContainerBuilder()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func build(fromContainer container: ASN1Container) throws -> InAppPurchase {
        var quantity: Int?
        var productId: String?
        var transactionId: String?
        var originalTransactionId: String?
        var productType: InAppPurchase.ProductType = .unknown
        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var expiresDate: Date?
        var cancellationDate: Date?
        var isInTrialPeriod: Bool?
        var isInIntroOfferPeriod: Bool?
        var webOrderLineItemId: Int64?
        var promotionalOfferIdentifier: String?

        for internalContainer in container.internalContainers {
            guard internalContainer.internalContainers.count == expectedInternalContainersCount else {
                throw PurchasesReceiptParser.Error.inAppPurchaseParsingError
            }
            let typeContainer = internalContainer.internalContainers[typeContainerIndex]
            let valueContainer = internalContainer.internalContainers[attributeTypeContainerIndex]

            guard let attributeType = AttributeType(rawValue: typeContainer.internalPayload.toInt())
                else { continue }

            let internalContainer = try containerBuilder.build(fromPayload: valueContainer.internalPayload)
            guard internalContainer.length.value > 0 else { continue }

            switch attributeType {
            case .quantity:
                quantity = internalContainer.internalPayload.toInt()
            case .webOrderLineItemId:
                webOrderLineItemId = internalContainer.internalPayload.toInt64()
            case .productType:
                productType = .init(rawValue: internalContainer.internalPayload.toInt()) ?? .unknown
            case .isInIntroOfferPeriod:
                isInIntroOfferPeriod = internalContainer.internalPayload.toBool()
            case .isInTrialPeriod:
                isInTrialPeriod = internalContainer.internalPayload.toBool()
            case .productId:
                productId = internalContainer.internalPayload.toString()
            case .transactionId:
                transactionId = internalContainer.internalPayload.toString()
            case .originalTransactionId:
                originalTransactionId = internalContainer.internalPayload.toString()
            case .promotionalOfferIdentifier:
                promotionalOfferIdentifier = internalContainer.internalPayload.toString()
            case .cancellationDate:
                cancellationDate = internalContainer.internalPayload.toDate()
            case .expiresDate:
                expiresDate = internalContainer.internalPayload.toDate()
            case .originalPurchaseDate:
                originalPurchaseDate = internalContainer.internalPayload.toDate()
            case .purchaseDate:
                purchaseDate = internalContainer.internalPayload.toDate()
            }
        }

        guard let nonOptionalQuantity = quantity,
            let nonOptionalProductId = productId,
            let nonOptionalTransactionId = transactionId,
            let nonOptionalPurchaseDate = purchaseDate else {
            throw PurchasesReceiptParser.Error.inAppPurchaseParsingError
        }

        return InAppPurchase(quantity: nonOptionalQuantity,
                             productId: nonOptionalProductId,
                             transactionId: nonOptionalTransactionId,
                             originalTransactionId: originalTransactionId,
                             productType: productType,
                             purchaseDate: nonOptionalPurchaseDate,
                             originalPurchaseDate: originalPurchaseDate,
                             expiresDate: expiresDate,
                             cancellationDate: cancellationDate,
                             isInTrialPeriod: isInTrialPeriod,
                             isInIntroOfferPeriod: isInIntroOfferPeriod,
                             webOrderLineItemId: webOrderLineItemId,
                             promotionalOfferIdentifier: promotionalOfferIdentifier)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension InAppPurchaseBuilder: @unchecked Sendable {}
