import Foundation

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

    func run() throws -> String {
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
                killSwitchConfig: self.command.mode == .configKillswitch
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
            } catch let error as BenchmarkError {
                if case .scenarioViolation = error { throw error }
                metrics.record(error: error, iteration: iteration)
            } catch {
                metrics.record(error: error, iteration: iteration)
            }
        }

        return metrics.jsonlRow(for: self.command)
    }

}

private extension BenchmarkRunner {

    /// Live runs get a per-run nonce so reruns never share server-side per-user state with a
    /// previous run; simulated runs stay fully deterministic.
    private static let liveRunNonce = String(Int(Date().timeIntervalSince1970))

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

        let totalMs = try self.launch(stack, appUserID: appUserID)

        return IterationMeasurement(
            totalMs: totalMs,
            events: SimulatedTransportURLProtocol.drainEvents()
        )
    }

    /// One simulated launch; returns start-to-offerings-delivered wall time in milliseconds.
    /// Runs off the main thread; the offerings completion is delivered on the main queue, which
    /// `BenchmarkMain` keeps pumping via `dispatchMain()`.
    func launch(_ stack: BenchmarkSDKStack, appUserID: String) throws -> Double {
        let start = DispatchTime.now()
        stack.refreshRemoteConfigIfWired()

        let semaphore = DispatchSemaphore(value: 0)
        let failure = Atomic<OfferingsManager.Error?>(nil)
        stack.offeringsManager.offerings(appUserID: appUserID) { result in
            if case let .failure(error) = result {
                failure.value = error
            }
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + 120) == .success else {
            throw BenchmarkError.timeout("offerings fetch")
        }
        if let error = failure.value {
            throw BenchmarkError.backendFailure("offerings fetch failed: \(error)")
        }

        let end = DispatchTime.now()
        return Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }

    /// Warm runs must prove that EVERY measured iteration hit the revalidation paths; a single
    /// iteration silently falling back to full 200 responses or re-downloading blobs would mix
    /// cold behavior into the warm distribution.
    func validateScenario(_ measurement: IterationMeasurement, iteration: Int) throws {
        guard self.command.scenario == .warm, self.command.lossPercent == 0 else { return }
        try Self.validateWarmMeasurement(measurement, mode: self.command.mode, iteration: iteration)
    }

}

extension BenchmarkRunner {

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

        // Kill-switch mode pays the config 4xx on every launch by design, so only plain config
        // mode must see manifest 204s.
        if mode == .config {
            guard !measurement.configStatusCodes.isEmpty,
                  measurement.configStatusCodes.allSatisfy({ $0 == 204 }) else {
                throw BenchmarkError.scenarioViolation(
                    "warm iteration \(iteration) did not revalidate config via manifest 204 " +
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
