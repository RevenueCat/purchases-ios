import Foundation

enum BenchmarkMode: String, CaseIterable {

    case legacy
    case config
    case configKillswitch = "config-killswitch"

    /// Whether a `RemoteConfigManager` stack is wired into the offerings flow.
    var usesRemoteConfig: Bool {
        switch self {
        case .legacy: return false
        case .config, .configKillswitch: return true
        }
    }

    /// Whether the fixture forces `/v1/config` to fail with a 4xx (the kill switch).
    var forcesConfigFailure: Bool {
        return self == .configKillswitch
    }

    /// Whether warm iterations must revalidate config via manifest 204s. Kill-switch mode
    /// pays a 4xx on every launch instead, by design.
    var expectsWarmConfigRevalidation: Bool {
        return self == .config
    }

}

enum BenchmarkTransport: String, CaseIterable {

    /// In-process fixture transport: deterministic, seedable, supports profiles, loss, and the
    /// forced kill-switch 4xx.
    case simulated

    /// Real requests against the production backend, recorded for metrics. Pinned to the
    /// prepared stress-test project (`BenchmarkProject`).
    case live

}

/// The canonical RevenueCat project live runs measure against:
/// https://app.revenuecat.com/projects/5f07e7e3 ("Stress Test Config Endpoint"), prepared with
/// a large number of paywalls and workflows. Keys are the project's client-side public SDK
/// keys, hardcoded on purpose so every live run measures the same content. The Test Store key
/// is the default because the project's packages live on its Test Store app; the App Store app
/// has no products registered, which makes `OfferingsManager` fail with a configuration error.
enum BenchmarkProject {

    static let projectID = "5f07e7e3"
    static let dashboardURL = "https://app.revenuecat.com/projects/5f07e7e3"
    static let testStoreAPIKey = "REDACTED_RESOLVED_VIA_MAFDET"
    static let appStoreAPIKey = "REDACTED_RESOLVED_VIA_MAFDET"

}

enum BenchmarkScenario: String, CaseIterable {

    /// Every iteration starts with empty disk caches and a fresh app user ID.
    case cold

    /// Disk caches are primed once, then every iteration simulates an app relaunch:
    /// fresh in-memory state, retained disk state, same app user ID. The fixture
    /// serves 304 (offerings) and 204 (config) when the SDK proves it has current data.
    case warm

}

struct BenchmarkCommand {

    static let defaultSimulatedAPIKey = "appl_benchmark"

    /// Keys `jsonlRow` writes itself; annotations must never overwrite them, or a row could
    /// lie about what was measured (e.g. `--annotation mode=legacy` on a config run).
    static let reservedRowKeys: Set<String> = [
        "mode", "transport", "scenario", "profile", "loss_percent", "paywalls", "workflows",
        "seed", "iterations", "warmup_discarded", "measured_iterations", "error_count",
        "post_warmup_error_count", "mean_ms", "min_ms", "max_ms", "p50_ms", "p90_ms", "p95_ms",
        "p99_ms", "request_count_mean", "bytes_received_mean", "failed_requests_total",
        "fallback_host_requests_total", "offerings_ms_mean", "config_ms_mean", "blob_ms_mean",
        "first_error", "project_id"
    ]

    var mode: BenchmarkMode = .legacy
    var transport: BenchmarkTransport = .simulated
    var scenario: BenchmarkScenario = .cold
    var profileName: String = "ideal"
    var lossPercent: Int = 0
    var iterations: Int = 25
    var warmupIterations: Int = 3
    var paywallCount: Int = 50
    var workflowCount: Int = 100
    var seed: UInt64 = 42
    var appUserID: String = "benchmark-user"
    var apiKey: String = BenchmarkCommand.defaultSimulatedAPIKey
    /// Which RevenueCat project a live run measures; labels the row so results from different
    /// projects can never be compared as equivalents. Nil for simulated runs.
    var projectID: String?
    /// Extra key=value pairs echoed verbatim into the JSONL row (e.g. sdk_commit=abc123).
    var annotations: [String: String] = [:]

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func parse(_ args: [String]) throws -> BenchmarkCommand {
        var command = BenchmarkCommand()
        var index = 0

        func value(for flag: String) throws -> String {
            index += 1
            guard index < args.count else {
                throw BenchmarkError.invalidArgument("\(flag) requires a value")
            }
            return args[index]
        }

        func intValue(for flag: String, in range: ClosedRange<Int>) throws -> Int {
            let raw = try value(for: flag)
            guard let parsed = Int(raw), range.contains(parsed) else {
                throw BenchmarkError.invalidArgument("\(flag) must be an integer in \(range), got \(raw)")
            }
            return parsed
        }

        while index < args.count {
            let flag = args[index]
            switch flag {
            case "--mode":
                let raw = try value(for: flag)
                guard let mode = BenchmarkMode(rawValue: raw) else {
                    throw BenchmarkError.invalidArgument("unknown mode \(raw)")
                }
                command.mode = mode
            case "--transport":
                let raw = try value(for: flag)
                guard let transport = BenchmarkTransport(rawValue: raw) else {
                    throw BenchmarkError.invalidArgument("unknown transport \(raw)")
                }
                command.transport = transport
            case "--scenario":
                let raw = try value(for: flag)
                guard let scenario = BenchmarkScenario(rawValue: raw) else {
                    throw BenchmarkError.invalidArgument("unknown scenario \(raw)")
                }
                command.scenario = scenario
            case "--profile":
                command.profileName = try value(for: flag)
            case "--loss-percent":
                command.lossPercent = try intValue(for: flag, in: 0...100)
            case "--iterations":
                command.iterations = try intValue(for: flag, in: 1...100_000)
            case "--warmup-iterations":
                command.warmupIterations = try intValue(for: flag, in: 0...1_000)
            case "--paywalls":
                command.paywallCount = try intValue(for: flag, in: 1...10_000)
            case "--workflows":
                command.workflowCount = try intValue(for: flag, in: 0...10_000)
            case "--seed":
                let raw = try value(for: flag)
                guard let seed = UInt64(raw) else {
                    throw BenchmarkError.invalidArgument("--seed must be an unsigned integer, got \(raw)")
                }
                command.seed = seed
            case "--app-user-id":
                command.appUserID = try value(for: flag)
            case "--api-key":
                command.apiKey = try value(for: flag)
            case "--project-id":
                command.projectID = try value(for: flag)
            case "--annotation":
                let raw = try value(for: flag)
                let parts = raw.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2, !parts[0].isEmpty else {
                    throw BenchmarkError.invalidArgument("--annotation expects key=value, got \(raw)")
                }
                guard !Self.reservedRowKeys.contains(parts[0]) else {
                    throw BenchmarkError.invalidArgument("--annotation key \(parts[0]) is a reserved row field")
                }
                command.annotations[parts[0]] = parts[1]
            default:
                throw BenchmarkError.invalidArgument("unknown flag \(flag)")
            }
            index += 1
        }

        guard command.warmupIterations < command.iterations else {
            throw BenchmarkError.invalidArgument(
                "--warmup-iterations (\(command.warmupIterations)) must be below --iterations (\(command.iterations))"
            )
        }

        try command.validateAndDefaultTransport()

        return command
    }

    /// Live runs hit the real backend: the knobs that shape the simulated network (and the
    /// forced kill-switch 4xx) cannot apply there, and the API key defaults to the pinned
    /// stress-test project.
    private mutating func validateAndDefaultTransport() throws {
        guard self.transport == .live else {
            guard self.projectID == nil else {
                throw BenchmarkError.invalidArgument("--project-id only applies to --transport live")
            }
            return
        }

        guard self.lossPercent == 0 else {
            throw BenchmarkError.invalidArgument("--loss-percent requires --transport simulated")
        }
        guard self.profileName == "ideal" else {
            throw BenchmarkError.invalidArgument(
                "--profile requires --transport simulated; live runs use the real network"
            )
        }
        guard !self.mode.forcesConfigFailure else {
            throw BenchmarkError.invalidArgument(
                "config-killswitch cannot force a 4xx on the real backend; use --transport simulated"
            )
        }

        if self.apiKey == Self.defaultSimulatedAPIKey {
            self.apiKey = BenchmarkProject.testStoreAPIKey
            self.projectID = self.projectID ?? BenchmarkProject.projectID
        } else if self.projectID == nil {
            // A custom key without a project label would let rows from different projects
            // collide in comparisons.
            throw BenchmarkError.invalidArgument("--api-key with --transport live also requires --project-id")
        }

        // Fixture-size knobs don't shape live payloads (the pinned project's real content
        // does), so rows carry 0 rather than a fixture size that was never measured.
        self.paywallCount = 0
        self.workflowCount = 0
    }

}
