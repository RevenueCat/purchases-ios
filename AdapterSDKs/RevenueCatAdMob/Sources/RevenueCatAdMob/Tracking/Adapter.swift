//
//  Adapter.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// Bridges AdMob events to RevenueCat's ad-tracking pipeline.
    ///
    /// Holds the singleton `Tracker` used by the adapter and exposes the `track*` helpers
    /// invoked by the GMA delegate wrappers and the `loadAndTrack` extensions.
    final class Adapter {

        static let shared = Adapter(tracker: PurchasesTracker())

        let tracker: Tracker

        let fullScreenDelegateStore = FullScreenDelegateStore()
        let nativeDelegateStore = NativeDelegateStore()
        let nativeAdLoaderProxyStore = NativeAdLoaderProxyStore()

        // Missing response metadata is not expected, but keep a deterministic fallback value also for type safety.
        private static let fallbackValue = ""
        static let microsPerUnit = NSDecimalNumber(value: 1_000_000)

        init(tracker: Tracker) {
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

        @MainActor
        func updateFullScreenContentDelegate(
            on fullScreenAd: some FullScreenAd,
            newDelegate: GoogleMobileAds.FullScreenContentDelegate?
        ) {
            if let wrapper = fullScreenAd.fullScreenContentDelegate as? FullScreenContentDelegate {
                wrapper.delegate = newDelegate
                return
            }

            fullScreenAd.fullScreenContentDelegate = newDelegate
        }

        // MARK: - handleLoadOutcome

        func handleLoadOutcome<Ad: AnyObject & FullScreenAd>(
            loadAd: () async throws -> Ad,
            context: FullScreenLoadContext
        ) async throws -> Ad {
            let loadedAd: Ad
            do {
                loadedAd = try await loadAd()
            } catch {
                self.trackFailedToLoad(
                    placement: context.placement,
                    adUnitID: context.adUnitID,
                    adFormat: context.adFormat,
                    error: error
                )
                throw error
            }

            let responseInfo = loadedAd.responseInfo

            self.trackLoaded(
                responseInfo: responseInfo,
                placement: context.placement,
                adUnitID: context.adUnitID,
                adFormat: context.adFormat
            )

            let placement = context.placement
            let adUnitID = context.adUnitID
            let adFormat = context.adFormat
            let fullScreenContentDelegate = context.fullScreenContentDelegate
            let paidEventHandler = context.paidEventHandler

            return await MainActor.run {
                let trackingDelegate = FullScreenContentDelegate(
                    adapter: self,
                    delegate: fullScreenContentDelegate,
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: adFormat,
                    responseInfoProvider: { responseInfo }
                )
                self.fullScreenDelegateStore.retain(trackingDelegate, for: loadedAd)
                loadedAd.fullScreenContentDelegate = trackingDelegate
                loadedAd.paidEventHandler = { [weak self, weak trackingDelegate] adValue in
                    self?.trackRevenue(
                        placement: trackingDelegate?.placement,
                        adUnitID: adUnitID,
                        adFormat: adFormat,
                        responseInfo: responseInfo,
                        adValue: adValue
                    )
                    paidEventHandler?(adValue)
                }
                return loadedAd
            }
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

}

#endif
