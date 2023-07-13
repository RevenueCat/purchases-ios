import Nimble
@testable import RevenueCatUI
import SnapshotTesting
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PaywallViewTests: TestCase {

    func testOne() {
        let view = PaywallView(offering: TestData.offering, paywall: TestData.paywall)
            .frame(width: 300, height: 400)

        expect(view).to(haveValidSnapshot(as: .image))
    }

}
