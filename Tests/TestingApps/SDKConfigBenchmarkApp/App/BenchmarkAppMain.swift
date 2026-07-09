//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BenchmarkAppMain.swift
//
//  Created by Facundo Menzella on 9/7/26.

@_spi(Internal) import RevenueCat
import RevenueCatUI
import SwiftUI

/// Measures one real SDK launch end to end: configure, first customer info, offerings,
/// paywall appeared. The XCUITest runner relaunches this app once per iteration (a true
/// process cold start), injecting the API key and user via the launch environment:
///
/// - `BENCH_API_KEY`: RevenueCat public API key (required; never committed to source)
/// - `BENCH_APP_USER_ID`: app user ID for this launch
/// - `--wipe-state` argument: delete all SDK disk state before configuring (cold launch)
@main
struct SDKConfigBenchmarkApp: App {

    private let clock: LaunchClock
    @StateObject private var model: LaunchModel

    init() {
        // Wipe before anchoring the clock: harness cleanup I/O must never count as SDK
        // launch time (it would inflate every cold phase by the previous launch's litter).
        if CommandLine.arguments.contains("--wipe-state") {
            Self.wipeSDKState()
        }

        let clock = LaunchClock()
        self.clock = clock

        let environment = ProcessInfo.processInfo.environment
        let model = LaunchModel(clock: clock)
        self._model = StateObject(wrappedValue: model)

        guard let apiKey = environment["BENCH_API_KEY"], !apiKey.isEmpty else {
            model.fail("BENCH_API_KEY missing from launch environment")
            return
        }

        // The config path (config persisted, each blob stored inline vs downloaded) is only
        // observable through the SDK's log stream, so run verbose and parse. The logging
        // overhead is inside the measured window but identical across variants.
        let observer = model.blobObserver
        Purchases.logLevel = .verbose
        Purchases.verboseLogHandler = { _, message, _, _, _ in
            observer.ingest(message)
        }
        Purchases.configure(
            with: .builder(withAPIKey: apiKey)
                .with(appUserID: environment["BENCH_APP_USER_ID"])
                .build()
        )
        model.recordConfigured()
        // The impression event fires when the paywall CONTENT view appears (resolved paywall
        // or explicit fallback), unlike the wrapper's onAppear, which can precede it while a
        // loading state shows. It is the headline "user sees the paywall" mark.
        Purchases.shared.eventsListener = model.impressionListener
        model.startObserving()
    }

    var body: some Scene {
        WindowGroup {
            LaunchView(model: self.model)
        }
    }

    /// Deletes every place the SDK persists state so the next configure is a true cold start.
    private static func wipeSDKState() {
        let fileManager = FileManager.default
        for directory in [FileManager.SearchPathDirectory.cachesDirectory, .applicationSupportDirectory] {
            guard let root = fileManager.urls(for: directory, in: .userDomainMask).first,
                  let contents = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            else { continue }
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        let sdkSuite = SDKObservedValues.revenueCatUserDefaultsSuiteName
        UserDefaults(suiteName: sdkSuite)?.removePersistentDomain(forName: sdkSuite)
    }

}

/// Drives the measured phases after configure and publishes the finished sample.
@MainActor
final class LaunchModel: ObservableObject {

    @Published private(set) var offering: Offering?
    @Published private(set) var finishedSampleJSON: String?

    let blobObserver: BlobObserver
    /// Retained here: the SDK does not keep the events listener alive.
    private(set) var impressionListener: PaywallImpressionListener!

    private let clock: LaunchClock
    private var sample = LaunchSample()
    private var paywallAppeared = false

    init(clock: LaunchClock) {
        self.clock = clock
        self.blobObserver = BlobObserver(clock: clock)
        self.impressionListener = PaywallImpressionListener(clock: clock) { [weak self] elapsedMs in
            Task { @MainActor in
                self?.recordPaywallImpression(elapsedMs: elapsedMs)
            }
        }
    }

    nonisolated func fail(_ message: String) {
        Task { @MainActor in
            self.sample.error = message
            self.finish()
        }
    }

    nonisolated func recordConfigured() {
        let elapsed = self.clock.elapsedMs()
        Task { @MainActor in
            self.sample.configuredMs = elapsed
        }
    }

    nonisolated func startObserving() {
        Task { @MainActor in
            await self.observeLaunch()
        }
    }

    private func observeLaunch() async {
        async let customerInfo: Void = self.awaitFirstCustomerInfo()

        do {
            let offerings = try await Purchases.shared.offerings()
            self.sample.offeringsMs = self.clock.elapsedMs()
            guard let current = offerings.current else {
                throw NSError(
                    domain: "SDKConfigBenchmarkApp",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "project has no current offering"]
                )
            }
            self.offering = current
        } catch {
            self.sample.error = String(describing: error)
            self.finish()
        }

        await customerInfo
        self.finishIfComplete()
    }

    private func awaitFirstCustomerInfo() async {
        for await _ in Purchases.shared.customerInfoStream {
            self.sample.customerInfoMs = self.clock.elapsedMs()
            break
        }
    }

    func recordPaywallAppeared() {
        guard !self.paywallAppeared else { return }
        self.paywallAppeared = true
        self.sample.paywallAppearedMs = self.clock.elapsedMs()
        self.finishIfComplete()
    }

    private func recordPaywallImpression(elapsedMs: Double) {
        guard self.sample.paywallImpressionMs == nil else { return }
        self.sample.paywallImpressionMs = elapsedMs
        self.finishIfComplete()
    }

    private func finishIfComplete() {
        guard self.finishedSampleJSON == nil else { return }
        let done = self.sample.customerInfoMs != nil
            && self.sample.offeringsMs != nil
            && self.sample.paywallAppearedMs != nil
            && self.sample.paywallImpressionMs != nil
        if done {
            self.finish()
        }
    }

    private func finish() {
        guard self.finishedSampleJSON == nil else { return }
        self.blobObserver.apply(to: &self.sample)
        let json = self.sample.jsonString()
        self.finishedSampleJSON = json
        // Also visible in the unified log for smoke testing without the XCUITest runner.
        NSLog("BENCH_SAMPLE %@", json)
    }

}

/// Stamps the moment the SDK tracks that paywall content actually appeared (via the SDK's
/// internal events listener SPI), unlike the wrapper's `onAppear`, which can fire while a
/// loading state still shows. A classic paywall tracks `paywall_impression`; a workflow
/// paywall tracks `workflows_step_started` when its first step renders.
final class PaywallImpressionListener: EventsListener {

    private let clock: LaunchClock
    private let onImpression: (Double) -> Void

    init(clock: LaunchClock, onImpression: @escaping (Double) -> Void) {
        self.clock = clock
        self.onImpression = onImpression
    }

    func onEventTracked(_ event: [String: Any]) {
        guard let type = event["type"] as? String,
              SDKObservedValues.contentAppearedEventTypes.contains(type) else { return }
        self.onImpression(self.clock.elapsedMs())
    }

}

struct LaunchView: View {

    @ObservedObject var model: LaunchModel

    var body: some View {
        ZStack {
            if let offering = self.model.offering {
                PaywallView(offering: offering)
                    .onAppear {
                        self.model.recordPaywallAppeared()
                    }
            } else {
                ProgressView()
            }

            if let json = self.model.finishedSampleJSON {
                // The runner reads the sample from this element's label.
                Text(json)
                    .font(.system(size: 4))
                    .opacity(0.02)
                    .accessibilityIdentifier("benchmark-result")
            }
        }
    }

}
