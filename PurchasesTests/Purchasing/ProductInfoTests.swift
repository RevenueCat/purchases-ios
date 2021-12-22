import XCTest
import Nimble
import SnapshotTesting

@testable import RevenueCat

class ProductInfoTests: XCTestCase {
    func testAsDictionaryConvertsProductIdentifierCorrectly() {
        let productIdentifier = "cool_product"
        let productInfo: ProductInfo = .createMockProductInfo(productIdentifier: productIdentifier)
        expect(productInfo.asDictionary()["product_id"] as? String) == productIdentifier
    }

    func testAsDictionaryConvertsPaymentModeCorrectly() {
        var paymentMode: PromotionalOffer.PaymentMode = .none
        var productInfo: ProductInfo = .createMockProductInfo(paymentMode: paymentMode)
        expect(productInfo.asDictionary()["payment_mode"]).to(beNil())

        paymentMode = .payAsYouGo
        productInfo = .createMockProductInfo(paymentMode: paymentMode)

        var receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .freeTrial
        productInfo = .createMockProductInfo(paymentMode: paymentMode)

        receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .payUpFront
        productInfo = .createMockProductInfo(paymentMode: paymentMode)

        receivedPaymentMode = (productInfo.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue
    }

    func testAsDictionaryConvertsCurrencyCodeCorrectly() {
        let currencyCode = "USD"
        let productInfo: ProductInfo = .createMockProductInfo(currencyCode: currencyCode)
        expect(productInfo.asDictionary()["currency"] as? String) == currencyCode
    }

    func testAsDictionaryConvertsPriceCorrectly() {
        let price: NSDecimalNumber = 9.99
        let productInfo: ProductInfo = .createMockProductInfo(price: price)
        expect(productInfo.asDictionary()["price"] as? NSDecimalNumber) == price
    }

    func testAsDictionaryConvertsNormalDurationCorrectly() {
        let normalDuration = "P3Y"
        let productInfo: ProductInfo = .createMockProductInfo(normalDuration: normalDuration)
        expect(productInfo.asDictionary()["normal_duration"] as? String) == normalDuration
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForFreeTrial() {
        let trialDuration = "P3M"
        let productInfo: ProductInfo = .createMockProductInfo(introDuration: trialDuration,
                                                                introDurationType: .freeTrial)
        expect(productInfo.asDictionary()["trial_duration"] as? String) == trialDuration
        expect(productInfo.asDictionary()["intro_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForIntroPrice() {
        let introDuration = "P3M"
        let productInfo: ProductInfo = .createMockProductInfo(introDuration: introDuration,
                                                                introDurationType: .introPrice)
        expect(productInfo.asDictionary()["intro_duration"] as? String) == introDuration
        expect(productInfo.asDictionary()["trial_duration"]).to(beNil())
    }

    func testAsDictionaryDoesntAddIntroDurationIfDurationTypeNone() {
        let introDuration = "P3M"
        let productInfo: ProductInfo = .createMockProductInfo(introDuration: introDuration,
                                                                introDurationType: .none)
        expect(productInfo.asDictionary()["trial_duration"]).to(beNil())
        expect(productInfo.asDictionary()["intro_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroPriceCorrectly() {
        let introPrice: NSDecimalNumber = 6.99
        let productInfo: ProductInfo = .createMockProductInfo(introPrice: 6.99)
        expect(productInfo.asDictionary()["introductory_price"] as? NSDecimalNumber) == introPrice
    }

    func testAsDictionaryConvertsSubscriptionGroupCorrectly() {
        let subscriptionGroup = "cool_group"
        let productInfo: ProductInfo = .createMockProductInfo(subscriptionGroup: subscriptionGroup)
        expect(productInfo.asDictionary()["subscription_group_id"] as? String) == subscriptionGroup
    }

    func testAsDictionaryConvertsDiscountsCorrectly() throws {
        guard #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) else { return }
        let discount1 = PromotionalOffer(offerIdentifier: "offerid1",
                                         price: 11,
                                         paymentMode: .payAsYouGo,
                                         subscriptionPeriod: .init(value: 1, unit: .month))
        
        let discount2 = PromotionalOffer(offerIdentifier: "offerid2",
                                         price: 12,
                                         paymentMode: .payUpFront,
                                         subscriptionPeriod: .init(value: 5, unit: .week))
        
        let discount3 = PromotionalOffer(offerIdentifier: "offerid3",
                                         price: 13,
                                         paymentMode: .freeTrial,
                                         subscriptionPeriod: .init(value: 3, unit: .month))
        
        let productInfo: ProductInfo = .createMockProductInfo(discounts: [discount1, discount2, discount3])
        
        expect(productInfo.asDictionary()["offers"] as? [[String: NSObject]]).toNot(beNil())
        let receivedOffers = try XCTUnwrap(productInfo.asDictionary()["offers"] as? [[String: NSObject]])

        expect(receivedOffers[0]["offer_identifier"] as? String) == discount1.offerIdentifier
        expect(receivedOffers[0]["price"] as? Decimal) == discount1.price
        expect((receivedOffers[0]["payment_mode"] as? NSNumber)?.intValue) == discount1.paymentMode.rawValue
        
        expect(receivedOffers[1]["offer_identifier"] as? String) == discount2.offerIdentifier
        expect(receivedOffers[1]["price"] as? Decimal) == discount2.price
        expect((receivedOffers[1]["payment_mode"] as? NSNumber)?.intValue) == discount2.paymentMode.rawValue
        
        expect(receivedOffers[2]["offer_identifier"] as? String) == discount3.offerIdentifier
        expect(receivedOffers[2]["price"] as? Decimal) == discount3.price
        expect((receivedOffers[2]["payment_mode"] as? NSNumber)?.intValue) == discount3.paymentMode.rawValue
        
    }
    
    func testEncoding() throws {
        let discount1 = PromotionalOffer(offerIdentifier: "offerid1",
                                         price: 11,
                                         paymentMode: .payAsYouGo,
                                         subscriptionPeriod: .init(value: 1, unit: .month))

        let discount2 = PromotionalOffer(offerIdentifier: "offerid2",
                                         price: 12,
                                         paymentMode: .payUpFront,
                                         subscriptionPeriod: .init(value: 2, unit: .year))

        let discount3 = PromotionalOffer(offerIdentifier: "offerid3",
                                         price: 13,
                                         paymentMode: .freeTrial,
                                         subscriptionPeriod: .init(value: 3, unit: .day))

        let productInfo: ProductInfo = .createMockProductInfo(productIdentifier: "cool_product",
                                                              paymentMode: .payUpFront,
                                                              currencyCode: "UYU",
                                                              price: 49.99,
                                                              normalDuration: "P3Y",
                                                              introDuration: "P3W",
                                                              introDurationType: .freeTrial,
                                                              introPrice: 0,
                                                              subscriptionGroup: "cool_group",
                                                              discounts: [discount1, discount2, discount3])

        try assertSnapshot(matching: productInfo.asDictionary(), as: .json)
    }

    func testCacheKey() {
        guard #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) else { return }
        
        let discount1 = PromotionalOffer(offerIdentifier: "offerid1",
                                         price: 11,
                                         paymentMode: .payAsYouGo,
                                         subscriptionPeriod: .init(value: 1, unit: .month))
        
        let discount2 = PromotionalOffer(offerIdentifier: "offerid2",
                                         price: 12,
                                         paymentMode: .payUpFront,
                                         subscriptionPeriod: .init(value: 2, unit: .year))
        
        let discount3 = PromotionalOffer(offerIdentifier: "offerid3",
                                         price: 13,
                                         paymentMode: .freeTrial,
                                         subscriptionPeriod: .init(value: 3, unit: .day))
        
        let productInfo: ProductInfo = .createMockProductInfo(productIdentifier: "cool_product",
                                                              paymentMode: .payUpFront,
                                                              currencyCode: "UYU",
                                                              price: 49.99,
                                                              normalDuration: "P3Y",
                                                              introDuration: "P3W",
                                                              introDurationType: .freeTrial,
                                                              introPrice: 0,
                                                              subscriptionGroup: "cool_group",
                                                              discounts: [discount1, discount2, discount3])
        expect(productInfo.cacheKey) == "cool_product-49.99-UYU-1-0-cool_group-P3Y-P3W-0-offerid1-offerid2-offerid3"
    }
}

// Remove once https://github.com/pointfreeco/swift-snapshot-testing/pull/552 is available in a release.
extension Snapshotting where Value == Any, Format == String {
    static var json: Snapshotting {
        let options: JSONSerialization.WritingOptions = [
            .prettyPrinted,
            .sortedKeys
        ]

        var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
            try! String(decoding: JSONSerialization.data(withJSONObject: data,
                                                         options: options), as: UTF8.self)
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }
}
