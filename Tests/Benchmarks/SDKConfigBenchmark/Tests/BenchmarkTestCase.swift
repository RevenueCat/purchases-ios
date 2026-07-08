import XCTest

/// Minimal base class for benchmark harness tests. The benchmark test target does not link
/// the main UnitTests infrastructure, so it carries its own `XCTestCase` subclass to satisfy
/// the repo convention that test classes never inherit `XCTestCase` directly.
// swiftlint:disable:next xctestcase_superclass
class BenchmarkTestCase: XCTestCase {}
