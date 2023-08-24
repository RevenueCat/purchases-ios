//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VariablesTests.swift

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class VariablesTests: TestCase {

    private var provider: MockVariableProvider!

    override func setUp() {
        super.setUp()

        self.provider = .init()
    }

    func testEmptyString() {
        expect(self.process("")) == ""
    }

    func testStringWithNoVariables() {
        expect(self.process("Hello")) == "Hello"
    }

    func testVariableWithNoSpaces() {
        expect(self.process("{{price_per_month}}")) == "{{price_per_month}}"
    }

    func testApplicationName() {
        self.provider.applicationName = "Paywalls"
        expect(self.process("Welcome to {{ app_name }}")) == "Welcome to Paywalls"
    }

    func testPrice() {
        self.provider.localizedPrice = "$10.99"
        expect(self.process("Purchase for {{ price }}")) == "Purchase for $10.99"
    }

    func testPricePerPeriod() {
        self.provider.localizedPricePerPeriod = "$3.99/yr"
        expect(self.process("{{ price_per_period }}")) == "$3.99/yr"
    }

    func testPricePerMonth() {
        self.provider.localizedPricePerMonth = "$3.99"
        expect(self.process("{{ sub_price_per_month }} per month")) == "$3.99 per month"
    }

    func testTotalPriceAndPerMonth() {
        self.provider.localizedPriceAndPerMonth = "$49.99 ($4.16/mth)"
        expect(self.process("{{ total_price_and_per_month }}")) == self.provider.localizedPriceAndPerMonth
    }

    func testProductName() {
        self.provider.productName = "MindSnacks"
        expect(self.process("Purchase {{ product_name }}")) == "Purchase MindSnacks"
    }

    func testPeriodName() {
        self.provider.periodName = "Monthly"
        expect(self.process("{{ sub_period }}")) == "Monthly"
    }

    func testSubscriptionDuration() {
        self.provider.subscriptionDuration = "1 month"
        expect(self.process("{{ sub_duration }}")) == "1 month"
    }

    func testIntroDurationName() {
        self.provider.introductoryOfferDuration = "1 week"
        expect(self.process("Start {{ sub_offer_duration }} trial")) == "Start 1 week trial"
    }

    func testIntroPrice() {
        self.provider.introductoryOfferPrice = "$4.99"
        expect(self.process("{{ sub_offer_price }}")) == self.provider.localizedIntroductoryOfferPrice
    }

    func testMultipleVariables() {
        self.provider.productName = "Pro"
        self.provider.localizedPricePerMonth = "$1.99"
        expect(self.process("Unlock {{ product_name }} for {{ sub_price_per_month }}")) == "Unlock Pro for $1.99"
    }

    func testHandlesUnknownVariablesGracefully() {
        expect(self.process("Purchase {{ unknown }}")) == "Purchase "
    }

    func testProcessesLocalizedConfiguration() {
        let configuration = PaywallData.LocalizedConfiguration(
            title: "Buy {{ product_name }} for {{ app_name }}",
            subtitle: "Price: {{ price }}",
            callToAction: "Unlock {{ product_name }} for {{ sub_price_per_month }}",
            callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial\n" +
            "Then {{ sub_price_per_month }} every month",
            offerDetails: "Purchase for {{ price }} every {{ sub_duration }}",
            offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} free trial\n" +
            "Then {{ sub_price_per_month }} every month",
            offerName: "{{ sub_period }}",
            features: [
                .init(title: "Purchase {{ product_name }}",
                      content: "Trial lasts {{ sub_offer_duration }}",
                      iconID: nil),
                .init(title: "Only {{ price }}",
                      content: "{{ sub_period }} subscription",
                      iconID: nil)
            ]
        )
        let processed = configuration.processVariables(with: TestData.packageWithIntroOffer)

        expect(processed.title) == "Buy PRO monthly for xctest"
        expect(processed.subtitle) == "Price: $3.99"
        expect(processed.callToAction) == "Unlock PRO monthly for $3.99"
        expect(processed.callToActionWithIntroOffer) == "Start your 1 week free trial\nThen $3.99 every month"
        expect(processed.offerDetails) == "Purchase for $3.99 every 1 month"
        expect(processed.offerDetailsWithIntroOffer) == "Start your 1 week free trial\nThen $3.99 every month"
        expect(processed.offerName) == "Monthly"
        expect(processed.features) == [
            .init(title: "Purchase PRO monthly",
                  content: "Trial lasts 1 week",
                  iconID: nil),
            .init(title: "Only $3.99",
                  content: "Monthly subscription",
                  iconID: nil)
        ]
    }

    // Note: this isn't perfect, but a warning is logged
    // and it's better than crashing.
    func testPricePerMonthForLifetimeProductsReturnsPrice() {
        let result = VariableHandler.processVariables(
            in: "{{ sub_price_per_month }}",
            with: TestData.lifetimePackage
        )
        expect(result) == "$119.49"
    }

    func testTotalPriceAndPerMonthForLifetimeProductsReturnsPrice() {
        let result = VariableHandler.processVariables(
            in: "{{ total_price_and_per_month }}",
            with: TestData.lifetimePackage
        )
        expect(result) == "$119.49"
    }

    func testTotalPriceAndPerMonthForForMonthlyPackage() {
        let result = VariableHandler.processVariables(
            in: "{{ total_price_and_per_month }}",
            with: TestData.monthlyPackage
        )
        expect(result) == "$6.99/mo"
    }

    func testTotalPriceAndPerMonthForCustomMonthlyProductsReturnsPrice() {
        let result = VariableHandler.processVariables(
            in: "{{ total_price_and_per_month }}",
            with: Package(
                identifier: "custom",
                packageType: .custom,
                storeProduct: TestData.monthlyProduct.toStoreProduct(),
                offeringIdentifier: ""
            )
        )
        expect(result) == "$6.99/mo"
    }

    func testTotalPriceAndPerMonthForCustomAnnualProductsReturnsPriceAndPerMonth() {
        let result = VariableHandler.processVariables(
            in: "{{ total_price_and_per_month }}",
            with: Package(
                identifier: "custom",
                packageType: .custom,
                storeProduct: TestData.annualProduct.toStoreProduct(),
                offeringIdentifier: ""
            )
        )
        expect(result) == "$53.99 ($4.49/mo)"
    }

    // MARK: - validation

    func testNoUnrecognizedVariables() {
        let allVariables = "{{ app_name }} {{ price }} {{ price_per_period }} " +
        "{{ total_price_and_per_month }} {{ product_name }} {{ sub_period }} " +
        "{{ sub_price_per_month }} {{ sub_duration }} {{ sub_offer_duration }} " +
        "{{ sub_offer_price }}"

        expect("".unrecognizedVariables()).to(beEmpty())
        expect(allVariables.unrecognizedVariables()).to(beEmpty())
    }

    func testUnrecognizedVariable() {
        expect("This contains {{ multiple }} unrecognized {{ variables }}".unrecognizedVariables()) == [
            "multiple",
            "variables"
        ]
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension VariablesTests {

    func process(_ string: String, locale: Locale = .current) -> String {
        return VariableHandler.processVariables(in: string, with: self.provider, locale: locale)
    }

}

private struct MockVariableProvider: VariableDataProvider {

    var applicationName: String = ""
    var localizedPrice: String = ""
    var localizedPricePerMonth: String = ""
    var localizedPriceAndPerMonth: String = ""
    var localizedPricePerPeriod: String = ""
    var productName: String = ""
    var periodName: String = ""
    var subscriptionDuration: String?
    var introductoryOfferDuration: String?
    var introductoryOfferPrice: String = ""

    func periodName(_ locale: Locale) -> String {
        return self.periodName
    }

    func subscriptionDuration(_ locale: Locale) -> String? {
        return self.subscriptionDuration
    }

    func introductoryOfferDuration(_ locale: Locale) -> String? {
        return self.introductoryOfferDuration
    }

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        return self.localizedPricePerPeriod
    }

    func localizedPriceAndPerMonth(_ locale: Locale) -> String {
        return self.localizedPriceAndPerMonth
    }

    var localizedIntroductoryOfferPrice: String? {
        return self.introductoryOfferPrice
    }

}
