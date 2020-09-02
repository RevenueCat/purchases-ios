import XCTest
import Nimble

@testable import PurchasesCoreSwift

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
class IntroEligibilityCalculatorTests: XCTestCase {

    var calculator: IntroEligibilityCalculator!
    let mockProductsManager = MockProductsManager()
    let mockReceiptParser = MockReceiptParser()

    override func setUp() {
        super.setUp()
        calculator = IntroEligibilityCalculator(productsManager: mockProductsManager,
                                                receiptParser: mockReceiptParser)
    }

    func testCheckTrialOrIntroductoryPriceEligibilityReturnsEmptyIfNoProductIds() {
        var receivedError: Error? = nil
        var receivedEligibility: [String: NSNumber]? = nil
        var completionCalled = false
        calculator.checkTrialOrIntroductoryPriceEligibility(with: Data(),
                                                            productIdentifiers: Set()) { eligibilityByProductId,
                                                                                         error in
            completionCalled = true
            receivedError = error
            receivedEligibility = eligibilityByProductId
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility).toNot(beNil())
        expect(receivedEligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroductoryPriceEligibilityReturnsErrorIfReceiptParserThrows() {
        var receivedError: Error? = nil
        var receivedEligibility: [String: NSNumber]? = nil
        var completionCalled = false
        let productIdentifiers = Set(["com.revenuecat.test"])

        mockReceiptParser.stubbedParseError = ReceiptReadingError.receiptParsingError

        calculator.checkTrialOrIntroductoryPriceEligibility(with: Data(),
                                                            productIdentifiers: productIdentifiers) {
            eligibilityByProductId,
            error in
            completionCalled = true
            receivedError = error
            receivedEligibility = eligibilityByProductId
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(matchError(ReceiptReadingError.receiptParsingError))
        expect(receivedEligibility).toNot(beNil())
        expect(receivedEligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroductoryPriceEligibilityMakesOnlyOneProductsRequest() {
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let receiptIdentifiers = receipt.purchasedIntroOfferOrFreeTrialProductIdentifiers()

        mockProductsManager.stubbedProductsCompletionResult = Set(["a", "b"].map {
            MockSKProduct(mockProductIdentifier: $0)
        })

        let candidateIdentifiers = Set(["a", "b", "c"])
        calculator.checkTrialOrIntroductoryPriceEligibility(with: Data(),
                                                            productIdentifiers: Set(candidateIdentifiers)) { _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockProductsManager.invokedProductsCount) == 1
        expect(self.mockProductsManager.invokedProductsParameters) == candidateIdentifiers.union(receiptIdentifiers)
    }

    func testCheckTrialOrIntroductoryPriceEligibilityGetsCorrectResult() {
        var receivedError: Error? = nil
        var receivedEligibility: [String: NSNumber]? = nil
        var completionCalled = false

        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        mockProductsManager.stubbedProductsCompletionResult = Set([
                                                                      MockSKProduct(mockProductIdentifier: "com.revenuecat.product1",
                                                                                    mockSubscriptionGroupIdentifier: "group1"),
                                                                      MockSKProduct(mockProductIdentifier: "com.revenuecat.product2",
                                                                                    mockSubscriptionGroupIdentifier: "group2")
                                                                  ])

        let candidateIdentifiers = Set(["com.revenuecat.product1",
                                        "com.revenuecat.product2",
                                        "com.revenuecat.unknownProduct"])

        calculator.checkTrialOrIntroductoryPriceEligibility(with: Data(),
                                                            productIdentifiers: Set(candidateIdentifiers)) { eligibility, error in
            completionCalled = true
            receivedError = error
            receivedEligibility = eligibility
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
        expect(receivedEligibility) == [
            "com.revenuecat.product1": IntroEligibilityStatus.eligible.toNSNumber(),
            "com.revenuecat.product2": IntroEligibilityStatus.ineligible.toNSNumber(),
            "com.revenuecat.unknownProduct": IntroEligibilityStatus.unknown.toNSNumber(),
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
