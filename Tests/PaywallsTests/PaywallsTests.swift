import Nimble
@testable import Paywalls
import SnapshotTesting
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PaywallsTests: TestCase {

    func testOne() {
        let view = PaywallView(offering: TestData.offering)
            .frame(width: 300, height: 400)

        expect(view).to(haveValidSnapshot(as: .image))
    }

}
