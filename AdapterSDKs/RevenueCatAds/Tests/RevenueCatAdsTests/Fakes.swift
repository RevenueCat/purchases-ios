//
//  Fakes.swift
//
//  Created by RevenueCat.
//

import UIKit
import XCTest

#if os(iOS) && canImport(PrebidMobile)
import RevenueCat
@_spi(Experimental) @testable import RevenueCatAds

/// Local base class for RevenueCatAds unit tests.
typealias TestCase = XCTestCase

func makeURL(_ string: String) -> URL {
    guard let url = URL(string: string) else { fatalError("Invalid URL \(string)") }
    return url
}

@MainActor
final class FakeAdModule: AdModule {

    var initializedConfigurations: [ResolvedAdsConfiguration] = []
    var initializeError: Error?
    var interstitials: [FakeAdModuleInterstitial] = []
    /// Applied as `eventOnLoad` to interstitials created from now on.
    var interstitialEvent: AdModuleEvent?

    var lastInterstitial: FakeAdModuleInterstitial? { self.interstitials.last }

    func initialize(with configuration: ResolvedAdsConfiguration) throws {
        if let initializeError = self.initializeError {
            throw initializeError
        }
        self.initializedConfigurations.append(configuration)
    }

    func makeInterstitial(placementID: String) -> AdModuleInterstitial {
        let interstitial = FakeAdModuleInterstitial(placementID: placementID)
        interstitial.eventOnLoad = self.interstitialEvent
        self.interstitials.append(interstitial)
        return interstitial
    }

}

@MainActor
final class FakeAdModuleInterstitial: AdModuleInterstitial {

    let placementID: String
    var onEvent: ((AdModuleEvent) -> Void)?
    var isReady = false
    var networkName = "FakeNetwork"
    var revenue: AdModuleRevenue?
    var loadCallCount = 0
    var showCallCount = 0

    /// Event emitted synchronously from `load()`, like a cached/instant response would.
    var eventOnLoad: AdModuleEvent?

    init(placementID: String) {
        self.placementID = placementID
    }

    func load() {
        self.loadCallCount += 1
        if let event = self.eventOnLoad {
            self.emit(event)
        }
    }

    func show(from viewController: UIViewController) {
        self.showCallCount += 1
    }

    func emit(_ event: AdModuleEvent) {
        if case .loaded = event {
            self.isReady = true
        }
        self.onEvent?(event)
    }

}

final class FakeAdTracking: AdTracking {

    var isConfigured = true
    private(set) var loaded: [AdLoaded] = []
    private(set) var displayed: [AdDisplayed] = []
    private(set) var opened: [AdOpened] = []
    private(set) var revenues: [AdRevenue] = []
    private(set) var failedToLoad: [AdFailedToLoad] = []

    var trackedEventCount: Int {
        self.loaded.count + self.displayed.count + self.opened.count + self.revenues.count + self.failedToLoad.count
    }

    func trackAdLoaded(_ data: AdLoaded) { self.loaded.append(data) }

    func trackAdDisplayed(_ data: AdDisplayed) { self.displayed.append(data) }

    func trackAdOpened(_ data: AdOpened) { self.opened.append(data) }

    func trackAdRevenue(_ data: AdRevenue) { self.revenues.append(data) }

    func trackAdFailedToLoad(_ data: AdFailedToLoad) { self.failedToLoad.append(data) }

}

@MainActor
final class RecordingDelegate: AdsInterstitialDelegate {

    enum Event: Equatable {

        case loaded
        case failed(AdsError.Code)
        case presented
        case impression
        case clicked
        case dismissed

    }

    private(set) var events: [Event] = []

    func interstitialDidLoad(_ interstitial: AdsInterstitial) { self.events.append(.loaded) }

    func interstitial(_ interstitial: AdsInterstitial, didFailWithError error: AdsError) {
        self.events.append(.failed(error.code))
    }

    func interstitialDidPresent(_ interstitial: AdsInterstitial) { self.events.append(.presented) }

    func interstitialDidRecordImpression(_ interstitial: AdsInterstitial) { self.events.append(.impression) }

    func interstitialDidRecordClick(_ interstitial: AdsInterstitial) { self.events.append(.clicked) }

    func interstitialDidDismiss(_ interstitial: AdsInterstitial) { self.events.append(.dismissed) }

}

#endif
