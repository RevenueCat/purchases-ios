import Nimble
import XCTest

@testable import RevenueCat

class AppleReceiptBuilderTests: TestCase {
    let containerFactory = ContainerFactory()
    var appleReceiptBuilder: AppleReceiptBuilder!
    var mockInAppPurchaseBuilder: MockInAppPurchaseBuilder!

    let bundleId = "com.revenuecat.test"
    let applicationVersion = "3.2.1"
    let originalApplicationVersion = "1.2.2"
    // swiftlint:disable:next force_try
    let creationDate = try! Date.from(year: 2020, month: 3, day: 23, hour: 15, minute: 5, second: 3)

    override func setUp() {
        super.setUp()
        self.mockInAppPurchaseBuilder = MockInAppPurchaseBuilder()
        self.appleReceiptBuilder = AppleReceiptBuilder(inAppPurchaseBuilder: mockInAppPurchaseBuilder)
    }

    func testCanBuildCorrectlyWithMinimalAttributes() {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        expect { try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer) }.notTo(throwError())
    }

    func testBuildGetsCorrectBundleId() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.bundleId) == bundleId
    }

    func testBuildGetsCorrectApplicationVersion() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.applicationVersion) == applicationVersion
    }

    func testBuildGetsCorrectOriginalApplicationVersion() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.originalApplicationVersion) == originalApplicationVersion
    }

    func testBuildGetsCorrectCreationDate() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.creationDate) == creationDate
    }

    func testBuildGetsSha1Hash() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.sha1Hash).toNot(beNil())
    }

    func testBuildGetsOpaqueValue() throws {
        let sampleReceiptContainer = sampleReceiptContainerWithMinimalAttributes()
        let receipt = try self.appleReceiptBuilder.build(fromContainer: sampleReceiptContainer)
        expect(receipt.opaqueValue).toNot(beNil())
    }

    func testBuildGetsExpiresDate() throws {
        let expirationDate = try Date.from(year: 2020, month: 7, day: 4, hour: 5, minute: 3, second: 2)
        let expirationDateContainer =
            containerFactory.receiptAttributeContainer(attributeType: ReceiptAttributeType.expirationDate,
                                                       expirationDate)
        let receiptContainer =
            containerFactory.receiptContainerFromContainers(containers: minimalAttributes() + [expirationDateContainer])

        let receipt = try self.appleReceiptBuilder.build(fromContainer: receiptContainer)
        expect(receipt.expirationDate) == expirationDate
    }

    func testBuildGetsInAppPurchases() throws {
        let totalInAppPurchases = Int.random(in: 5..<20)
        let inAppContainers = (Int(0)..<totalInAppPurchases).map { _ in
            containerFactory.receiptDataAttributeContainer(attributeType: ReceiptAttributeType.inAppPurchase)
        }

        let receiptContainer = containerFactory
            .receiptContainerFromContainers(containers: minimalAttributes() + inAppContainers)

        mockInAppPurchaseBuilder.stubbedBuildResult = InAppPurchase(quantity: 2,
                                                                    productId: "com.revenuecat.sometest",
                                                                    transactionId: "8923532523",
                                                                    originalTransactionId: "235325322",
                                                                    productType: .nonRenewingSubscription,
                                                                    purchaseDate: Date(),
                                                                    originalPurchaseDate: Date(),
                                                                    expiresDate: nil,
                                                                    cancellationDate: nil,
                                                                    isInTrialPeriod: false,
                                                                    isInIntroOfferPeriod: false,
                                                                    webOrderLineItemId: Int64(658464),
                                                                    promotionalOfferIdentifier: nil)

        let receipt = try self.appleReceiptBuilder.build(fromContainer: receiptContainer)
        expect(receipt.inAppPurchases.count) == totalInAppPurchases
        expect(self.mockInAppPurchaseBuilder.invokedBuildCount) == totalInAppPurchases

        for inAppPurchase in receipt.inAppPurchases {
            expect(inAppPurchase) == mockInAppPurchaseBuilder.stubbedBuildResult
        }
    }

    func testBuildThrowsIfBundleIdIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            appVersionContainer(),
            originalAppVersionContainer(),
            opaqueValueContainer(),
            sha1HashContainer(),
            creationDateContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.to(throwError())
    }

    func testBuildThrowsIfAppVersionIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            bundleIdContainer(),
            originalAppVersionContainer(),
            opaqueValueContainer(),
            sha1HashContainer(),
            creationDateContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.to(throwError())
    }

    func testBuildDoesntThrowIfOriginalAppVersionIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            bundleIdContainer(),
            appVersionContainer(),
            opaqueValueContainer(),
            sha1HashContainer(),
            creationDateContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.notTo(throwError())
    }

    func testBuildThrowsIfOpaqueValueIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            bundleIdContainer(),
            appVersionContainer(),
            originalAppVersionContainer(),
            sha1HashContainer(),
            creationDateContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.to(throwError())
    }

    func testBuildThrowsIfSha1HashIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            bundleIdContainer(),
            appVersionContainer(),
            originalAppVersionContainer(),
            opaqueValueContainer(),
            creationDateContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.to(throwError())
    }

    func testBuildThrowsIfCreationDateIsMissing() {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [
            bundleIdContainer(),
            appVersionContainer(),
            originalAppVersionContainer(),
            opaqueValueContainer(),
            sha1HashContainer()
        ])
        expect { try self.appleReceiptBuilder.build(fromContainer: receiptContainer) }.to(throwError())
    }
}

private extension AppleReceiptBuilderTests {
    func minimalAttributes() -> [ASN1Container] {
        return [
            bundleIdContainer(),
            appVersionContainer(),
            originalAppVersionContainer(),
            opaqueValueContainer(),
            sha1HashContainer(),
            creationDateContainer()
        ]
    }

    func sampleReceiptContainerWithMinimalAttributes() -> ASN1Container {
        return containerFactory.receiptContainerFromContainers(containers: minimalAttributes())
    }
}

private extension AppleReceiptBuilderTests {

    func creationDateContainer() -> ASN1Container {
        containerFactory.receiptAttributeContainer(attributeType: ReceiptAttributeType.creationDate,
                                                   creationDate)
    }

    func sha1HashContainer() -> ASN1Container {
        containerFactory.receiptDataAttributeContainer(attributeType: ReceiptAttributeType.sha1Hash)
    }

    func opaqueValueContainer() -> ASN1Container {
        containerFactory.receiptDataAttributeContainer(attributeType: ReceiptAttributeType.opaqueValue)
    }

    func originalAppVersionContainer() -> ASN1Container {
        containerFactory.receiptAttributeContainer(attributeType: ReceiptAttributeType.originalApplicationVersion,
                                                   originalApplicationVersion)
    }

    func appVersionContainer() -> ASN1Container {
        containerFactory.receiptAttributeContainer(attributeType: ReceiptAttributeType.applicationVersion,
                                                   applicationVersion)
    }

    func bundleIdContainer() -> ASN1Container {
        containerFactory.receiptAttributeContainer(attributeType: ReceiptAttributeType.bundleId,
                                                   bundleId)
    }
}
