import Nimble
@testable import RevenueCat
import XCTest

#if PAYWALL_COMPONENTS

class FallbackComponentTests: TestCase {

    let jsonStringDefaultStack = """
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

    func testUnknownTypeWithSuccessfulFallbackDecoding() throws {
        let jsonString = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            },
            "fallback": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedComponent = try JSONDecoder.default.decode(PaywallComponent.self, from: jsonData)

        let fallbackStackComponent = try JSONDecoder.default.decode(
            PaywallComponent.StackComponent.self,
            from: jsonStringDefaultStack.data(using: .utf8)!
        )

        switch decodedComponent {
        case .stack(let stackComponent):
            XCTAssertEqual(stackComponent, fallbackStackComponent)
        default:
            XCTFail("Did not fallback to any component")
        }
    }

    func testUnknownTypeWithFailedFallbackDecoding() throws {
        let jsonString = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            },
            "fallback": {
                "type": "less_new_but_still_new_type",
                "unknown_property": {
                    "type": "more_unknown"
                }
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        do {
            _ = try JSONDecoder.default.decode(PaywallComponent.self, from: jsonData)
            XCTFail("Should have failed to decode fallback property")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.debugDescription).to(
                contain("Failed to decode fallback for unknown type \"super_new_type\"")
            )
        } catch {
            XCTFail("Should have caught DecodingError.dataCorrupted")
        }
    }

    func testUnknownTypeNoFallbackDecoding() throws {
        let jsonString = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        do {
            _ = try JSONDecoder.default.decode(PaywallComponent.self, from: jsonData)
            XCTFail("Should have failed to decode fallback property")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.debugDescription).to(
                contain("Failed to decode fallback for unknown type \"super_new_type\"")
            )
        } catch {
            XCTFail("Should have caught DecodingError.dataCorrupted")
        }
    }

}

#endif
