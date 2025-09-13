import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

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

    func testUnknownTypeWithSuccessfulFallbackDecodingAndEncodesAndRedecodes() throws {
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

        // Step 1: Decodes correctly
        switch decodedComponent {
        case .stack(let stackComponent):
            XCTAssertEqual(stackComponent, fallbackStackComponent)
        default:
            XCTFail("Did not fallback to any component")
        }

        // Step 2: Encodes
        let encodedComponent = try JSONEncoder.default.encode(decodedComponent)

        // Step 3: Decodes correctly (verifying encoding)
        let redecodedComponent = try JSONDecoder.default.decode(PaywallComponent.self, from: encodedComponent)
        switch redecodedComponent {
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
                contain("Failed to decode fallback for unknown type \"super_new_type\".")
            )
            expect(context.underlyingError.debugDescription).to(
                contain("Failed to decode unknown type \\\"less_new_but_still_new_type\\\" without a fallback.")
            )
        } catch {
            XCTFail("Should have caught DecodingError.dataCorrupted")
        }
    }

    func testUnknownTypeWithInvalidExistingTypeDecoding() throws {
        let jsonString = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            },
            "fallback": {
                "type": "text",
                "wrong": "property"
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        do {
            _ = try JSONDecoder.default.decode(PaywallComponent.self, from: jsonData)
            XCTFail("Should have failed to decode fallback property")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.debugDescription).to(
                contain("Failed to decode fallback for unknown type \"super_new_type\".")
            )
            expect(context.underlyingError.debugDescription).to(
                contain("No value associated with key CodingKeys(stringValue: \\\"textLid\\\"")
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
                contain("Failed to decode unknown type \"super_new_type\" without a fallback.")
            )
        } catch {
            XCTFail("Should have caught DecodingError.dataCorrupted")
        }
    }

    func testUnknownTypeNullFallbackDecoding() throws {
        let jsonString = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            },
            "fallback": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        do {
            _ = try JSONDecoder.default.decode(PaywallComponent.self, from: jsonData)
            XCTFail("Should have failed to decode fallback property")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.debugDescription).to(
                contain("Failed to decode unknown type \"super_new_type\" without a fallback.")
            )
        } catch {
            XCTFail("Should have caught DecodingError.dataCorrupted")
        }
    }

}

#endif
