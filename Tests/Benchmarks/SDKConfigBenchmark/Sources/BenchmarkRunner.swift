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
        defer { SimulatedTransportURLProtocol.uninstall() }

        var metrics = BenchmarkMetrics()

        if self.command.scenario == .warm {
            try self.primeDiskState()
        }

        for iteration in 0..<self.command.iterations {
            do {
                metrics.record(try self.runIteration(iteration))
            } catch {
                metrics.record(error: error)
            }
        }

        try self.verifyScenario(metrics)

        return metrics.jsonlRow(for: self.command)
    }

}

private extension BenchmarkRunner {

    func appUserID(forIteration iteration: Int) -> String {
        switch self.command.scenario {
        case .cold:
            return "\(self.command.appUserID)-\(iteration)"
        case .warm:
            return self.command.appUserID
        }
    }

    /// Uncounted launch that fills the disk caches the warm iterations relaunch against.
    func primeDiskState() throws {
        let stack = BenchmarkSDKStack(
            mode: self.command.mode,
            apiKey: self.command.apiKey,
            appUserID: self.command.appUserID
        )
        stack.clearAllDiskState()
        _ = try self.launch(stack, appUserID: self.command.appUserID)
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

    /// Warm runs must prove they actually hit the revalidation paths.
    func verifyScenario(_ metrics: BenchmarkMetrics) throws {
        guard self.command.scenario == .warm, self.command.lossPercent == 0 else { return }

        let statuses = Set(metrics.allStatusCodes)
        guard statuses.contains(304) else {
            throw BenchmarkError.scenarioViolation("warm run never revalidated offerings via 304")
        }
        if self.command.mode == .config, !statuses.contains(204) {
            throw BenchmarkError.scenarioViolation("warm config run never revalidated via manifest 204")
        }
    }

}
