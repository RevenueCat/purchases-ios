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

    func testPricePerMonth() {
        self.provider.localizedPricePerMonth = "$3.99"
        expect(self.process("{{ price_per_month }} per month")) == "$3.99 per month"
    }

    func testProductName() {
        self.provider.productName = "MindSnacks"
        expect(self.process("Purchase {{ product_name }}")) == "Purchase MindSnacks"
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
            subtitle: "Price: {{ price_per_month }}",
            callToAction: "Unlock {{ product_name }} for {{ price_per_month }}",
            offerDetails: "Purchase for {{ price_per_month }}"
        )
        let processed = configuration.processVariables(with: TestData.testPackage)

        expect(processed.title) == "Title PRO monthly"
        expect(processed.subtitle) == "Price: $3.99"
        expect(processed.callToAction) == "Unlock PRO monthly for $3.99"
        expect(processed.offerDetails) == "Purchase for $3.99"
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

    var localizedPricePerMonth: String = ""
    var productName: String = ""

}
