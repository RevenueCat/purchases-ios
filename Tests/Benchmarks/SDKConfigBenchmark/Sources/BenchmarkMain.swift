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

        // Every run gets its own disk-cache root: the SDK's container directories ignore
        // $HOME, so this is the only way concurrent runs stay isolated (and the user's real
        // Library stays clean).
        let diskRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("SDKConfigBenchmark-\(UUID().uuidString)", isDirectory: true)
        DirectoryHelper.benchmarkBaseDirectoryOverride = diskRoot

        func finish(exitCode: Int32) -> Never {
            try? FileManager.default.removeItem(at: diskRoot)
            exit(exitCode)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try BenchmarkRunner(command: command).run()
                print(result.jsonlRow)
                if result.postWarmupErrorCount > 0 {
                    let message = "\(result.postWarmupErrorCount) post-warmup iteration(s) failed; " +
                        "timings are not valid comparison input\n"
                    FileHandle.standardError.write(Data(message.utf8))
                    finish(exitCode: 2)
                }
                finish(exitCode: 0)
            } catch {
                FileHandle.standardError.write(Data("\(error)\n".utf8))
                finish(exitCode: 1)
            }
        }

        dispatchMain()
    }

}
