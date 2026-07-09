import Foundation

struct BenchmarkRunResult {

    let jsonlRow: String
    /// Nonzero means the row is visible but its timings are not valid comparison input.
    let postWarmupErrorCount: Int

}

/// Drives one benchmark configuration: N simulated app launches through the real SDK stack,
/// against the simulated transport, producing a single JSONL row.
///
/// An iteration is one launch: build a fresh stack (fresh in-memory state, like a new process),
/// kick the remote config refresh when wired, fetch offerings, and stop the clock when the
/// offerings completion fires. `cold` wipes disk state before every iteration and uses a
/// per-iteration app user ID; `warm` primes disk once, then relaunches against retained disk
/// state, which must revalidate via 304 (offerings) and 204 (config) or the run fails loudly
/// rather than silently measuring cold behavior.
final class BenchmarkRunner {

    private let command: BenchmarkCommand

    init(command: BenchmarkCommand) {
        self.command = command
    }

    func run() throws -> BenchmarkRunResult {
        switch self.command.transport {
        case .simulated:
            guard let profile = NetworkProfile.named(self.command.profileName) else {
                throw BenchmarkError.invalidArgument("unknown profile \(self.command.profileName)")
            }
            let factory = BenchmarkPayloadFactory(
                paywallCount: self.command.paywallCount,
                workflowCount: self.command.workflowCount
            )
            let server = FixtureServer(
                factory: factory,
                killSwitchConfig: self.command.mode.forcesConfigFailure
            )
            SimulatedTransportURLProtocol.install(
                server: server,
                profile: profile,
                loss: LossModel(lossPercent: self.command.lossPercent),
                seed: self.command.seed
            )
        case .live:
            // Requests hit the real backend (the pinned stress-test project) through a
            // recording passthrough, so live rows carry the same per-request metrics.
            SimulatedTransportURLProtocol.installPassthrough()
        }
        defer { SimulatedTransportURLProtocol.uninstall() }

        var metrics = BenchmarkMetrics()

        if self.command.scenario == .warm {
            try self.primeDiskState()
        }

        for iteration in 0..<self.command.iterations {
            SimulatedTransportURLProtocol.beginIteration(iteration)
            do {
                let measurement = try self.runIteration(iteration)
                if iteration >= self.command.warmupIterations {
                    try self.validateScenario(measurement, iteration: iteration)
                }
                metrics.record(measurement, iteration: iteration)
            } catch {
                if case BenchmarkError.scenarioViolation = error { throw error }
                metrics.record(error: error, iteration: iteration)
            }
        }

        return BenchmarkRunResult(
            jsonlRow: metrics.jsonlRow(for: self.command),
            postWarmupErrorCount: metrics.postWarmupErrorCount(warmupIterations: self.command.warmupIterations)
        )
    }

}

private extension BenchmarkRunner {

    /// Live runs get a per-run nonce so reruns (even parallel or same-second ones) never share
    /// server-side per-user state; simulated runs stay fully deterministic.
    private static let liveRunNonce = String(UUID().uuidString.prefix(8))

    var baseAppUserID: String {
        switch self.command.transport {
        case .simulated:
            return self.command.appUserID
        case .live:
            return "\(self.command.appUserID)-\(Self.liveRunNonce)"
        }
    }

    func appUserID(forIteration iteration: Int) -> String {
        switch self.command.scenario {
        case .cold:
            return "\(self.baseAppUserID)-\(iteration)"
        case .warm:
            return self.baseAppUserID
        }
    }

    /// Uncounted launch that fills the disk caches the warm iterations relaunch against.
    func primeDiskState() throws {
        SimulatedTransportURLProtocol.beginIteration(-1)
        let stack = BenchmarkSDKStack(
            mode: self.command.mode,
            apiKey: self.command.apiKey,
            appUserID: self.baseAppUserID
        )
        stack.clearAllDiskState()
        _ = try self.launch(stack, appUserID: self.baseAppUserID)
        SimulatedTransportURLProtocol.waitUntilIdle()
        _ = SimulatedTransportURLProtocol.drainEvents()
    }

    func runIteration(_ iteration: Int) throws -> IterationMeasurement {
        let appUserID = self.appUserID(forIteration: iteration)
        let stack = BenchmarkSDKStack(
            mode: self.command.mode,
            apiKey: self.command.apiKey,
            appUserID: appUserID
        )
        if self.command.scenario == .cold {
            stack.clearAllDiskState()
        }
        _ = SimulatedTransportURLProtocol.drainEvents()
        let blobRefsBeforeLaunch = stack.blobStore?.cachedRefs() ?? []

        let totalMs: Double
        do {
            totalMs = try self.launch(stack, appUserID: appUserID)
        } catch {
            // Quiet the failed stack so its in-flight work stops churning; any straggler
            // events it still produces carry this iteration's stamp and are filtered out of
            // later measurements below.
            stack.remoteConfigManager?.close()
            throw error
        }

        // The clock stopped at offerings delivery, but trailing requests from this launch
        // (e.g. the warm config 204 that finishes after offerings, matching production order)
        // still belong to this iteration's accounting: collect until the transport is idle
        // AND the config request (when wired) has landed, then keep only this iteration's
        // events so stragglers from earlier launches can't inflate the row.
        let events = self.collectEvents(forIteration: iteration)
        return IterationMeasurement(
            totalMs: totalMs,
            events: events,
            blobAccounting: Self.blobAccounting(
                blobStore: stack.blobStore,
                refsBeforeLaunch: blobRefsBeforeLaunch,
                events: events
            )
        )
    }

    /// Drains transport events until quiescence, additionally waiting (bounded) for this
    /// iteration's config request in config modes: transport idleness alone can race the gap
    /// between kicking the refresh and its request reaching the transport.
    func collectEvents(forIteration iteration: Int, timeoutMs: Int = 15_000) -> [TransportEvent] {
        var events: [TransportEvent] = []
        let deadline = DispatchTime.now() + .milliseconds(timeoutMs)

        while true {
            SimulatedTransportURLProtocol.waitUntilIdle()
            events += SimulatedTransportURLProtocol.drainEvents()

            let configLanded = events.contains { $0.iteration == iteration && $0.kind == .config }
            if !self.command.mode.usesRemoteConfig || configLanded || DispatchTime.now() >= deadline {
                break
            }
            usleep(5_000)
        }

        return events.filter { $0.iteration == iteration }
    }

    /// One simulated launch; returns start-to-offerings-delivered wall time in milliseconds.
    /// Runs off the main thread; the offerings completion is delivered on the main queue, which
    /// `BenchmarkMain` keeps pumping via `dispatchMain()`.
    ///
    /// This calls the exact pair `Purchases.updateAllCaches` calls, in the same order:
    /// `updateOfferingsCache` (which enqueues the offerings operation synchronously, before
    /// this method moves on) and then `refreshRemoteConfig`. Both land on the same serial
    /// backend queue and single-connection host pool, so enqueue order shapes the measured
    /// serialization; using `offerings(appUserID:)` instead would hop through the main actor
    /// first and let the config request race ahead.
    func launch(_ stack: BenchmarkSDKStack, appUserID: String) throws -> Double {
        let start = DispatchTime.now()

        let semaphore = DispatchSemaphore(value: 0)
        let failure = Atomic<OfferingsManager.Error?>(nil)
        stack.offeringsManager.updateOfferingsCache(appUserID: appUserID, isAppBackgrounded: false) { result in
            if case let .failure(error) = result {
                failure.value = error
            }
            semaphore.signal()
        }
        stack.refreshRemoteConfigIfWired()

        guard semaphore.wait(timeout: .now() + 120) == .success else {
            throw BenchmarkError.timeout("offerings fetch")
        }
        if let error = failure.value {
            throw BenchmarkError.backendFailure("offerings fetch failed: \(error)")
        }

        let end = DispatchTime.now()
        return Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }

    /// Every measured iteration must prove it exercised the path its row claims: warm runs
    /// must hit the revalidation paths, and cold config runs must complete a successful
    /// config request (a failed refresh silently delivers offerings via the legacy fallback,
    /// which would let a "config" row measure the wrong system). Skipped under packet loss,
    /// where transient failures are the thing being measured.
    func validateScenario(_ measurement: IterationMeasurement, iteration: Int) throws {
        guard self.command.lossPercent == 0 else { return }
        switch self.command.scenario {
        case .warm:
            try Self.validateWarmMeasurement(measurement, mode: self.command.mode, iteration: iteration)
        case .cold:
            try Self.validateColdMeasurement(measurement, mode: self.command.mode, iteration: iteration)
        }
    }

}

extension BenchmarkRunner {

    /// Attributes this iteration's newly stored blobs (all disk reads happen after the timed
    /// window): a new ref with a successful blob request was downloaded; any other new ref can
    /// only have arrived inline in the config container.
    static func blobAccounting(
        blobStore: RemoteConfigBlobStoreType?,
        refsBeforeLaunch: Set<String>,
        events: [TransportEvent]
    ) -> BlobAccounting {
        guard let blobStore else { return .empty }

        let newRefs = blobStore.cachedRefs().subtracting(refsBeforeLaunch)
        guard !newRefs.isEmpty else { return .empty }

        let downloadedRefs = Set(
            events
                .filter { $0.kind == .blob && !$0.failed }
                .map { ($0.path as NSString).lastPathComponent }
        )
        let newRefSizes = newRefs.reduce(into: [String: Int]()) { sizes, ref in
            sizes[ref] = blobStore.read(ref: ref)?.count ?? 0
        }
        return BlobAccounting(newRefSizes: newRefSizes, downloadedRefs: downloadedRefs)
    }

    /// Cold config iterations must have actually completed the config exchange their mode
    /// claims: a success for plain config mode, the disabling 4xx for the kill switch.
    static func validateColdMeasurement(
        _ measurement: IterationMeasurement,
        mode: BenchmarkMode,
        iteration: Int
    ) throws {
        guard mode.usesRemoteConfig else { return }

        if mode.forcesConfigFailure {
            guard !measurement.configStatusCodes.isEmpty,
                  measurement.configStatusCodes.allSatisfy({ (400...499).contains($0) }) else {
                throw BenchmarkError.scenarioViolation(
                    "cold kill-switch iteration \(iteration) did not hit the config 4xx " +
                    "(statuses: \(measurement.configStatusCodes))"
                )
            }
            return
        }

        guard measurement.configStatusCodes.contains(where: { (200...299).contains($0) }) else {
            throw BenchmarkError.scenarioViolation(
                "cold config iteration \(iteration) never completed a successful config request " +
                "(statuses: \(measurement.configStatusCodes)); the row would measure legacy fallback"
            )
        }
    }

    static func validateWarmMeasurement(
        _ measurement: IterationMeasurement,
        mode: BenchmarkMode,
        iteration: Int
    ) throws {
        guard !measurement.offeringsStatusCodes.isEmpty,
              measurement.offeringsStatusCodes.allSatisfy({ $0 == 304 }) else {
            throw BenchmarkError.scenarioViolation(
                "warm iteration \(iteration) did not revalidate offerings via 304 " +
                "(statuses: \(measurement.offeringsStatusCodes))"
            )
        }

        // Plain config mode must revalidate via manifest 204s; kill-switch mode must pay the
        // disabling 4xx on every launch (each iteration is a fresh manager, so the switch
        // trips again). Anything else means the mode isn't measuring what it claims.
        if mode.expectsWarmConfigRevalidation {
            guard !measurement.configStatusCodes.isEmpty,
                  measurement.configStatusCodes.allSatisfy({ $0 == 204 }) else {
                throw BenchmarkError.scenarioViolation(
                    "warm iteration \(iteration) did not revalidate config via manifest 204 " +
                    "(statuses: \(measurement.configStatusCodes))"
                )
            }
        }
        if mode.forcesConfigFailure {
            guard !measurement.configStatusCodes.isEmpty,
                  measurement.configStatusCodes.allSatisfy({ (400...499).contains($0) }) else {
                throw BenchmarkError.scenarioViolation(
                    "warm kill-switch iteration \(iteration) did not hit the config 4xx " +
                    "(statuses: \(measurement.configStatusCodes))"
                )
            }
        }

        guard measurement.blobRequestCount == 0 else {
            throw BenchmarkError.scenarioViolation(
                "warm iteration \(iteration) re-downloaded \(measurement.blobRequestCount) blob(s)"
            )
        }
    }

}
