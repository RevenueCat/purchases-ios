import XCTest
import Nimble

import Purchases

class ProductInfoTests: XCTestCase {
    func testAsDictionaryConvertsProductIdentifierCorrectly() {
        let product_identifier = "cool_product"
        let productInfo = RCProductInfo(productIdentifier: product_identifier,
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["product_id"] as? String) == product_identifier
    }

    func testAsDictionaryConvertsPaymentModeCorrectly() {
        var paymentMode: RCPaymentMode = .none
        var productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: paymentMode,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["payment_mode"]).to(beNil())

        paymentMode = .payAsYouGo
        productInfo = RCProductInfo(productIdentifier: "cool_product",
                                    paymentMode: paymentMode,
                                    currencyCode: "UYU",
                                    price: 9.99,
                                    normalDuration: nil,
                                    introDuration: nil,
                                    introDurationType: .none,
                                    introPrice: nil,
                                    subscriptionGroup: nil,
                                    discounts: nil)
        var receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .freeTrial
        productInfo = RCProductInfo(productIdentifier: "cool_product",
                                    paymentMode: paymentMode,
                                    currencyCode: "UYU",
                                    price: 9.99,
                                    normalDuration: nil,
                                    introDuration: nil,
                                    introDurationType: .none,
                                    introPrice: nil,
                                    subscriptionGroup: nil,
                                    discounts: nil)
        receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .payUpFront
        productInfo = RCProductInfo(productIdentifier: "cool_product",
                                    paymentMode: paymentMode,
                                    currencyCode: "UYU",
                                    price: 9.99,
                                    normalDuration: nil,
                                    introDuration: nil,
                                    introDurationType: .none,
                                    introPrice: nil,
                                    subscriptionGroup: nil,
                                    discounts: nil)
        receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue
    }

    func testAsDictionaryConvertsCurrencyCodeCorrectly() {
        let currencyCode = "USD"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: currencyCode,
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["currency"] as? String) == currencyCode
    }

    func testAsDictionaryConvertsPriceCorrectly() {
        let price: NSDecimalNumber = 9.99
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: price,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["price"] as? NSDecimalNumber) == price
    }

    func testAsDictionaryConvertsNormalDurationCorrectly() {
        let normalDuration = "P3Y"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: normalDuration,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["normal_duration"] as? String) == normalDuration
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForFreeTrial() {
        let trialDuration = "P3M"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: trialDuration,
                                        introDurationType: .freeTrial,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["trial_duration"] as? String) == trialDuration
        expect(productInfo.asDictionary()["intro_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForIntroPrice() {
        let introDuration = "P3M"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: introDuration,
                                        introDurationType: .introPrice,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["intro_duration"] as? String) == introDuration
        expect(productInfo.asDictionary()["trial_duration"]).to(beNil())
    }

    func testAsDictionaryDoesntAddIntroDurationIfDurationTypeNone() {
        let introDuration = "P3M"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: introDuration,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["trial_duration"]).to(beNil())
        expect(productInfo.asDictionary()["trial_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroPriceCorrectly() {
        let introPrice: NSDecimalNumber = 6.99
        var productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: 6.99,
                                        subscriptionGroup: nil,
                                        discounts: nil)
        expect(productInfo.asDictionary()["introductory_price"] as? NSDecimalNumber) == introPrice
    }

    func testAsDictionaryConvertsSubscriptionGroupCorrectly() {
        let subscriptionGroup = "cool_group"
        let productInfo = RCProductInfo(productIdentifier: "cool_product",
                                        paymentMode: .none,
                                        currencyCode: "UYU",
                                        price: 9.99,
                                        normalDuration: nil,
                                        introDuration: nil,
                                        introDurationType: .none,
                                        introPrice: nil,
                                        subscriptionGroup: subscriptionGroup,
                                        discounts: nil)
        expect(productInfo.asDictionary()["subscription_group_id"] as? String) == subscriptionGroup
    }

    func testAsDictionaryConvertsDiscountsCorrectly() {
        
    }
}
