import Nimble
@testable import RevenueCatUI
import SnapshotTesting
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PaywallViewTests: TestCase {

    override class func setUp() {
        super.setUp()

        // isRecording = true
    }

    func testSamplePaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering, paywall: offering.paywall!)
            .frame(width: Self.size.width, height: Self.size.height)

        expect(view).to(haveValidSnapshot(as: .image))
    }

    func testSamplePaywallWithIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering, paywall: offering.paywall!)
            .frame(width: Self.size.width, height: Self.size.height)

        expect(view).to(haveValidSnapshot(as: .image))
    }

    private static let size: CGSize = .init(width: 460, height: 950)

}
