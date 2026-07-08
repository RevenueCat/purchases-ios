import XCTest

@testable import SDKConfigBenchmarkCore

/// Minimal base class for benchmark harness tests. The benchmark test target does not link
/// the main UnitTests infrastructure, so it carries its own `XCTestCase` subclass to satisfy
/// the repo convention that test classes never inherit `XCTestCase` directly.
///
/// Every test gets a fresh disk-cache root so tests never touch the real user Library and
/// never see each other's (or a previous run's) cached state.
// swiftlint:disable:next xctestcase_superclass
class BenchmarkTestCase: XCTestCase {

    private var diskRoot: URL!

    override func setUp() {
        super.setUp()
        self.diskRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("SDKConfigBenchmarkTests-\(UUID().uuidString)", isDirectory: true)
        DirectoryHelper.benchmarkBaseDirectoryOverride = self.diskRoot
    }

    override func tearDown() {
        DirectoryHelper.benchmarkBaseDirectoryOverride = nil
        if let diskRoot = self.diskRoot {
            try? FileManager.default.removeItem(at: diskRoot)
        }
        super.tearDown()
    }

}
