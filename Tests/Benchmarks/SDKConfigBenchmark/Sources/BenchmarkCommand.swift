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

    var mode: BenchmarkMode = .legacy
    var scenario: BenchmarkScenario = .cold
    var profileName: String = "ideal"
    var lossPercent: Int = 0
    var iterations: Int = 25
    var warmupIterations: Int = 3
    var paywallCount: Int = 50
    var workflowCount: Int = 100
    var seed: UInt64 = 42
    var appUserID: String = "benchmark-user"
    var apiKey: String = "appl_benchmark"
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
            case "--annotation":
                let raw = try value(for: flag)
                let parts = raw.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2, !parts[0].isEmpty else {
                    throw BenchmarkError.invalidArgument("--annotation expects key=value, got \(raw)")
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

        return command
    }

}
