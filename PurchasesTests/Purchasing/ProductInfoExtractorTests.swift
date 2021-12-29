import XCTest
import Nimble
import StoreKit
@testable import RevenueCat

class ProductInfoExtractorTests: XCTestCase {

    private var product: MockSK1Product!

    private static let productID = "cool_product"

    override func setUp() {
        self.product = MockSK1Product(mockProductIdentifier: Self.productID)
    }

    private func extract() -> ProductInfo {
        return ProductInfoExtractor.extractInfo(from: self.product)
    }

    func testExtractInfoFromProductExtractsProductIdentifier() {
        let receivedProductInfo = self.extract()

        expect(receivedProductInfo.productIdentifier) == Self.productID
    }

    func testExtractInfoFromProductExtractsPrice() {
        let price: Decimal = 10.99
        product.mockPrice = price

        let receivedProductInfo = self.extract()

        expect(receivedProductInfo.price) == price
    }

    func testExtractInfoFromProductExtractsCurrencyCode() {
        product.mockPriceLocale = Locale(identifier: "es_UY")

        var receivedProductInfo = self.extract()

        expect(receivedProductInfo.currencyCode) == "UYU"

        product.mockPriceLocale = Locale(identifier: "en_US")
        receivedProductInfo = self.extract()
        expect(receivedProductInfo.currencyCode) == "USD"
    }

    func testExtractInfoFromProductExtractsPaymentMode() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount

            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.paymentMode.rawValue) == PromotionalOffer.PaymentMode.freeTrial.rawValue
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.paymentMode) == PromotionalOffer.PaymentMode.none
        }
    }

    func testExtractInfoFromProductExtractsIntroPrice() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPrice = 10.99

            product.mockDiscount = mockDiscount

            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introPrice) == 10.99
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introPrice).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsNormalDuration() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 2, unit: .month)

            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.normalDuration) == "P2M"
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductDoesNotExtractNormalDurationIfSubscriptionPeriodIsZero() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 0, unit: .month)
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.normalDuration).to(beNil())
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDuration() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)

            product.mockDiscount = mockDiscount

            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introDuration) == "P3Y"
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDurationType() {
        if #available(iOS 11.2, macOS 10.14.4, tvOS 11.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introDurationType) == .freeTrial
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.introDurationType) == PromotionalOffer.PaymentMode.none
        }
    }

    func testExtractInfoFromProductExtractsSubscriptionGroup() {
        if #available(iOS 12.0, macCatalyst 13.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *) {
            let group = "mock_group"
            product.mockSubscriptionGroupIdentifier = group

            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.subscriptionGroup) == group
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.subscriptionGroup).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsDiscounts() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            let paymentMode: SKProductDiscount.PaymentMode = .freeTrial
            mockDiscount.mockPaymentMode = paymentMode
            let price: Decimal = 10.99
            mockDiscount.mockPrice = price
            let discountID = "cool_discount"
            mockDiscount.mockIdentifier = discountID

            product.mockDiscount = mockDiscount
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.discounts?.count) == 1
            let receivedPromotionalOffer = receivedProductInfo.discounts?[0]
            expect(receivedPromotionalOffer?.offerIdentifier) == discountID
            expect(receivedPromotionalOffer?.price) == price
            expect(receivedPromotionalOffer?.paymentMode.rawValue) == Int(paymentMode.rawValue)
        } else {
            let receivedProductInfo = self.extract()

            expect(receivedProductInfo.discounts).to(beNil())
        }
    }
}
