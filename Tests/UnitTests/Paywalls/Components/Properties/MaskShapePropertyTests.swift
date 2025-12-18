import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class MaskShapePropertyTests: TestCase {

    func testRectangleNoCorners() throws {
        let json = """
        {
            "type": "rectangle",
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.MaskShape.self,
            from: json.data(using: .utf8)!
        )
    }

    func testRectangleWithCorners() throws {
        let json = """
        {
            "type": "rectangle",
            "corners": {
                "top_leading": 5,
                "top_trailing": 5,
                "bottom_leading": 5,
                "bottom_trailing": 5
            }
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.MaskShape.self,
            from: json.data(using: .utf8)!
        )
    }

    func testConvex() throws {
        let json = """
        {
            "type": "convex",
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.MaskShape.self,
            from: json.data(using: .utf8)!
        )
    }

    func testConcave() throws {
        let json = """
        {
            "type": "concave",
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.MaskShape.self,
            from: json.data(using: .utf8)!
        )
    }

}

#endif
