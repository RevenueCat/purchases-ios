import Foundation

enum BenchmarkError: Error, CustomStringConvertible {

    case invalidArgument(String)
    case invalidFixture(String)
    case timeout(String)
    case backendFailure(String)
    case scenarioViolation(String)

    var description: String {
        switch self {
        case let .invalidArgument(message): return "Invalid argument: \(message)"
        case let .invalidFixture(message): return "Invalid fixture: \(message)"
        case let .timeout(operation): return "Timed out waiting for \(operation)"
        case let .backendFailure(message): return "Backend failure: \(message)"
        case let .scenarioViolation(message): return "Scenario violation: \(message)"
        }
    }

}
