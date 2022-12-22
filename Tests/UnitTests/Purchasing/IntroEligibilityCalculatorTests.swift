import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
class IntroEligibilityCalculatorTests: TestCase {

    private var calculator: IntroEligibilityCalculator!
    private var systemInfo: MockSystemInfo!
    private var mockProductsManager: MockProductsManager!
    private let mockReceiptParser = MockReceiptParser()

    override func setUpWithError() throws {
        try super.setUpWithError()

        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1")
        self.systemInfo = try MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)
        self.mockProductsManager = MockProductsManager(systemInfo: systemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.calculator = IntroEligibilityCalculator(productsManager: mockProductsManager,
                                                     receiptParser: mockReceiptParser)
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEmptyIfNoProductIds() {
        let result: (eligibility: [String: IntroEligibilityStatus], error: Error?)? = waitUntilValue { completed in
            self.calculator.checkEligibility(with: Data(),
                                             productIdentifiers: Set()) { eligibilityByProductId, error in
                completed((eligibilityByProductId, error))
            }
        }

        expect(result?.error).to(beNil())
        expect(result?.eligibility).toNot(beNil())
        expect(result?.eligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsErrorIfReceiptParserThrows() {
        let productIdentifiers = Set(["com.revenuecat.test"])

        self.mockReceiptParser.stubbedParseError = .receiptParsingError

        let result: (eligibility: [String: IntroEligibilityStatus], error: Error?)? = waitUntilValue { completed in
            self.calculator.checkEligibility(with: Data(),
                                             productIdentifiers: productIdentifiers) { eligibilityByProductId, error in
                completed((eligibilityByProductId, error))
            }
        }

        expect(result?.error).to(matchError(PurchasesReceiptParser.Error.receiptParsingError))
        expect(result?.eligibility).toNot(beNil())
        expect(result?.eligibility).to(beEmpty())
    }

    func testCheckTrialOrIntroDiscountEligibilityMakesOnlyOneProductsRequest() {
        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let receiptIdentifiers = receipt.activeSubscriptionProductIdentifiers

        mockProductsManager.stubbedProductsCompletionResult = .success(
            Set(
                ["a", "b"]
                    .map { MockSK1Product(mockProductIdentifier: $0) }
                    .map(StoreProduct.init(sk1Product:))
            )
        )

        let candidateIdentifiers = Set(["a", "b", "c"])
        waitUntil { completed in
            self.calculator.checkEligibility(with: Data(),
                                             productIdentifiers: Set(candidateIdentifiers)) { _, _ in
                completed()
            }
        }

        expect(self.mockProductsManager.invokedProductsCount) == 1
        expect(self.mockProductsManager.invokedProductsParameters) == candidateIdentifiers.union(receiptIdentifiers)
    }

    func testCheckTrialOrIntroDiscountEligibilityGetsCorrectResult() {
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
        let result: (eligibility: [String: IntroEligibilityStatus], error: Error?)? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: Set(candidateIdentifiers)
            ) { eligibilityByProductId, error in
                completed((eligibilityByProductId, error))
            }
        }

        expect(result?.error).to(beNil())
        expect(result?.eligibility) == [
            "com.revenuecat.product1": IntroEligibilityStatus.eligible,
            "com.revenuecat.product2": IntroEligibilityStatus.ineligible,
            "com.revenuecat.unknownProduct": IntroEligibilityStatus.unknown
        ]
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsIneligibleWithActiveSubscriptionInSameGroup() {
        let receipt = AppleReceipt(
            bundleId: "com.revenuecat.test",
            applicationVersion: "3.4.5",
            originalApplicationVersion: "3.2.1",
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: [
                .init(quantity: 1,
                      productId: "com.revenuecat.product2",
                      transactionId: "65465265651322",
                      originalTransactionId: "65465265651321",
                      productType: .autoRenewableSubscription,
                      purchaseDate: Date(),
                      originalPurchaseDate: Date(),
                      expiresDate: Date().addingTimeInterval(1000),
                      cancellationDate: nil,
                      isInTrialPeriod: false,
                      isInIntroOfferPeriod: false,
                      webOrderLineItemId: 64651321,
                      promotionalOfferIdentifier: nil)
            ]
        )
        self.mockReceiptParser.stubbedParseResult = receipt

        let product2 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product2",
                                      mockSubscriptionGroupIdentifier: "group1")
        let product3 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product3",
                                      mockSubscriptionGroupIdentifier: "group1")
        product3.mockDiscount = MockSKProductDiscount()
        let products = Set([product2, product3].map(StoreProduct.init(sk1Product:)))

        self.mockProductsManager.stubbedProductsCompletionResult = .success(products)

        let result: IntroEligibilityStatus? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: [product3.productIdentifier]
            ) { result, _ in
                completed(result[product3.productIdentifier])
            }
        }

        expect(result) == .ineligible
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEligibleWithExpiredSubscriptionInSameGroup() {
        let receipt = self.mockReceiptWithExpiredSubscription()
        self.mockReceiptParser.stubbedParseResult = receipt

        let product2 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product2",
                                      mockSubscriptionGroupIdentifier: "group1")
        let product3 = MockSK1Product(mockProductIdentifier: "com.revenuecat.product3",
                                      mockSubscriptionGroupIdentifier: "group1")
        product3.mockDiscount = MockSKProductDiscount()
        let products = Set([product2, product3].map(StoreProduct.init(sk1Product:)))

        self.mockProductsManager.stubbedProductsCompletionResult = .success(products)

        let result: IntroEligibilityStatus? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: [product3.productIdentifier]
            ) { result, _ in
                completed(result[product3.productIdentifier])
            }
        }

        expect(result) == .eligible
    }

    func testCheckTrialOrIntroDiscountEligibilityForProductWithoutIntroTrialReturnsNoIntroOfferExists() {
        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let mockProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.product1",
                                         mockSubscriptionGroupIdentifier: "group1")
        mockProduct.mockDiscount = nil
        mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: mockProduct)])

        let candidateIdentifiers = Set(["com.revenuecat.product1"])

        let result: (eligibility: [String: IntroEligibilityStatus], error: Error?)? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: Set(candidateIdentifiers)
            ) { eligibilityByProductId, error in
                completed((eligibilityByProductId, error))
            }
        }

        expect(result?.error).to(beNil())
        expect(result?.eligibility) == [
            "com.revenuecat.product1": IntroEligibilityStatus.noIntroOfferExists
        ]
    }

    func testCheckTrialOrIntroDiscountEligibilityForConsumableReturnsUnknown() {
        let receipt = mockReceipt()
        mockReceiptParser.stubbedParseResult = receipt
        let mockProduct = MockSK1Product(mockProductIdentifier: "lifetime",
                                         mockSubscriptionGroupIdentifier: "group1")
        mockProduct.mockDiscount = nil
        mockProduct.mockSubscriptionPeriod = nil
        mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: mockProduct)])

        let candidateIdentifiers = Set(["lifetime"])

        let result: (eligibility: [String: IntroEligibilityStatus], error: Error?)? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: Set(candidateIdentifiers)
            ) { eligibilityByProductId, error in
                completed((eligibilityByProductId, error))
            }
        }

        expect(result?.error).to(beNil())
        expect(result?.eligibility) == [
            "lifetime": IntroEligibilityStatus.unknown
        ]
    }
}

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
private extension IntroEligibilityCalculatorTests {

    func mockInAppPurchases() -> [AppleReceipt.InAppPurchase] {
        return [
            .init(quantity: 1,
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
            .init(quantity: 1,
                  productId: "com.revenuecat.product2",
                  transactionId: "65465265651322",
                  originalTransactionId: "65465265651321",
                  productType: .autoRenewableSubscription,
                  purchaseDate: Date(),
                  originalPurchaseDate: Date(),
                  expiresDate: Date().addingTimeInterval(1000),
                  cancellationDate: nil,
                  isInTrialPeriod: false,
                  isInIntroOfferPeriod: false,
                  webOrderLineItemId: 64651321,
                  promotionalOfferIdentifier: nil),
            .init(quantity: 1,
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

    func mockInAppPurchasesWithExpiredSubscription() -> [AppleReceipt.InAppPurchase] {
        return [
            .init(quantity: 1,
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
            .init(quantity: 1,
                  productId: "com.revenuecat.product2",
                  transactionId: "65465265651322",
                  originalTransactionId: "65465265651321",
                  productType: .autoRenewableSubscription,
                  purchaseDate: Date(),
                  originalPurchaseDate: Date(),
                  expiresDate: Date().addingTimeInterval(-1000),
                  cancellationDate: nil,
                  isInTrialPeriod: true,
                  isInIntroOfferPeriod: false,
                  webOrderLineItemId: 64651321,
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

    func mockReceiptWithExpiredSubscription() -> AppleReceipt {
        return AppleReceipt(bundleId: "com.revenuecat.test",
                            applicationVersion: "3.4.5",
                            originalApplicationVersion: "3.2.1",
                            opaqueValue: Data(),
                            sha1Hash: Data(),
                            creationDate: Date(),
                            expirationDate: nil,
                            inAppPurchases: self.mockInAppPurchasesWithExpiredSubscription())
    }

}
