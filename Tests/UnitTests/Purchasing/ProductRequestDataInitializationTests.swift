import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

// swiftlint:disable:next type_name
class ProductRequestDataSK1ProductInitializationTests: TestCase {

    private var product: MockSK1Product!
    private var storefront: MockStorefront!

    private static let productID = "cool_product"
    private static let storefrontCountryCode = "ESP"

    override func setUp() {
        super.setUp()

        self.product = MockSK1Product(mockProductIdentifier: Self.productID)
        self.storefront = MockStorefront(countryCode: Self.storefrontCountryCode)
    }

    private func extract() -> ProductRequestData {
        return ProductRequestData(with: StoreProduct(sk1Product: self.product), storefront: self.storefront)
    }

    func testExtractInfoFromProductExtractsProductIdentifier() {
        let receivedProductData = self.extract()

        expect(receivedProductData.productIdentifier) == Self.productID
    }

    func testExtractInfoFromProductExtractsStorefrontCountryCode() {
        let receivedProductData = self.extract()

        expect(receivedProductData.storefront?.countryCode) == Self.storefrontCountryCode
    }

    func testExtractInfoFromProductExtractsPrice() {
        let price: Decimal = 10.99
        product.mockPrice = price

        let receivedProductData = self.extract()

        expect(receivedProductData.price) == price
    }

    func testExtractInfoFromProductExtractsCurrencyCode() {
        product.mockPriceLocale = Locale(identifier: "es_UY")

        var receivedProductData = self.extract()

        expect(receivedProductData.currencyCode) == "UYU"

        product.mockPriceLocale = Locale(identifier: "en_US")
        receivedProductData = self.extract()
        expect(receivedProductData.currencyCode) == "USD"
    }

    func testExtractInfoFromProductExtractsPaymentMode() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockSKProductDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount

            let receivedProductData = self.extract()

            expect(receivedProductData.paymentMode) == .freeTrial
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.paymentMode).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroPrice() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockSKProductDiscount()
            mockDiscount.mockPrice = 10.99

            product.mockDiscount = mockDiscount

            let receivedProductData = self.extract()

            expect(receivedProductData.introPrice) == 10.99
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.introPrice).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsNormalDuration() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 2, unit: .month)

            let receivedProductData = self.extract()

            expect(receivedProductData.normalDuration) == "P2M"
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductDoesNotExtractNormalDurationIfSubscriptionPeriodIsZero() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 0, unit: .month)
            let receivedProductData = self.extract()

            expect(receivedProductData.normalDuration).to(beNil())
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.normalDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDuration() {
        if #available(iOS 11.2, tvOS 11.2, macOS 10.13.2, *) {
            let mockDiscount = MockSKProductDiscount()
            mockDiscount.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)

            product.mockDiscount = mockDiscount

            let receivedProductData = self.extract()

            expect(receivedProductData.introDuration) == "P3Y"
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.introDuration).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsIntroDurationType() {
        if #available(iOS 11.2, macOS 10.14.4, tvOS 11.2, *) {
            let mockDiscount = MockSKProductDiscount()
            mockDiscount.mockPaymentMode = .freeTrial

            product.mockDiscount = mockDiscount
            let receivedProductData = self.extract()

            expect(receivedProductData.introDurationType) == .freeTrial
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.introDurationType).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsSubscriptionGroup() {
        if #available(iOS 12.0, macCatalyst 13.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *) {
            let group = "mock_group"
            product.mockSubscriptionGroupIdentifier = group

            let receivedProductData = self.extract()

            expect(receivedProductData.subscriptionGroup) == group
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.subscriptionGroup).to(beNil())
        }
    }

    func testExtractInfoFromProductExtractsDiscounts() {
        if #available(iOS 12.2, tvOS 12.2, macOS 10.13.2, *) {
            let mockDiscount = MockSKProductDiscount()
            let paymentMode: SKProductDiscount.PaymentMode = .freeTrial
            mockDiscount.mockPaymentMode = paymentMode
            let price: Decimal = 10.99
            mockDiscount.mockPrice = price
            let discountID = "cool_discount"
            mockDiscount.mockIdentifier = discountID

            product.mockDiscount = mockDiscount
            let receivedProductData = self.extract()

            expect(receivedProductData.discounts?.count) == 1
            let receivedPromotionalOffer = receivedProductData.discounts?[0]
            expect(receivedPromotionalOffer?.offerIdentifier) == discountID
            expect(receivedPromotionalOffer?.price) == price
            expect(receivedPromotionalOffer?.paymentMode.rawValue) == Int(paymentMode.rawValue)
        } else {
            let receivedProductData = self.extract()

            expect(receivedProductData.discounts).to(beNil())
        }
    }
}
