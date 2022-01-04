import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class ProductRequestDataTests: XCTestCase {
    func testAsDictionaryConvertsProductIdentifierCorrectly() throws {
        let productIdentifier = "cool_product"
        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier)
        expect(try productData.asDictionary()["product_id"] as? String) == productIdentifier
    }

    func testAsDictionaryConvertsPaymentModeCorrectly() throws {
        var paymentMode: PromotionalOffer.PaymentMode = .none
        var productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)
        expect(try productData.asDictionary()["payment_mode"]).to(beNil())

        paymentMode = .payAsYouGo
        productData = .createMockProductData(paymentMode: paymentMode)

        var receivedPaymentMode = (try productData.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .freeTrial
        productData = .createMockProductData(paymentMode: paymentMode)

        receivedPaymentMode = (try productData.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue

        paymentMode = .payUpFront
        productData = .createMockProductData(paymentMode: paymentMode)

        receivedPaymentMode = (try productData.asDictionary()["payment_mode"] as? NSNumber)?.intValue
        expect(receivedPaymentMode) == paymentMode.rawValue
    }

    func testAsDictionaryConvertsCurrencyCodeCorrectly() throws {
        let currencyCode = "USD"
        let productData: ProductRequestData = .createMockProductData(currencyCode: currencyCode)
        expect(try productData.asDictionary()["currency"] as? String) == currencyCode
    }

    func testAsDictionaryConvertsPriceCorrectly() throws {
        let price: NSDecimalNumber = 9.99
        let productData: ProductRequestData = .createMockProductData(price: price as Decimal)
        expect(try productData.asDictionary()["price"] as? String) == price.description
    }

    func testAsDictionaryConvertsNormalDurationCorrectly() throws {
        let normalDuration = "P3Y"
        let productData: ProductRequestData = .createMockProductData(normalDuration: normalDuration)
        expect(try productData.asDictionary()["normal_duration"] as? String) == normalDuration
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForFreeTrial() throws {
        let trialDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: trialDuration,
                                                                     introDurationType: .freeTrial)
        expect(try productData.asDictionary()["trial_duration"] as? String) == trialDuration
        expect(try productData.asDictionary()["intro_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForIntroPrice() throws {
        let introDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: introDuration,
                                                                     introDurationType: .payUpFront)
        expect(try productData.asDictionary()["intro_duration"] as? String) == introDuration
        expect(try productData.asDictionary()["trial_duration"]).to(beNil())
    }

    func testAsDictionaryDoesntAddIntroDurationIfDurationTypeNone() throws {
        let introDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: introDuration,
                                                                     introDurationType: .none)
        expect(try productData.asDictionary()["trial_duration"]).to(beNil())
        expect(try productData.asDictionary()["intro_duration"]).to(beNil())
    }

    func testAsDictionaryConvertsIntroPriceCorrectly() throws {
        let introPrice: NSDecimalNumber = 6.99
        let productData: ProductRequestData = .createMockProductData(introPrice: introPrice as Decimal)
        expect(try productData.asDictionary()["introductory_price"] as? String) == introPrice.description
    }

    func testAsDictionaryConvertsSubscriptionGroupCorrectly() {
        let subscriptionGroup = "cool_group"
        let productData: ProductRequestData = .createMockProductData(subscriptionGroup: subscriptionGroup)
        expect(try productData.asDictionary()["subscription_group_id"] as? String) == subscriptionGroup
    }

    func testAsDictionaryConvertsDiscountsCorrectly() throws {
        let discount1 = PromotionalOffer(offerIdentifier: "offerid1",
                                         price: 11.1,
                                         paymentMode: .payAsYouGo,
                                         subscriptionPeriod: .init(value: 1, unit: .month))

        let discount2 = PromotionalOffer(offerIdentifier: "offerid2",
                                         price: 12.2,
                                         paymentMode: .payUpFront,
                                         subscriptionPeriod: .init(value: 5, unit: .week))

        let discount3 = PromotionalOffer(offerIdentifier: "offerid3",
                                         price: 13.3,
                                         paymentMode: .freeTrial,
                                         subscriptionPeriod: .init(value: 3, unit: .month))

        let productData: ProductRequestData = .createMockProductData(discounts: [discount1, discount2, discount3])

        let dictionary = try productData.asDictionary()
        let receivedOffers = try XCTUnwrap(dictionary["offers"] as? [[String: NSObject]])

        expect(receivedOffers[0]["offer_identifier"] as? String) == discount1.offerIdentifier
        expect(receivedOffers[0]["price"] as? String) == discount1.price.description
        expect((receivedOffers[0]["payment_mode"] as? NSNumber)?.intValue) == discount1.paymentMode.rawValue

        expect(receivedOffers[1]["offer_identifier"] as? String) == discount2.offerIdentifier
        expect(receivedOffers[1]["price"] as? String) == discount2.price.description
        expect((receivedOffers[1]["payment_mode"] as? NSNumber)?.intValue) == discount2.paymentMode.rawValue

        expect(receivedOffers[2]["offer_identifier"] as? String) == discount3.offerIdentifier
        expect(receivedOffers[2]["price"] as? String) == discount3.price.description
        expect((receivedOffers[2]["payment_mode"] as? NSNumber)?.intValue) == discount3.paymentMode.rawValue
    }

    func testEncoding() throws {
        let discount1 = PromotionalOffer(offerIdentifier: "offerid1",
                                         price: 11.2,
                                         paymentMode: .payAsYouGo,
                                         subscriptionPeriod: .init(value: 1, unit: .month))

        let discount2 = PromotionalOffer(offerIdentifier: "offerid2",
                                         price: 12.2,
                                         paymentMode: .payUpFront,
                                         subscriptionPeriod: .init(value: 2, unit: .year))

        let discount3 = PromotionalOffer(offerIdentifier: "offerid3",
                                         price: 13.3,
                                         paymentMode: .freeTrial,
                                         subscriptionPeriod: .init(value: 3, unit: .day))

        let productData: ProductRequestData = .createMockProductData(productIdentifier: "cool_product",
                                                                     paymentMode: .payUpFront,
                                                                     currencyCode: "UYU",
                                                                     price: 49.99,
                                                                     normalDuration: "P3Y",
                                                                     introDuration: "P3W",
                                                                     introDurationType: .freeTrial,
                                                                     introPrice: 15.13,
                                                                     subscriptionGroup: "cool_group",
                                                                     discounts: [discount1, discount2, discount3])

        try assertSnapshot(matching: productData.asDictionary(), as: .json)
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

        let productData: ProductRequestData = .createMockProductData(productIdentifier: "cool_product",
                                                                     paymentMode: .payUpFront,
                                                                     currencyCode: "UYU",
                                                                     price: 49.99,
                                                                     normalDuration: "P3Y",
                                                                     introDuration: "P3W",
                                                                     introDurationType: .freeTrial,
                                                                     introPrice: 0,
                                                                     subscriptionGroup: "cool_group",
                                                                     discounts: [discount1, discount2, discount3])
        expect(productData.cacheKey) == "cool_product-49.99-UYU-1-0-cool_group-P3Y-P3W-2-offerid1-offerid2-offerid3"
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
            // swiftlint:disable:next force_try
            try! String(decoding: JSONSerialization.data(withJSONObject: data,
                                                         options: options), as: UTF8.self)
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }
}
