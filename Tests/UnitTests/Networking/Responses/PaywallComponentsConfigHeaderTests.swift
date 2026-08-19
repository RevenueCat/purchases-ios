import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

class PaywallComponentsConfigHeaderTests: TestCase {

    private let backgroundJSON = """
    {
        "type": "color",
        "value": {
            "light": {
                "type": "hex",
                "value": "#FFFFFF"
            }
        }
    }
    """

    private let stackJSON = """
    {
        "type": "stack",
        "dimension": {
            "type": "vertical",
            "alignment": "center",
            "distribution": "start"
        },
        "size": {
            "width": { "type": "fill" },
            "height": { "type": "fit" }
        },
        "padding": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "margin": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "components": []
    }
    """

    func testDecodesHeaderWhenPresent() throws {
        let json = """
        {
            "stack": \(self.stackJSON),
            "background": \(self.backgroundJSON),
            "header": {
                "type": "header",
                "stack": \(self.stackJSON)
            }
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponentsData.PaywallComponentsConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.header).toNot(beNil())
        expect(decoded.header?.stack.components).to(beEmpty())
    }

    func testDecodesHeaderWhenAbsent() throws {
        let json = """
        {
            "stack": \(self.stackJSON),
            "background": \(self.backgroundJSON)
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponentsData.PaywallComponentsConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.header).to(beNil())
    }

    func testDecodesHeaderWhenNull() throws {
        let json = """
        {
            "stack": \(self.stackJSON),
            "background": \(self.backgroundJSON),
            "header": null
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponentsData.PaywallComponentsConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.header).to(beNil())
    }

    func testDecodesHeaderAndStickyFooterTogether() throws {
        let json = """
        {
            "stack": \(self.stackJSON),
            "background": \(self.backgroundJSON),
            "header": {
                "type": "header",
                "stack": \(self.stackJSON)
            },
            "sticky_footer": {
                "type": "sticky_footer",
                "stack": \(self.stackJSON)
            }
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponentsData.PaywallComponentsConfig.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.header).toNot(beNil())
        expect(decoded.stickyFooter).toNot(beNil())
    }

}
