import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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

    func testPrice() {
        self.provider.localizedPrice = "$10.99"
        expect(self.process("Purchase for {{ price }}")) == "Purchase for $10.99"
    }

    func testPricePerMonth() {
        self.provider.localizedPricePerMonth = "$3.99"
        expect(self.process("{{ price_per_month }} per month")) == "$3.99 per month"
    }

    func testProductName() {
        self.provider.productName = "MindSnacks"
        expect(self.process("Purchase {{ product_name }}")) == "Purchase MindSnacks"
    }

    func testIntroDurationName() {
        self.provider.introductoryOfferDuration = "1 week"
        expect(self.process("Start {{ intro_duration }} trial")) == "Start 1 week trial"
    }

    func testMultipleVariables() {
        self.provider.productName = "Pro"
        self.provider.localizedPricePerMonth = "$1.99"
        expect(self.process("Unlock {{ product_name }} for {{ price_per_month }}")) == "Unlock Pro for $1.99"
    }

    func testHandlesUnknownVariablesGracefully() {
        expect(self.process("Purchase {{ unknown }}")) == "Purchase "
    }

    func testProcessesLocalizedConfiguration() {
        let configuration = PaywallData.LocalizedConfiguration(
            title: "Title {{ product_name }}",
            subtitle: "Price: {{ price }}",
            callToAction: "Unlock {{ product_name }} for {{ price_per_month }}",
            callToActionWithIntroOffer: "Start your {{ intro_duration }} free trial\n" +
            "Then {{ price_per_month }} every month",
            offerDetails: "Purchase for {{ price }}",
            offerDetailsWithIntroOffer: "Start your {{ intro_duration }} free trial\n" +
            "Then {{ price_per_month }} every month"
        )
        let processed = configuration.processVariables(with: TestData.packageWithIntroOffer)

        expect(processed.title) == "Title PRO monthly"
        expect(processed.subtitle) == "Price: $3.99"
        expect(processed.callToAction) == "Unlock PRO monthly for $3.99"
        expect(processed.callToActionWithIntroOffer) == "Start your 1 week free trial\nThen $3.99 every month"
        expect(processed.offerDetails) == "Purchase for $3.99"
        expect(processed.offerDetailsWithIntroOffer) == "Start your 1 week free trial\nThen $3.99 every month"
    }

}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension VariablesTests {

    func process(_ string: String) -> String {
        return VariableHandler.processVariables(in: string, with: self.provider)
    }

}

private struct MockVariableProvider: VariableDataProvider {

    var localizedPrice: String = ""
    var localizedPricePerMonth: String = ""
    var productName: String = ""
    var introductoryOfferDuration: String?

}
