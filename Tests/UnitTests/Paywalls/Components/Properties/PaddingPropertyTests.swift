import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class PaddingPropertyTests: TestCase {

    func testAllValues() throws {
        let json = """
        {
            "top": 5,
            "bottom": 5,
            "leading": 5,
            "trailing": 5
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.Padding.self,
            from: json.data(using: .utf8)!
        )
    }

    func testNullValues() throws {
        let json = """
        {
            "top": null,
            "bottom": null,
            "leading": null,
            "trailing": null
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.Padding.self,
            from: json.data(using: .utf8)!
        )
    }

    func testEmptyObject() throws {
        let json = """
        {}
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.Padding.self,
            from: json.data(using: .utf8)!
        )
    }

}

#endif
