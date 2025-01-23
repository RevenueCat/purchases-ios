import Nimble
@testable import RevenueCat
import XCTest

#if PAYWALL_COMPONENTS

class StackComponentTests: TestCase {

    func testUnknownTypeWithSuccessfulFallbackDecodingAndEncodesAndRedecodes() throws {
        let jsonStack = """
        {
            "type": "stack",
            "dimension": {
                "type": "vertical",
                "alignment": "center",
                "distribution": "start"
            },
            "size": {
                "width": { "type": "fill" },
                "height": { "type": "fill" }
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

        _ = try JSONDecoder.default.decode(
            PaywallComponent.StackComponent.self,
            from: jsonStack.data(using: .utf8)!
        )
    }

}

#endif
