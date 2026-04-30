import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@MainActor
@available(iOS 15.0, *)
final class RewardVerificationPlacementOverrideTests: AdapterTestCase {

    func testKeepLoadTimePlacementDoesNotClearExistingPlacement() {
        let fullScreenAd = FakeFullScreenAd()
        let trackingDelegate = Tracking.FullScreenContentDelegate(
            delegate: nil,
            placement: "load_time_placement",
            adUnitID: "ad_unit_id",
            adFormat: .rewarded,
            responseInfoProvider: { nil }
        )
        Tracking.Adapter.shared.fullScreenDelegateStore.retain(trackingDelegate, for: fullScreenAd)

        Tracking.applyRewardVerificationPlacementOverride(.keepLoadTimePlacement, on: fullScreenAd)

        let updatedDelegate = Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: fullScreenAd)
        XCTAssertEqual(updatedDelegate?.placement, "load_time_placement")
    }

    func testExplicitNilPlacementOverrideClearsExistingPlacement() {
        let fullScreenAd = FakeFullScreenAd()
        let trackingDelegate = Tracking.FullScreenContentDelegate(
            delegate: nil,
            placement: "load_time_placement",
            adUnitID: "ad_unit_id",
            adFormat: .rewarded,
            responseInfoProvider: { nil }
        )
        Tracking.Adapter.shared.fullScreenDelegateStore.retain(trackingDelegate, for: fullScreenAd)

        Tracking.applyRewardVerificationPlacementOverride(.override(nil), on: fullScreenAd)

        let updatedDelegate = Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: fullScreenAd)
        XCTAssertNil(updatedDelegate?.placement)
    }
}

@available(iOS 15.0, *)
private final class FakeFullScreenAd: NSObject, Tracking.FullScreenAd {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
    let responseInfo: GoogleMobileAds.ResponseInfo = unsafeBitCast(
        FakeResponseInfo(),
        to: GoogleMobileAds.ResponseInfo.self
    )
}

@available(iOS 15.0, *)
private final class FakeResponseInfo: NSObject {
    @objc var responseIdentifier: String? { nil }
    @objc var loadedAdNetworkResponseInfo: AnyObject? { nil }
}

#endif
