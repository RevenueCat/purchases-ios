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
        self.systemInfo = MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)
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
        expect(self.mockProductsManager.invokedProductsParameters) == candidateIdentifiers
            .union(receipt.activeSubscriptionsProductIdentifiers)
    }

    func testCheckTrialOrIntroDiscountEligibilityGetsCorrectResult() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                (productID: "com.revenuecat.product1", expiration: nil, inTrial: false),
                (productID: "com.revenuecat.product2", expiration: Date().addingTimeInterval(1000), inTrial: false),
                (productID: "com.revenuecat.product2", expiration: Date(), inTrial: false)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: "group1", hasTrial: true),
                "com.revenuecat.product2": (groupID: "group2", hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product1": .eligible,
                "com.revenuecat.product2": .ineligible,
                "com.revenuecat.unknown": .unknown
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsIneligibleForPreviouslyOwnedSubscription() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", Date().addingTimeInterval(-1000), true)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: "group1", hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product1": .ineligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEligibleForPreviouslyOwnedSubscriptionWithUnusedTrial() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", Date().addingTimeInterval(-1000), false)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: "group1", hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product1": .eligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEligibleForPreviouslyOwnedSubscriptionInDifferentGroup() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                "com.revenuecat.product1": Date().addingTimeInterval(-1000)
            ],
            productsInGroups: [
                "com.revenuecat.product1": "group1",
                "com.revenuecat.product3": "group2"
            ],
            expectedResult: [
                "com.revenuecat.product3": .eligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsIneligibleWithActiveSubscriptionInSameGroup() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                "com.revenuecat.product2": Date().addingTimeInterval(1000)
            ],
            productsInGroups: [
                "com.revenuecat.product2": "group1",
                "com.revenuecat.product3": "group1"
            ],
            expectedResult: [
                "com.revenuecat.product3": .ineligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEligibleWithActiveSubscriptionInDifferentGroup() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                "com.revenuecat.product2": Date().addingTimeInterval(1000)
            ],
            productsInGroups: [
                "com.revenuecat.product2": "group1",
                "com.revenuecat.product3": "group2"
            ],
            expectedResult: [
                "com.revenuecat.product3": .eligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsEligibleWithExpiredSubscriptionWithNoTrialInSameGroup() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", nil, false),
                ("com.revenuecat.product2", Date().addingTimeInterval(-1000), false)
            ],
            productsInGroups: [
                "com.revenuecat.product2": (groupID: "group1", hasTrial: true),
                "com.revenuecat.product3": (groupID: "group1", hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product3": .eligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityReturnsIneligibleWithExpiredSubscriptionWithTrialInSameGroup() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", nil, false),
                ("com.revenuecat.product2", Date().addingTimeInterval(-1000), true)
            ],
            productsInGroups: [
                "com.revenuecat.product2": (groupID: "group1", hasTrial: true),
                "com.revenuecat.product3": (groupID: "group1", hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product3": .ineligible
            ]
        )
    }

    func testCheckTrialOrIntroDiscountEligibilityForProductWithoutIntroTrialReturnsNoIntroOfferExists() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", nil, false)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: "group1", hasTrial: false)
            ],
            expectedResult: [
                "com.revenuecat.product1": .noIntroOfferExists
            ]
        )
    }

    func testCheckTrialEligibilityReturnsIneligibleForProductWithNoSubscriptionGroupAndActiveSubscription() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                "com.revenuecat.product1": Date().addingTimeInterval(1000)
            ],
            productsInGroups: [
                "com.revenuecat.product1": nil
            ],
            expectedResult: [
                "com.revenuecat.product1": .ineligible
            ]
        )
    }

    func testCheckTrialEligibilityReturnsEligibleForProductWithNoSubscriptionGroupAndExpiredSubscriptionWithNoTrial() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", Date().addingTimeInterval(-1000), false)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: nil, hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product1": .eligible
            ]
        )
    }

    func testCheckTrialEligibilityReturnsIneligibleForProductWithNoSubscriptionGroupAndExpiredSubscriptionWithTrial() {
        self.testEligibility(
            purchaseExpirationsByProductIdentifier: [
                ("com.revenuecat.product1", Date().addingTimeInterval(-1000), true)
            ],
            productsInGroups: [
                "com.revenuecat.product1": (groupID: nil, hasTrial: true)
            ],
            expectedResult: [
                "com.revenuecat.product1": .ineligible
            ]
        )
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

    func testEligibility(
        purchaseExpirationsByProductIdentifier: [String: Date?],
        productsInGroups: [String: String?],
        expectedResult: [String: IntroEligibilityStatus],
        file: FileString = #file,
        line: UInt = #line
    ) {
        return self.testEligibility(
            purchaseExpirationsByProductIdentifier: purchaseExpirationsByProductIdentifier.map { ($0, $1, false) },
            productsInGroups: productsInGroups.mapValues { (groupID: $0, hasTrial: true) },
            expectedResult: expectedResult,
            file: file,
            line: line
        )
    }

    func testEligibility(
        purchaseExpirationsByProductIdentifier: [(productID: String, expiration: Date?, inTrial: Bool)],
        productsInGroups: [String: (groupID: String?, hasTrial: Bool)],
        expectedResult: [String: IntroEligibilityStatus],
        file: FileString = #file,
        line: UInt = #line
    ) {
        let receipt = AppleReceipt(
            bundleId: "com.revenuecat.test",
            applicationVersion: "3.4.5",
            originalApplicationVersion: "3.2.1",
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: purchaseExpirationsByProductIdentifier
                .map { productIdentifier, expiration, inTrial in
                        .init(quantity: 1,
                              productId: productIdentifier,
                              transactionId: "65465265651322",
                              originalTransactionId: "65465265651321",
                              productType: .autoRenewableSubscription,
                              purchaseDate: Date(),
                              originalPurchaseDate: Date(),
                              expiresDate: expiration,
                              cancellationDate: nil,
                              isInTrialPeriod: inTrial,
                              isInIntroOfferPeriod: inTrial,
                              webOrderLineItemId: 64651321,
                              promotionalOfferIdentifier: nil)
                }
        )
        self.mockReceiptParser.stubbedParseResult = receipt

        let products = productsInGroups
            .map { productID, group in
                let product = MockSK1Product(mockProductIdentifier: productID,
                                             mockSubscriptionGroupIdentifier: group.groupID)
                if group.hasTrial {
                    product.mockDiscount = MockSKProductDiscount()
                }

                return product
            }
            .map(StoreProduct.init(sk1Product:))

        self.mockProductsManager.stubbedProductsCompletionResult = .success(Set(products))

        let result: [String: IntroEligibilityStatus]? = waitUntilValue { completed in
            self.calculator.checkEligibility(
                with: Data(),
                productIdentifiers: Set(expectedResult.keys)
            ) { result, error in
                expect(error).to(beNil())
                completed(result)
            }
        }

        expect(file: file, line: line, result) == expectedResult
    }

    func testEligibilityStatusIsEligible() {
        expect(IntroEligibilityStatus.unknown.isEligible) == false
        expect(IntroEligibilityStatus.ineligible.isEligible) == false
        expect(IntroEligibilityStatus.noIntroOfferExists.isEligible) == false
        expect(IntroEligibilityStatus.eligible.isEligible) == true
    }

    func mockReceipt() -> AppleReceipt {
        return AppleReceipt(bundleId: "com.revenuecat.test",
                            applicationVersion: "3.4.5",
                            originalApplicationVersion: "3.2.1",
                            opaqueValue: Data(),
                            sha1Hash: Data(),
                            creationDate: Date(),
                            expirationDate: nil,
                            inAppPurchases: [
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
                            ])
    }

}
