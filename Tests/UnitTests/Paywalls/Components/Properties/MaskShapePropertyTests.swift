import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class MaskShapePropertyTests: TestCase {

    private static let corners = """
    "corners": {
        "top_leading": 1,
        "top_trailing": 2,
        "bottom_leading": 3,
        "bottom_trailing": 4
    }
    """

    func testDecodesEachType() throws {
        let cases: [(json: String, expected: PaywallComponent.MaskShape)] = [
            (#"{ "type": "rectangle" }"#, .rectangle(nil)),
            (
                #"{ "type": "rectangle", \#(Self.corners) }"#,
                .rectangle(.init(topLeading: 1, topTrailing: 2, bottomLeading: 3, bottomTrailing: 4))
            ),
            (#"{ "type": "circle" }"#, .circle),
            (#"{ "type": "concave" }"#, .concave),
            (#"{ "type": "convex" }"#, .convex)
        ]

        for (json, expected) in cases {
            expect(try Self.decode(json)).to(equal(expected), description: json)
        }
    }

    func testUnknownTypeFallsBackToRectangle() throws {
        expect(try Self.decode(#"{ "type": "hexagon" }"#)) == .rectangle(nil)
    }

    private static func decode(_ json: String) throws -> PaywallComponent.MaskShape {
        return try JSONDecoder.default.decode(PaywallComponent.MaskShape.self, from: json.data(using: .utf8)!)
    }

}

#endif
