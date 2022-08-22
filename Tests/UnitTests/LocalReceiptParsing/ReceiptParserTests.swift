import Nimble
import XCTest

@testable import RevenueCat

class ReceiptParserTests: TestCase {
    var receiptParser: ReceiptParser!
    var mockAppleReceiptBuilder: MockAppleReceiptBuilder!
    var mockASN1ContainerBuilder: MockASN1ContainerBuilder!

    private let containerFactory = ContainerFactory()

    override func setUp() {
        super.setUp()
        mockAppleReceiptBuilder = MockAppleReceiptBuilder()
        mockASN1ContainerBuilder = MockASN1ContainerBuilder()
        receiptParser = ReceiptParser(containerBuilder: mockASN1ContainerBuilder,
                                      receiptBuilder: mockAppleReceiptBuilder)
    }

    func testParseFromReceiptDataBuildsContainerAfterObjectIdentifier() throws {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [])
        let dataObjectIdentifierContainer = containerFactory.objectIdentifierContainer(.data)
        let constructedContainer = containerFactory.constructedContainer(containers: [
            dataObjectIdentifierContainer,
            receiptContainer
        ])

        mockASN1ContainerBuilder.stubbedBuildResult = constructedContainer
        let expectedReceipt = mockAppleReceiptWithoutPurchases()
        mockAppleReceiptBuilder.stubbedBuildResult = expectedReceipt

        let receivedReceipt = try self.receiptParser.parse(from: Data())

        expect(self.mockAppleReceiptBuilder.invokedBuildCount) == 1
        expect(self.mockAppleReceiptBuilder.invokedBuildParameters) == receiptContainer
        expect(receivedReceipt) == expectedReceipt
    }

    func testParseFromReceiptDataBuildsContainerAfterObjectIdentifierInComplexContainer() throws {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [])
        let dataObjectIdentifierContainer = containerFactory.objectIdentifierContainer(.data)

        let complexContainer = containerFactory.constructedContainer(containers: [
            containerFactory.simpleDataContainer(),
            containerFactory.objectIdentifierContainer(.signedData),
            containerFactory.constructedContainer(containers: [
                containerFactory.simpleDataContainer(),
                containerFactory.intContainer(int: 656)
            ]),
            containerFactory.simpleDataContainer(),
            containerFactory.stringContainer(string: "some string"),
            containerFactory.constructedContainer(containers: [
                containerFactory.simpleDataContainer(),
                containerFactory.intContainer(int: 656),
                containerFactory.constructedContainer(containers: [
                    dataObjectIdentifierContainer,
                    receiptContainer
                ]),
                containerFactory.dateContainer(date: Date())
            ]),
            containerFactory.objectIdentifierContainer(.encryptedData)
        ])

        mockASN1ContainerBuilder.stubbedBuildResult = complexContainer
        let expectedReceipt = mockAppleReceiptWithoutPurchases()
        mockAppleReceiptBuilder.stubbedBuildResult = expectedReceipt

        let receivedReceipt = try self.receiptParser.parse(from: Data())

        expect(self.mockAppleReceiptBuilder.invokedBuildCount) == 1
        expect(self.mockAppleReceiptBuilder.invokedBuildParameters) == receiptContainer
        expect(receivedReceipt) == expectedReceipt
    }

    func testParseFromReceiptThrowsIfReceiptBuilderThrows() {
        let container = containerWithDataObjectIdentifier()

        mockASN1ContainerBuilder.stubbedBuildResult = container
        mockAppleReceiptBuilder.stubbedBuildError = ReceiptReadingError.receiptParsingError

        expect { try self.receiptParser.parse(from: Data()) }.to(throwError(ReceiptReadingError.receiptParsingError))
    }

    func testParseFromReceiptThrowsIfNoDataObjectIdentifierFound() {
        let container = containerFactory.constructedContainer(containers: [
            containerFactory.objectIdentifierContainer(.signedAndEnvelopedData),
            containerFactory.receiptContainerFromContainers(containers: [])
        ])

        mockASN1ContainerBuilder.stubbedBuildResult = container

        expect { try self.receiptParser.parse(from: Data()) }
            .to(throwError(ReceiptReadingError.dataObjectIdentifierMissing))
    }

    func testParseFromReceiptThrowsIfReceiptPayloadIsntLocatedAfterDataObjectIdentifierContainer() {
        let container = containerFactory.constructedContainer(containers: [
            containerFactory.receiptContainerFromContainers(containers: []),
            containerFactory.objectIdentifierContainer(.data)
        ])

        mockASN1ContainerBuilder.stubbedBuildResult = container

        expect { try self.receiptParser.parse(from: Data()) }
            .to(throwError(ReceiptReadingError.dataObjectIdentifierMissing))
    }

    func testReceiptHasTransactionsTrueIfReceiptHasTransactions() {
        mockASN1ContainerBuilder.stubbedBuildResult = containerWithDataObjectIdentifier()
        mockAppleReceiptBuilder.stubbedBuildResult = mockAppleReceiptWithPurchases()
        expect(self.receiptParser.receiptHasTransactions(receiptData: Data())) == true
    }

    func testReceiptHasTransactionsFalseIfNoIAPsInReceipt() {
        mockASN1ContainerBuilder.stubbedBuildResult = containerWithDataObjectIdentifier()
        mockAppleReceiptBuilder.stubbedBuildResult = mockAppleReceiptWithoutPurchases()
        expect(self.receiptParser.receiptHasTransactions(receiptData: Data())) == false
    }

    func testReceiptHasTransactionsTrueIfReceiptCantBeParsed() {
        mockASN1ContainerBuilder.stubbedBuildError = ReceiptReadingError.receiptParsingError
        expect(self.receiptParser.receiptHasTransactions(receiptData: Data())) == true
    }
}

private extension ReceiptParserTests {
    func containerWithDataObjectIdentifier() -> ASN1Container {
        let receiptContainer = containerFactory.receiptContainerFromContainers(containers: [])
        let dataObjectIdentifierContainer = containerFactory.objectIdentifierContainer(.data)
        let constructedContainer = containerFactory.constructedContainer(containers: [
            dataObjectIdentifierContainer,
            receiptContainer
        ])
        return constructedContainer
    }

    func mockAppleReceiptWithoutPurchases() -> AppleReceipt {
        return AppleReceipt(bundleId: "com.revenuecat.testapp",
                            applicationVersion: "3.2.3",
                            originalApplicationVersion: "3.1.1",
                            opaqueValue: Data(),
                            sha1Hash: Data(),
                            creationDate: Date(),
                            expirationDate: nil,
                            inAppPurchases: [])
    }

    func mockAppleReceiptWithPurchases() -> AppleReceipt {
        return AppleReceipt(bundleId: "com.revenuecat.testapp",
                            applicationVersion: "3.2.3",
                            originalApplicationVersion: "3.1.1",
                            opaqueValue: Data(),
                            sha1Hash: Data(),
                            creationDate: Date(),
                            expirationDate: nil,
                            inAppPurchases: [
                                InAppPurchase(quantity: 1,
                                              productId: "com.revenuecat.test",
                                              transactionId: "892398531",
                                              originalTransactionId: "892398531",
                                              productType: .autoRenewableSubscription,
                                              purchaseDate: Date(),
                                              originalPurchaseDate: Date(),
                                              expiresDate: nil,
                                              cancellationDate: Date(),
                                              isInTrialPeriod: false,
                                              isInIntroOfferPeriod: false,
                                              webOrderLineItemId: 79238531,
                                              promotionalOfferIdentifier: nil),
                                InAppPurchase(quantity: 1,
                                              productId: "com.revenuecat.test",
                                              transactionId: "892398532",
                                              originalTransactionId: "892398531",
                                              productType: .autoRenewableSubscription,
                                              purchaseDate: Date(),
                                              originalPurchaseDate: Date(),
                                              expiresDate: nil,
                                              cancellationDate: Date(),
                                              isInTrialPeriod: false,
                                              isInIntroOfferPeriod: false,
                                              webOrderLineItemId: 79238532,
                                              promotionalOfferIdentifier: nil)
                            ])
    }
}
