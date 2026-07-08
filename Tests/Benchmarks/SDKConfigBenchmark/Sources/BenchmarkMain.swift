import Foundation

// BenchmarkMain hosts only static members, but it cannot be the caseless enum that
// `convenience_type` wants because the repo bans new public enums outright.
// swiftlint:disable convenience_type

/// The single public entry point for the `SDKConfigBenchmark` executable target.
/// Everything else in this module stays internal; the executable is one call into here.
public struct BenchmarkMain {

    /// Parses `CommandLine.arguments`, runs the requested benchmark, prints one JSONL row
    /// to stdout, and terminates the process (0 on success, 1 on error).
    public static func run() -> Never {
        do {
            let command = try BenchmarkCommand.parse(Array(CommandLine.arguments.dropFirst()))
            // Placeholder output until the runner lands; proves parsing and target wiring.
            print("parsed mode=\(command.mode.rawValue) scenario=\(command.scenario.rawValue) " +
                  "profile=\(command.profileName) iterations=\(command.iterations)")
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
    }

}
