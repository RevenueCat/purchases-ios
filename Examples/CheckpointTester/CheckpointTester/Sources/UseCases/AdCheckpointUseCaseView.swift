//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdCheckpointUseCaseView.swift
//

import Foundation
import GoogleMobileAds
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct AdCheckpointUseCaseView: View {

    @ObservedObject var customVariables: CustomVariables

    @State private var isRunning = false
    @State private var status = "Tap \"Hit checkpoint\" to resolve the ad checkpoint."
    @State private var presenter: InterstitialAdPresenter?
    @State private var didLoad = false

    var body: some View {
        List {
            Section("Latest result") {
                Text(self.isRunning ? "Running the checkpoint…" : self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Hit checkpoint") {
                    Task { @MainActor in
                        await self.runCheckpoint()
                    }
                }
                .disabled(self.isRunning)
            }
        }
        .navigationTitle("Ad checkpoint")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            await self.runCheckpoint()
        }
    }

    @MainActor
    private func runCheckpoint() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        defer { self.isRunning = false }

        do {
            let result = try await Purchases.shared.checkpoint(
                "ad_checkpoint",
                params: self.customVariables.checkpointParams
            )
            self.handle(result)
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func handle(_ result: CheckpointResult) {
        switch result {
        case let adResult as CheckpointAdResult:
            self.status = "Resolved ad unit \(adResult.adUnitId). Loading…"
            self.loadAndShowAd(adUnitId: adResult.adUnitId)
        case let noAction as CheckpointNoActionResult:
            self.status = "No ad shown (\(noAction.reason.value))."
        default:
            self.status = "Unknown checkpoint result."
        }
    }

    @MainActor
    private func loadAndShowAd(adUnitId: String) {
        let presenter = InterstitialAdPresenter { status in
            self.status = status
        }
        self.presenter = presenter
        presenter.load(adUnitId: adUnitId)
    }

}

/// Loads and shows a plain GoogleMobileAds interstitial, reporting a terminal status string back to the view.
///
/// This calls Google's ad SDK directly (not `purchases-ios-admob`'s `loadAndTrack`) — this use case validates
/// that a checkpoint resolves to a real, backend-configured ad unit ID and that a real interstitial renders
/// from it; RevenueCat ad-event tracking via `purchases-ios-admob` is a separate, already-proven integration.
@MainActor
private final class InterstitialAdPresenter: NSObject, FullScreenContentDelegate {

    private var interstitialAd: InterstitialAd?
    private let onStatusChange: (String) -> Void

    init(onStatusChange: @escaping (String) -> Void) {
        self.onStatusChange = onStatusChange
    }

    func load(adUnitId: String) {
        InterstitialAd.load(with: adUnitId, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.onStatusChange("Ad failed to load: \(error.localizedDescription)")
                return
            }
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.onStatusChange("Ad loaded. Presenting…")
            guard let rootViewController = Self.rootViewController() else {
                self.onStatusChange("Ad loaded, but no root view controller to present from.")
                return
            }
            self.interstitialAd?.present(from: rootViewController)
        }
    }

    func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
        self.onStatusChange("Ad impression recorded.")
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.onStatusChange("Ad failed to present: \(error.localizedDescription)")
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        self.onStatusChange("Ad dismissed.")
    }

    private static func rootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

}
