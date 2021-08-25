import XCTest
import Nimble
import StoreKit
@testable import PurchasesCoreSwift

class ProductInfoExtractorTests: XCTestCase {

    func testExtractInfoFromProductExtractsProductIdentifier() {
        let productID = "cool_product"
        let product = MockSKProduct(mockProductIdentifier: productID)
        let productInfoExtractor = ProductInfoExtractor()

        let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.productIdentifier) == productID
    }

    func testExtractInfoFromProductExtractsPrice() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        let price: NSDecimalNumber = 10.99
        product.mockPrice = price
        let productInfoExtractor = ProductInfoExtractor()

        let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.price) == price
    }

    func testExtractInfoFromProductExtractsCurrencyCode() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        product.mockPriceLocale = Locale(identifier: "es_UY")
        let productInfoExtractor = ProductInfoExtractor()

        var receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.currencyCode) == "UYU"

        product.mockPriceLocale = Locale(identifier: "en_US")
        receivedProductInfo = productInfoExtractor.extractInfo(from: product)
        expect(receivedProductInfo.currencyCode) == "USD"
    }

    func testExtractInfoFromProductExtractsPaymentMode() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.paymentMode.rawValue) == ProductInfo.PaymentMode.freeTrial.rawValue
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.paymentMode) == ProductInfo.PaymentMode.none
        }
    }

    func testExtractInfoFromProductExtractsIntroPrice() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPrice = 10.99

            product.mockDiscount = mockDiscount
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introPrice) == 10.99
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introPrice).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsNormalDuration() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 2, unit: .month)
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.normalDuration) == "P2M"
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductDoesNotExtractNormalDurationIfSubscriptionPeriodIsZero() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 0, unit: .month)
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.normalDuration).to(beNil())
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDuration() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)

            product.mockDiscount = mockDiscount
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introDuration) == "P3Y"
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDurationType() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 11.2, macOS 10.14.4, tvOS 11.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introDurationType) == .freeTrial
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.introDurationType) == IntroDurationType.none
        }
    }

    func testExtractInfoFromProductExtractsSubscriptionGroup() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        if #available(iOS 11.2, *) {
            let group = "mock_group"
            product.mockSubscriptionGroupIdentifier = group
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.subscriptionGroup) == group
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.subscriptionGroup).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsDiscounts() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 12.2, tvOS 12.2, macOS 10.13.2, *) {
            let mockDiscount = MockDiscount()
            let paymentMode: SKProductDiscount.PaymentMode = .freeTrial
            mockDiscount.mockPaymentMode = paymentMode
            let price: NSDecimalNumber = 10.99
            mockDiscount.mockPrice = price
            let discountID = "cool_discount"
            mockDiscount.mockIdentifier = discountID

            product.mockDiscount = mockDiscount
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.discounts?.count) == 1
            let receivedPromotionalOffer = receivedProductInfo.discounts?[0]
            expect(receivedPromotionalOffer?.offerIdentifier) == discountID
            expect(receivedPromotionalOffer?.price) == price
            expect(receivedPromotionalOffer?.paymentMode.rawValue) == Int(paymentMode.rawValue)
        } else {
            let productInfoExtractor = ProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.discounts).to(beNil())
        }
    }
}
