//
//  FullScreenAd+RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

// MARK: - InterstitialAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.InterstitialAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob
    ) async throws -> GoogleMobileAds.InterstitialAd {
        try await rcAdMob.handleLoadOutcome(
            loadAd: { try await Self.load(with: adUnitID, request: request) },
            context: FullScreenLoadContext(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: RevenueCat.AdFormat.interstitial,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.InterstitialAd {

    /// Loads an interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil
    ) async throws -> GoogleMobileAds.InterstitialAd {
        try await self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared
        )
    }

    /// Presents the interstitial ad and overrides the placement used for RevenueCat analytics.
    ///
    /// Call this instead of `present(from:)` when you want to specify or override the placement at show time.
    /// The placement passed here takes precedence over any placement provided at load time.
    @MainActor
    func present(from viewController: UIViewController, placement: String?) {
        RCAdMob.shared.retrieveFullScreenDelegate(for: self)?.placement = placement
        self.present(from: viewController)
    }
}

// MARK: - AppOpenAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.AppOpenAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob
    ) async throws -> GoogleMobileAds.AppOpenAd {
        try await rcAdMob.handleLoadOutcome(
            loadAd: { try await Self.load(with: adUnitID, request: request) },
            context: FullScreenLoadContext(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: RevenueCat.AdFormat.appOpen,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.AppOpenAd {

    /// Loads an app open ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil
    ) async throws -> GoogleMobileAds.AppOpenAd {
        try await self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared
        )
    }

    /// Presents the app open ad and overrides the placement used for RevenueCat analytics.
    ///
    /// Call this instead of `present(from:)` when you want to specify or override the placement at show time.
    /// The placement passed here takes precedence over any placement provided at load time.
    @MainActor
    func present(from viewController: UIViewController, placement: String?) {
        RCAdMob.shared.retrieveFullScreenDelegate(for: self)?.placement = placement
        self.present(from: viewController)
    }
}

// MARK: - RewardedAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.RewardedAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob
    ) async throws -> GoogleMobileAds.RewardedAd {
        try await rcAdMob.handleLoadOutcome(
            loadAd: { try await Self.load(with: adUnitID, request: request) },
            context: FullScreenLoadContext(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: RevenueCat.AdFormat.rewarded,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Loads a rewarded ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil
    ) async throws -> GoogleMobileAds.RewardedAd {
        try await self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared
        )
    }

    /// Presents the rewarded ad and overrides the placement used for RevenueCat analytics.
    ///
    /// Call this instead of `present(from:userDidEarnRewardHandler:)` when you want to specify or override
    /// the placement at show time. The placement passed here takes precedence over any placement provided at load time.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        userDidEarnRewardHandler: @escaping () -> Void
    ) {
        RCAdMob.shared.retrieveFullScreenDelegate(for: self)?.placement = placement
        self.present(from: viewController, userDidEarnRewardHandler: userDidEarnRewardHandler)
    }
}

// MARK: - RewardedInterstitialAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.RewardedInterstitialAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob
    ) async throws -> GoogleMobileAds.RewardedInterstitialAd {
        try await rcAdMob.handleLoadOutcome(
            loadAd: { try await Self.load(with: adUnitID, request: request) },
            context: FullScreenLoadContext(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: RevenueCat.AdFormat.rewardedInterstitial,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Loads a rewarded interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil
    ) async throws -> GoogleMobileAds.RewardedInterstitialAd {
        try await self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared
        )
    }

    /// Presents the rewarded interstitial ad and overrides the placement used for RevenueCat analytics.
    ///
    /// Call this instead of `present(from:userDidEarnRewardHandler:)` when you want to specify or override
    /// the placement at show time. The placement passed here takes precedence over any placement provided at load time.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        userDidEarnRewardHandler: @escaping () -> Void
    ) {
        RCAdMob.shared.retrieveFullScreenDelegate(for: self)?.placement = placement
        self.present(from: viewController, userDidEarnRewardHandler: userDidEarnRewardHandler)
    }
}

@available(iOS 15.0, *)
internal protocol RCFullScreenAdTracking: AnyObject {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate? { get set }
    var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? { get set }
    var responseInfo: GoogleMobileAds.ResponseInfo { get }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.InterstitialAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.AppOpenAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RCFullScreenAdTracking {}

// MARK: - Delegate reassignment

@available(iOS 15.0, *)
internal extension RCFullScreenAdTracking {

    @MainActor
    func rcSetTrackingFullScreenContentDelegate(
        _ delegate: GoogleMobileAds.FullScreenContentDelegate?
    ) {
        RCAdMob.shared.updateFullScreenContentDelegate(on: self, newDelegate: delegate)
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.InterstitialAd {

    /// Safely sets your ``FullScreenContentDelegate`` without removing RevenueCat's tracking wrapper.
    ///
    /// Use this instead of assigning ``fullScreenContentDelegate`` directly when the ad was loaded
    /// via ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:)``.
    /// If the ad was not loaded via `loadAndTrack`, this falls back to direct assignment.
    @MainActor
    func setTrackingFullScreenContentDelegate(_ delegate: GoogleMobileAds.FullScreenContentDelegate?) {
        self.rcSetTrackingFullScreenContentDelegate(delegate)
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.AppOpenAd {

    /// Safely sets your ``FullScreenContentDelegate`` without removing RevenueCat's tracking wrapper.
    ///
    /// Use this instead of assigning ``fullScreenContentDelegate`` directly when the ad was loaded
    /// via ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:)``.
    /// If the ad was not loaded via `loadAndTrack`, this falls back to direct assignment.
    @MainActor
    func setTrackingFullScreenContentDelegate(_ delegate: GoogleMobileAds.FullScreenContentDelegate?) {
        self.rcSetTrackingFullScreenContentDelegate(delegate)
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Safely sets your ``FullScreenContentDelegate`` without removing RevenueCat's tracking wrapper.
    ///
    /// Use this instead of assigning ``fullScreenContentDelegate`` directly when the ad was loaded
    /// via ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:)``.
    /// If the ad was not loaded via `loadAndTrack`, this falls back to direct assignment.
    @MainActor
    func setTrackingFullScreenContentDelegate(_ delegate: GoogleMobileAds.FullScreenContentDelegate?) {
        self.rcSetTrackingFullScreenContentDelegate(delegate)
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Safely sets your ``FullScreenContentDelegate`` without removing RevenueCat's tracking wrapper.
    ///
    /// Use this instead of assigning ``fullScreenContentDelegate`` directly when the ad was loaded
    /// via ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:completion:)``.
    /// If the ad was not loaded via `loadAndTrack`, this falls back to direct assignment.
    @MainActor
    func setTrackingFullScreenContentDelegate(_ delegate: GoogleMobileAds.FullScreenContentDelegate?) {
        self.rcSetTrackingFullScreenContentDelegate(delegate)
    }
}

@available(iOS 15.0, *)
internal struct FullScreenLoadContext {
    let placement: String?
    let adUnitID: String
    let adFormat: RevenueCat.AdFormat
    let fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    let paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
}

#endif
