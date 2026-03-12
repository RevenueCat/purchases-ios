//
//  RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
import Foundation
#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

// MARK: - AdTracking protocol

@available(iOS 15.0, *)
internal protocol AdTracking {
    var isConfigured: Bool { get }
    func trackAdLoaded(_ data: AdLoaded)
    func trackAdDisplayed(_ data: AdDisplayed)
    func trackAdOpened(_ data: AdOpened)
    func trackAdRevenue(_ data: AdRevenue)
    func trackAdFailedToLoad(_ data: AdFailedToLoad)
}

// MARK: - PurchasesAdTracker (production conformance)

@available(iOS 15.0, *)
internal final class PurchasesAdTracker: AdTracking {
    var isConfigured: Bool { Purchases.isConfigured }
    func trackAdLoaded(_ data: AdLoaded) { Purchases.shared.adTracker.trackAdLoaded(data) }
    func trackAdDisplayed(_ data: AdDisplayed) { Purchases.shared.adTracker.trackAdDisplayed(data) }
    func trackAdOpened(_ data: AdOpened) { Purchases.shared.adTracker.trackAdOpened(data) }
    func trackAdRevenue(_ data: AdRevenue) { Purchases.shared.adTracker.trackAdRevenue(data) }
    func trackAdFailedToLoad(_ data: AdFailedToLoad) { Purchases.shared.adTracker.trackAdFailedToLoad(data) }
}

// MARK: - RCAdMob

@available(iOS 15.0, *)
internal final class RCAdMob {

    static let shared = RCAdMob(tracker: PurchasesAdTracker())

    let tracker: AdTracking

    private static var fullScreenDelegateKey: UInt8 = 0
    private static var nativeDelegateKey: UInt8 = 0

    // Missing response metadata is not expected, but keep a deterministic fallback value also for type safety.
    private static let fallbackValue = ""
    static let microsPerUnit = NSDecimalNumber(value: 1_000_000)

    init(tracker: AdTracking) {
        self.tracker = tracker
    }

    func trackLoaded(
        responseInfo: GoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdLoaded(
                networkName: Self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: Self.adUnitID(adUnitID),
                impressionId: Self.impressionID(from: responseInfo)
            )
            self.tracker.trackAdLoaded(data)
        }
    }

    func trackDisplayed(
        responseInfo: GoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdDisplayed(
                networkName: Self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: Self.adUnitID(adUnitID),
                impressionId: Self.impressionID(from: responseInfo)
            )
            self.tracker.trackAdDisplayed(data)
        }
    }

    func trackOpened(
        responseInfo: GoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdOpened(
                networkName: Self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: Self.adUnitID(adUnitID),
                impressionId: Self.impressionID(from: responseInfo)
            )
            self.tracker.trackAdOpened(data)
        }
    }

    func trackRevenue(
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat,
        responseInfo: GoogleMobileAds.ResponseInfo?,
        adValue: GoogleMobileAds.AdValue
    ) {
        self.trackIfConfigured {
            let data = AdRevenue(
                networkName: Self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: Self.adUnitID(adUnitID),
                impressionId: Self.impressionID(from: responseInfo),
                revenueMicros: Self.revenueMicros(from: adValue.value),
                currency: adValue.currencyCode,
                precision: Self.mapPrecision(adValue.precision)
            )
            self.tracker.trackAdRevenue(data)
        }
    }

    func trackFailedToLoad(
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat,
        error: Error
    ) {
        self.trackIfConfigured {
            let data = AdFailedToLoad(
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: Self.adUnitID(adUnitID),
                mediatorErrorCode: (error as NSError).code
            )
            self.tracker.trackAdFailedToLoad(data)
        }
    }

    internal static func mapPrecision(_ precision: GoogleMobileAds.AdValuePrecision) -> AdRevenue.Precision {
        switch precision {
        case .precise: return .exact
        case .estimated: return .estimated
        case .publisherProvided: return .publisherDefined
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }

    internal static func revenueMicros(from adValue: NSDecimalNumber) -> Int {
        let micros = adValue.multiplying(by: self.microsPerUnit)
        return Int(micros.int64Value)
    }

    func retainFullScreenDelegate(_ delegate: AnyObject, for object: AnyObject) {
        objc_setAssociatedObject(
            object,
            &Self.fullScreenDelegateKey,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func retainNativeDelegate(_ delegate: AnyObject, for object: AnyObject) {
        objc_setAssociatedObject(
            object,
            &Self.nativeDelegateKey,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - handleLoadOutcome

    func handleLoadOutcome<Ad: AnyObject & RCFullScreenAdTracking>(
        loadedAd: Ad?,
        error: Error?,
        context: FullScreenLoadContext,
        completion: (Ad?, Error?) -> Void
    ) {
        if let error {
            self.trackFailedToLoad(
                placement: context.placement,
                adUnitID: context.adUnitID,
                adFormat: context.adFormat,
                error: error
            )
            completion(nil, error)
            return
        }

        guard let loadedAd else {
            // SDK contract is success (ad, nil) or failure (nil, error). (nil, nil) is not documented; forward as-is.
            completion(nil, nil)
            return
        }

        self.trackLoaded(
            responseInfo: context.responseInfo,
            placement: context.placement,
            adUnitID: context.adUnitID,
            adFormat: context.adFormat
        )

        let placement = context.placement
        let adUnitID = context.adUnitID
        let adFormat = context.adFormat
        let fullScreenContentDelegate = context.fullScreenContentDelegate
        let paidEventHandler = context.paidEventHandler
        let responseInfo = context.responseInfo

        let trackingDelegate = RCAdMobFullScreenContentDelegate(
            rcAdMob: self,
            delegate: fullScreenContentDelegate,
            placement: placement,
            adUnitID: adUnitID,
            adFormat: adFormat,
            responseInfoProvider: { responseInfo }
        )
        self.retainFullScreenDelegate(trackingDelegate, for: loadedAd)
        loadedAd.fullScreenContentDelegate = trackingDelegate
        loadedAd.paidEventHandler = { [weak self] adValue in
            self?.trackRevenue(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: adFormat,
                responseInfo: responseInfo,
                adValue: adValue
            )
            paidEventHandler?(adValue)
        }
        completion(loadedAd, nil)
    }

    // MARK: - Private helpers

    private static func networkName(from responseInfo: GoogleMobileAds.ResponseInfo?) -> String {
        responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? self.fallbackValue
    }

    private static func impressionID(from responseInfo: GoogleMobileAds.ResponseInfo?) -> String {
        responseInfo?.responseIdentifier ?? self.fallbackValue
    }

    private static func adUnitID(_ adUnitID: String?) -> String {
        adUnitID ?? self.fallbackValue
    }

    private func trackIfConfigured(_ block: () -> Void) {
        guard self.tracker.isConfigured else { return }
        block()
    }

}

#endif
