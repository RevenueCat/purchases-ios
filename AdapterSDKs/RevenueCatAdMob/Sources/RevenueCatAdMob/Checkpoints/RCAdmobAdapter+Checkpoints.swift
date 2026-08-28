//
//  RCAdmobAdapter+Checkpoints.swift
//
//  Created by RevenueCat on 8/27/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI

/// Auto-presents checkpoints resolved to an `"admob"` ad by registering a ``CheckpointAdHandler`` for
/// that mediator via `Purchases.registerCheckpointAdHandler(_:for:)` — after this, the app's existing
/// `Purchases.shared.checkpoint(_:)` call auto-presents an AdMob ad the same way it already
/// auto-presents a paywall, with no separate method to call and no need to know upfront which kind of
/// experience the backend will resolve to.
@available(iOS 15.0, *)
// swiftlint:disable:next convenience_type
public struct RCAdmobAdapter {

    /// The `mediator` value AdMob `ad` checkpoint steps are configured with in the RevenueCat dashboard.
    public static let checkpointMediator = "admob"

    /// Registers the AdMob checkpoint ad handler. Call once, after `Purchases.configure(...)`.
    @MainActor
    public static func enableCheckpointAds() {
        Purchases.shared.registerCheckpointAdHandler(AdMobCheckpointAdHandler(), for: Self.checkpointMediator)
    }

}

/// Loads and presents a GoogleMobileAds interstitial via `loadAndTrack`, resolving only once it has
/// been dismissed or failed — this is the concrete handler RevenueCatUI's `CheckpointsManager` awaits
/// directly, so it must always resume (see ``CheckpointAdHandler``'s documented contract).
@available(iOS 15.0, *)
@MainActor
private final class AdMobCheckpointAdHandler: NSObject, CheckpointAdHandler, GoogleMobileAds.FullScreenContentDelegate {

    private var interstitialAd: GoogleMobileAds.InterstitialAd?
    private var continuation: CheckedContinuation<Void, Error>?

    func present(checkpoint: CheckpointInfo, adUnitId: String) async throws {
        // `loadAndTrack` reports the load outcome to RevenueCat and wraps `self` in its own tracking
        // delegate — dismissal/failure still reach `self` via the callbacks below.
        let loadedAd = try await GoogleMobileAds.InterstitialAd.loadAndTrack(
            withAdUnitID: adUnitId,
            request: GoogleMobileAds.Request(),
            placement: checkpoint.identifier,
            fullScreenContentDelegate: self
        )

        guard let rootViewController = Self.rootViewController() else {
            throw CheckpointAdHandlerError.noPresentationContext
        }
        self.interstitialAd = loadedAd

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            loadedAd.present(from: rootViewController)
        }
    }

    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.finish(throwing: nil)
    }

    func ad(
        _ presentingAd: any GoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        self.finish(throwing: error)
    }

    private func finish(throwing error: Error?) {
        guard let continuation = self.continuation else { return }
        self.continuation = nil
        self.interstitialAd = nil
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }

    private static func rootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

}

private enum CheckpointAdHandlerError: Error {
    case noPresentationContext
}

#endif
