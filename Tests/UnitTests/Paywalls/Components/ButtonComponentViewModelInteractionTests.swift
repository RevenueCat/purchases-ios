import Nimble
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ButtonComponentViewModelInteractionTests: TestCase {

    func testUnknownActionInteractionValueIsUnknown() {
        let action: ButtonComponentViewModel.Action = .unknown

        expect(action.paywallComponentInteractionValue) == "unknown"
        expect(action.paywallComponentInteractionURL).to(beNil())
    }

    func testKnownActionInteractionValuesRemainUnchanged() {
        let action: ButtonComponentViewModel.Action = .navigateBack

        expect(action.paywallComponentInteractionValue) == "navigate_back"
        expect(action.paywallComponentInteractionURL).to(beNil())
    }

    func testWorkflowTriggerInteractionValue() {
        let action: ButtonComponentViewModel.Action = .workflowTrigger

        expect(action.paywallComponentInteractionValue) == "workflow_trigger"
        expect(action.paywallComponentInteractionURL).to(beNil())
    }

}

#endif
