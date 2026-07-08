import Foundation

// BenchmarkMain hosts only static members, but it cannot be the caseless enum that
// `convenience_type` wants because the repo bans new public enums outright.
// swiftlint:disable convenience_type

/// The single public entry point for the `SDKConfigBenchmark` executable target.
/// Everything else in this module stays internal; the executable is one call into here.
public struct BenchmarkMain {

    /// Parses `CommandLine.arguments`, runs the requested benchmark, prints one JSONL row
    /// to stdout, and terminates the process (0 on success, 1 on error).
    ///
    /// The benchmark itself runs on a background queue while the main thread sits in
    /// `dispatchMain()`: `OfferingsManager` delivers its completion on the main queue, so
    /// blocking the main thread on the run would deadlock every iteration.
    public static func run() -> Never {
        let command: BenchmarkCommand
        do {
            command = try BenchmarkCommand.parse(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let row = try BenchmarkRunner(command: command).run()
                print(row)
                exit(0)
            } catch {
                FileHandle.standardError.write(Data("\(error)\n".utf8))
                exit(1)
            }
        }

        dispatchMain()
    }

}
