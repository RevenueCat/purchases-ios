import XCTest
import Nimble

import Purchases

class ProductInfoExtractorTests: XCTestCase {

    func testExtractInfoFromProductExtractsProductIdentifier() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        let productInfoExtractor = RCProductInfoExtractor()

        let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.productIdentifier) == "cool_product"
    }

    func testExtractInfoFromProductExtractsPrice() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        product.mockPrice = NSDecimalNumber(decimal: 10.99)
        let productInfoExtractor = RCProductInfoExtractor()

        let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.price) == 10.99
    }

    func testExtractInfoFromProductExtractsCurrencyCode() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")
        product.mockPriceLocale = Locale(identifier: "es_UY")
        let productInfoExtractor = RCProductInfoExtractor()

        var receivedProductInfo = productInfoExtractor.extractInfo(from: product)

        expect(receivedProductInfo.currencyCode) == "UYU"

        product.mockPriceLocale = Locale(identifier: "en_US")
        receivedProductInfo = productInfoExtractor.extractInfo(from: product)
        expect(receivedProductInfo.currencyCode) == "USD"
    }

    func testExtractInfoFromProductExtractsPaymentMode() {
        let product = MockSKProduct(mockProductIdentifier: "cool_product")

        if #available(iOS 12.2, *) {
            let mockDiscount = MockDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount
            let productInfoExtractor = RCProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.paymentMode.rawValue) == RCPaymentMode.freeTrial.rawValue
        } else {
            let productInfoExtractor = RCProductInfoExtractor()

            let receivedProductInfo = productInfoExtractor.extractInfo(from: product)

            expect(receivedProductInfo.paymentMode).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroPrice() {
    }

    func testExtractInfoFromProductExtractsNormalDuration() {
    }

    func testExtractInfoFromProductExtractsIntroDuration() {
    }

    func testExtractInfoFromProductExtractsIntroDurationType() {
    }

    func testExtractInfoFromProductExtractsSubscriptionGroup() {
    }

    func testExtractInfoFromProductExtractsDiscounts() {
    }

    func testExtractInfoFromProductExtractsProductInfo() {
    }
}
