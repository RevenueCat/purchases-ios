import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
class IntroEligibilityCalculatorTests: TestCase {

    var calculator: IntroEligibilityCalculator!
    var systemInfo: MockSystemInfo!
    var mockProductsManager: MockProductsManager!
    let mockReceiptParser = MockReceiptParser()

    override func setUpWithError() throws {
        try super.setUpWithError()
        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1")
        systemInfo = try MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)
        self.mockProductsManager = MockProductsManager(systemInfo: systemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        calculator = IntroEligibilityCalculator(productsManager: mockProductsManager,
                                                receiptParser: mockReceiptParser)
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEmptyIfNoProductIds() {
        var receivedError: Error?
        var receivedEligibility: [String: IntroEligibilityStatus]?
        var completionCalled = false
        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: Set()) { eligibilityByProductId, error in
            receivedError = error
            receivedEligibility = eligibilityByProductId
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility).toNot(beNil())
        expect(receivedEligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsErrorIfReceiptParserThrows() {
        var receivedError: Error?
        var receivedEligibility: [String: IntroEligibilityStatus]?
        var completionCalled = false
        let productIdentifiers = Set(["com.revenuecat.test"])

        mockReceiptParser.stubbedParseError = ReceiptReadingError.receiptParsingError

        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: productIdentifiers) { eligibilityByProductId, error in
            receivedError = error
            receivedEligibility = eligibilityByProductId
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(matchError(ReceiptReadingError.receiptParsingError))
        expect(receivedEligibility).toNot(beNil())
        expect(receivedEligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroDiscountEligibilityMakesOnlyOneProductsRequest() {
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let receiptIdentifiers = receipt.purchasedIntroOfferOrFreeTrialProductIdentifiers()

        mockProductsManager.stubbedProductsCompletionResult = .success(
            Set(
                ["a", "b"]
                    .map { MockSK1Product(mockProductIdentifier: $0) }
                    .map(StoreProduct.init(sk1Product:))
            )
        )

        let candidateIdentifiers = Set(["a", "b", "c"])
        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: Set(candidateIdentifiers)) { _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockProductsManager.invokedProductsCount) == 1
        expect(self.mockProductsManager.invokedProductsParameters) == candidateIdentifiers.union(receiptIdentifiers)
    }

    func testCheckTrialOrIntroDiscountEligibilityGetsCorrectResult() {
        var receivedError: Error?
        var receivedEligibility: [String: IntroEligibilityStatus]?
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt

        let product1 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product1",
                                      mockSubscriptionGroupIdentifier: "group1")
        product1.mockDiscount = MockSKProductDiscount()
        let product2 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product2",
                                      mockSubscriptionGroupIdentifier: "group2")
        product2.mockDiscount = MockSKProductDiscount()

        mockProductsManager.stubbedProductsCompletionResult = .success(
            Set([product1, product2].map(StoreProduct.init(sk1Product:)))
        )

        let candidateIdentifiers = Set(["com.revenuecat.product1",
                                        "com.revenuecat.product2",
                                        "com.revenuecat.unknownProduct"])

        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: Set(candidateIdentifiers)) { eligibility, error in
            receivedError = error
            receivedEligibility = eligibility
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility) == [
            "com.revenuecat.product1": IntroEligibilityStatus.eligible,
            "com.revenuecat.product2": IntroEligibilityStatus.ineligible,
            "com.revenuecat.unknownProduct": IntroEligibilityStatus.unknown
        ]
    }

    func testCheckTrialOrIntroDiscountEligibilityForProductWithoutIntroTrialReturnsNoIntroOfferExists() {
        var receivedError: Error?
        var receivedEligibility: [String: IntroEligibilityStatus]?
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let mockProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.product1",
                                         mockSubscriptionGroupIdentifier: "group1")
        mockProduct.mockDiscount = nil
        mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: mockProduct)])

        let candidateIdentifiers = Set(["com.revenuecat.product1"])

        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: Set(candidateIdentifiers)) { eligibility, error in
            receivedError = error
            receivedEligibility = eligibility
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility) == [
            "com.revenuecat.product1": IntroEligibilityStatus.noIntroOfferExists
        ]
    }

    func testCheckTrialOrIntroDiscountEligibilityForConsumableReturnsUnknown() {
        var receivedError: Error?
        var receivedEligibility: [String: IntroEligibilityStatus]?
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let mockProduct = MockSK1Product(mockProductIdentifier: "lifetime",
                                         mockSubscriptionGroupIdentifier: "group1")
        mockProduct.mockDiscount = nil
        mockProduct.mockSubscriptionPeriod = nil
        mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: mockProduct)])

        let candidateIdentifiers = Set(["lifetime"])

        calculator.checkEligibility(with: Data(),
                                    productIdentifiers: Set(candidateIdentifiers)) { eligibility, error in
            receivedError = error
            receivedEligibility = eligibility
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility) == [
            "lifetime": IntroEligibilityStatus.unknown
        ]
    }
}

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
private extension IntroEligibilityCalculatorTests {
    func mockInAppPurchases() -> [InAppPurchase] {
        return [
            InAppPurchase(quantity: 1,
                          productId: "com.revenuecat.product1",
                          transactionId: "65465265651323",
                          originalTransactionId: "65465265651323",
                          productType: .consumable,
                          purchaseDate: Date(),
                          originalPurchaseDate: Date(),
                          expiresDate: nil,
                          cancellationDate: nil,
                          isInTrialPeriod: false,
                          isInIntroOfferPeriod: false,
                          webOrderLineItemId: 516854313,
                          promotionalOfferIdentifier: nil),
            InAppPurchase(quantity: 1,
                          productId: "com.revenuecat.product2",
                          transactionId: "65465265651322",
                          originalTransactionId: "65465265651321",
                          productType: .autoRenewableSubscription,
                          purchaseDate: Date(),
                          originalPurchaseDate: Date(),
                          expiresDate: Date(),
                          cancellationDate: nil,
                          isInTrialPeriod: false,
                          isInIntroOfferPeriod: false,
                          webOrderLineItemId: 64651321,
                          promotionalOfferIdentifier: nil),
            InAppPurchase(quantity: 1,
                          productId: "com.revenuecat.product2",
                          transactionId: "65465265651321",
                          originalTransactionId: "65465265651321",
                          productType: .autoRenewableSubscription,
                          purchaseDate: Date(),
                          originalPurchaseDate: Date(),
                          expiresDate: Date(),
                          cancellationDate: nil,
                          isInTrialPeriod: true,
                          isInIntroOfferPeriod: false,
                          webOrderLineItemId: 64651320,
                          promotionalOfferIdentifier: nil)
        ]
    }

    func mockReceipt() -> AppleReceipt {
        return AppleReceipt(bundleId: "com.revenuecat.test",
                            applicationVersion: "3.4.5",
                            originalApplicationVersion: "3.2.1",
                            opaqueValue: Data(),
                            sha1Hash: Data(),
                            creationDate: Date(),
                            expirationDate: nil,
                            inAppPurchases: mockInAppPurchases())
    }
}
