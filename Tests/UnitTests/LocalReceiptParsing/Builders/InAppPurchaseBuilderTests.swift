//
// Created by Andrés Boedo on 8/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class InAppPurchaseBuilderTests: TestCase {
    // swiftlint:disable force_try
    let quantity = 2
    let productId = "com.revenuecat.sampleProduct"
    let transactionId = "089230953203"
    let originalTransactionId = "089230953101"
    let productType = InAppPurchaseProductType.autoRenewableSubscription
    let purchaseDate = try! Date.from(year: 2019, month: 5, day: 3, hour: 1, minute: 55, second: 1)
    let originalPurchaseDate = try! Date.from(year: 2018, month: 6, day: 22, hour: 1, minute: 55, second: 1)
    let expiresDate = try! Date.from(year: 2018, month: 6, day: 22, hour: 1, minute: 55, second: 1)
    let cancellationDate = try! Date.from(year: 2019, month: 7, day: 4, hour: 7, minute: 1, second: 45)
    let isInTrialPeriod = false
    let isInIntroOfferPeriod = true
    let webOrderLineItemId = Int64(897501072)
    let promotionalOfferIdentifier = "com.revenuecat.productPromoOffer"
    // swiftlint:enable force_try

    private let containerFactory = ContainerFactory()
    private var inAppPurchaseBuilder: InAppPurchaseBuilder!

    override func setUp() {
        super.setUp()
        self.inAppPurchaseBuilder = InAppPurchaseBuilder()
    }

    func testCanBuildFromMinimalAttributes() {
        let sampleReceiptContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        expect { try self.inAppPurchaseBuilder.build(fromContainer: sampleReceiptContainer) }.notTo(throwError())
    }

    func testBuildThrowsIfUnexpectedNumberOfInternalContainers() {
        let typeContainer = containerFactory.intContainer(int: 1)
        let versionContainer = containerFactory.intContainer(int: 1)
        let valueContainer = containerFactory.constructedContainer(
            containers: [containerFactory.stringContainer(string: "test")]
        )
        let unexpectedContainer = containerFactory.intContainer(int: 2)

        let inAppPurchaseContainer = containerFactory.constructedContainer(
            containers: [typeContainer, versionContainer, valueContainer, unexpectedContainer]
        )

        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.to(throwError())
    }

    func testBuildGetsCorrectQuantity() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.quantity) == quantity
    }

    func testBuildGetsCorrectProductId() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.productId) == productId
    }

    func testBuildGetsCorrectTransactionId() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.transactionId) == transactionId
    }

    func testBuildGetsCorrectOriginalTransactionId() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.originalTransactionId) == originalTransactionId
    }

    func testBuildGetsCorrectPurchaseDate() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.purchaseDate) == purchaseDate
    }

    func testBuildGetsCorrectOriginalPurchaseDate() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.originalPurchaseDate) == originalPurchaseDate
    }

    func testBuildGetsCorrectIsInIntroOfferPeriod() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.isInIntroOfferPeriod) == isInIntroOfferPeriod
    }

    func testBuildGetsCorrectWebOrderLineItemId() throws {
        let sampleInAppPurchaseContainer = sampleInAppPurchaseContainerWithMinimalAttributes()
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: sampleInAppPurchaseContainer)
        expect(inAppPurchase.webOrderLineItemId) == webOrderLineItemId
    }

    func testBuildGetsCorrectProductType() throws {
        let inAppPurchaseContainer = containerFactory
            .inAppPurchaseContainerFromContainers(containers: minimalAttributes() + [productTypeContainer()])
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer)

        expect(inAppPurchase.productType) == productType
    }

    func testBuildGetsCorrectExpiresDate() throws {
        let inAppPurchaseContainer = containerFactory
            .inAppPurchaseContainerFromContainers(containers: minimalAttributes() + [expiresDateContainer()])
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer)

        expect(inAppPurchase.expiresDate) == expiresDate
    }

    func testBuildGetsCorrectCancellationDate() throws {
        let inAppPurchaseContainer = containerFactory
            .inAppPurchaseContainerFromContainers(containers: minimalAttributes() + [cancellationDateContainer()])
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer)

        expect(inAppPurchase.cancellationDate) == cancellationDate
    }

    func testBuildGetsCorrectIsInTrialPeriod() throws {
        let inAppPurchaseContainer = containerFactory
            .inAppPurchaseContainerFromContainers(containers: minimalAttributes() + [isInTrialPeriodContainer()])
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer)

        expect(inAppPurchase.isInTrialPeriod) == isInTrialPeriod
    }

    func testBuildGetsCorrectPromotionalOfferIdentifier() throws {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(
            containers: minimalAttributes() + [promotionalOfferIdentifierContainer()]
        )
        let inAppPurchase = try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer)

        expect(inAppPurchase.promotionalOfferIdentifier) == promotionalOfferIdentifier
    }

    func testBuildThrowsIfQuantityIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.to(throwError())
    }

    func testBuildThrowsIfProductIdIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.to(throwError())
    }

    func testBuildThrowsIfTransactionIdIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.to(throwError())
    }

    func testBuildDoesntThrowIfOriginalTransactionIdIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.notTo(throwError())
    }

    func testBuildThrowsIfPurchaseDateIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.to(throwError())
    }

    func testBuildDoesntThrowIfOriginalPurchaseDateIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.notTo(throwError())
    }

    func testBuildDoesntThrowIfIsInIntroOfferPeriodIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            webOrderLineItemIdContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.notTo(throwError())
    }

    func testBuildDoesntThrowIfWebOrderLineItemIdIsMissing() {
        let inAppPurchaseContainer = containerFactory.inAppPurchaseContainerFromContainers(containers: [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer()
        ])
        expect { try self.inAppPurchaseBuilder.build(fromContainer: inAppPurchaseContainer) }.notTo(throwError())
    }
}

private extension InAppPurchaseBuilderTests {

    func sampleInAppPurchaseContainerWithMinimalAttributes() -> ASN1Container {
        return containerFactory.inAppPurchaseContainerFromContainers(containers: minimalAttributes())
    }

    func minimalAttributes() -> [ASN1Container] {
        return [
            quantityContainer(),
            productIdContainer(),
            transactionIdContainer(),
            originalTransactionIdContainer(),
            purchaseDateContainer(),
            originalPurchaseDateContainer(),
            isInIntroOfferPeriodContainer(),
            webOrderLineItemIdContainer()
        ]
    }

    func quantityContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.quantity,
            quantity
        )
    }

    func productIdContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.productId,
            productId
        )
    }

    func transactionIdContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.transactionId,
            transactionId
        )
    }

    func originalTransactionIdContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.originalTransactionId,
            originalTransactionId
        )
    }

    func productTypeContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.productType,
            productType.rawValue
        )
    }

    func purchaseDateContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.purchaseDate,
            purchaseDate
        )
    }

    func originalPurchaseDateContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.originalPurchaseDate,
            originalPurchaseDate
        )
    }

    func expiresDateContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.expiresDate,
            expiresDate
        )
    }

    func cancellationDateContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.cancellationDate,
            cancellationDate
        )
    }

    func isInTrialPeriodContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.isInTrialPeriod,
            isInTrialPeriod
        )
    }

    func isInIntroOfferPeriodContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.isInIntroOfferPeriod,
            isInIntroOfferPeriod
        )
    }

    func webOrderLineItemIdContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.webOrderLineItemId,
            webOrderLineItemId
        )
    }

    func promotionalOfferIdentifierContainer() -> ASN1Container {
        return containerFactory.receiptAttributeContainer(
            attributeType: InAppPurchaseAttributeType.promotionalOfferIdentifier,
            promotionalOfferIdentifier
        )
    }
}
