import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class InputSingleChoiceComponentTests: TestCase {

    private let minimalStack = """
    {
        "type": "stack",
        "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
        "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
        "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "components": []
    }
    """

    func testDecodesInputSingleChoice() throws {
        let json = """
        {
            "type": "input_single_choice",
            "field_id": "plan_type",
            "required": true,
            "stack": \(minimalStack)
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.InputSingleChoiceComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        expect(component.fieldId) == "plan_type"
        expect(component.required) == true
    }

    func testDecodesInputSingleChoiceDefaultRequired() throws {
        let json = """
        {
            "type": "input_single_choice",
            "field_id": "plan_type",
            "stack": \(minimalStack)
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.InputSingleChoiceComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        expect(component.required) == false
    }

    func testDecodesInputOption() throws {
        let json = """
        {
            "type": "input_option",
            "option_id": "annual",
            "option_value": "annual",
            "stack": \(minimalStack),
            "triggers": { "on_press": "action_123" }
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.InputOptionComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        expect(component.optionId) == "annual"
        expect(component.optionValue) == "annual"
        expect(component.triggers?["on_press"]) == "action_123"
    }

    func testDecodesInputOptionNoTriggers() throws {
        let json = """
        {
            "type": "input_option",
            "option_id": "monthly",
            "option_value": "monthly",
            "stack": \(minimalStack)
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.InputOptionComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        expect(component.triggers).to(beNil())
    }

    func testRoundTripInputSingleChoice() throws {
        let component = PaywallComponent.InputSingleChoiceComponent(
            fieldId: "plan_type",
            required: true,
            stack: .init(components: [])
        )
        let data = try JSONEncoder.default.encode(component)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.InputSingleChoiceComponent.self,
            from: data
        )
        expect(decoded.fieldId) == component.fieldId
        expect(decoded.required) == component.required
    }

    func testRoundTripInputOption() throws {
        let component = PaywallComponent.InputOptionComponent(
            optionId: "annual",
            optionValue: "annual",
            stack: .init(components: []),
            triggers: ["on_press": "action_abc"]
        )
        let data = try JSONEncoder.default.encode(component)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.InputOptionComponent.self,
            from: data
        )
        expect(decoded.optionId) == component.optionId
        expect(decoded.optionValue) == component.optionValue
        expect(decoded.triggers) == component.triggers
    }

    // MARK: - PaywallComponent dispatch

    func testPaywallComponentDecodesInputSingleChoice() throws {
        let json = """
        {
            "type": "input_single_choice",
            "field_id": "plan_type",
            "required": false,
            "stack": \(minimalStack)
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        guard case .inputSingleChoice(let inner) = component else {
            return XCTFail("Expected .inputSingleChoice, got \(component)")
        }
        expect(inner.fieldId) == "plan_type"
    }

    func testPaywallComponentDecodesInputOption() throws {
        let json = """
        {
            "type": "input_option",
            "option_id": "monthly",
            "option_value": "monthly",
            "stack": \(minimalStack)
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.self,
            from: XCTUnwrap(json.data(using: .utf8))
        )
        guard case .inputOption(let inner) = component else {
            return XCTFail("Expected .inputOption, got \(component)")
        }
        expect(inner.optionId) == "monthly"
    }

}

#endif
