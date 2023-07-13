import Nimble
import RevenueCat
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

        let view = PaywallView(offering: offering, paywall: offering.paywall!.withLocalImage)
        view.snapshot(size: Self.size)
    }

    func testSamplePaywallWithIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering, paywall: offering.paywall!.withLocalImage)
        view.snapshot(size: Self.size)
    }

    private static let size: CGSize = .init(width: 460, height: 950)

}

private extension PaywallData {

    var withLocalImage: Self {
        var copy = self
        copy.assetBaseURL = URL(fileURLWithPath: Bundle.module.bundlePath)
        copy.config.headerImageName = "image.png"

        return copy
    }

}
