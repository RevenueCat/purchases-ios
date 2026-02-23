//
//  RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
import Foundation
#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat
@available(iOS 15.0, *)
internal enum RCAdMob {

    private static var fullScreenDelegateKey: UInt8 = 0
    private static var nativeDelegateKey: UInt8 = 0

    // Missing response metadata is not expected, but keep a deterministic fallback value also for type safety.
    private static let fallbackValue = ""
    static let microsPerUnit = NSDecimalNumber(value: 1_000_000)

    static func trackLoaded(
        responseInfo: RCGoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdLoaded(
                networkName: self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: self.adUnitID(adUnitID),
                impressionId: self.impressionID(from: responseInfo)
            )
            Purchases.shared.adTracker.trackAdLoaded(data)
        }
    }

    static func trackDisplayed(
        responseInfo: RCGoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdDisplayed(
                networkName: self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: self.adUnitID(adUnitID),
                impressionId: self.impressionID(from: responseInfo)
            )
            Purchases.shared.adTracker.trackAdDisplayed(data)
        }
    }

    static func trackOpened(
        responseInfo: RCGoogleMobileAds.ResponseInfo?,
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat
    ) {
        self.trackIfConfigured {
            let data = AdOpened(
                networkName: self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: self.adUnitID(adUnitID),
                impressionId: self.impressionID(from: responseInfo)
            )
            Purchases.shared.adTracker.trackAdOpened(data)
        }
    }

    static func trackRevenue(
        placement: String?,
        adUnitID: String?,
        adFormat: RevenueCat.AdFormat,
        responseInfo: RCGoogleMobileAds.ResponseInfo?,
        adValue: RCGoogleMobileAds.AdValue
    ) {
        self.trackIfConfigured {
            let data = AdRevenue(
                networkName: self.networkName(from: responseInfo),
                mediatorName: .adMob,
                adFormat: adFormat,
                placement: placement,
                adUnitId: self.adUnitID(adUnitID),
                impressionId: self.impressionID(from: responseInfo),
                revenueMicros: self.revenueMicros(from: adValue.value),
                currency: adValue.currencyCode,
                precision: self.mapPrecision(adValue.precision)
            )
            Purchases.shared.adTracker.trackAdRevenue(data)
        }
    }

    static func trackFailedToLoad(
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
                adUnitId: self.adUnitID(adUnitID),
                mediatorErrorCode: (error as NSError).code
            )
            Purchases.shared.adTracker.trackAdFailedToLoad(data)
        }
    }

    internal static func mapPrecision(_ precision: RCGoogleMobileAds.AdValuePrecision) -> AdRevenue.Precision {
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

    static func retainFullScreenDelegate(_ delegate: AnyObject, for object: AnyObject) {
        objc_setAssociatedObject(
            object,
            &self.fullScreenDelegateKey,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    static func retainNativeDelegate(_ delegate: AnyObject, for object: AnyObject) {
        objc_setAssociatedObject(
            object,
            &self.nativeDelegateKey,
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - Private helpers

    private static func networkName(from responseInfo: RCGoogleMobileAds.ResponseInfo?) -> String {
        responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? self.fallbackValue
    }

    private static func impressionID(from responseInfo: RCGoogleMobileAds.ResponseInfo?) -> String {
        responseInfo?.responseIdentifier ?? self.fallbackValue
    }

    private static func adUnitID(_ adUnitID: String?) -> String {
        adUnitID ?? self.fallbackValue
    }

    private static func trackIfConfigured(_ block: () -> Void) {
        guard Purchases.isConfigured else { return }
        block()
    }

}

#endif
