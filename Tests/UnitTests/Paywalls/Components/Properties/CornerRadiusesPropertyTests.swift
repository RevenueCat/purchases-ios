import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class CornerRadiusesPropertyTests: TestCase {

    func testAllValues() throws {
        let json = """
        {
            "top_leading": 5,
            "top_trailing": 5,
            "bottom_leading": 5,
            "bottom_trailing": 5
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.CornerRadiuses.self,
            from: json.data(using: .utf8)!
        )
    }

    func testNullValues() throws {
        let json = """
        {
            "top_leading": null,
            "top_trailing": null,
            "bottom_leading": null,
            "bottom_trailing": null
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.CornerRadiuses.self,
            from: json.data(using: .utf8)!
        )
    }

    func testEmptyObject() throws {
        let json = """
        {}
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.CornerRadiuses.self,
            from: json.data(using: .utf8)!
        )
    }

}

#endif
