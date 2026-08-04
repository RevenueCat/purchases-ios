import Foundation

/// Demo-only workflow loading. Production workflows are fetched from RevenueCat's server.
enum DemoWorkflowLoader {

    private static let workflowIdentifiers = [
        "result_picker",
        "soft_paywall",
        "hard_paywall",
        "onboarding"
    ]

    static func loadBundledWorkflowData() -> [String: Data] {
        return Dictionary(
            uniqueKeysWithValues: Self.workflowIdentifiers.compactMap { identifier in
                guard let url = Bundle.main.url(forResource: identifier, withExtension: "json"),
                      let data = try? Data(contentsOf: url) else {
                    return nil
                }
                return (identifier, data)
            }
        )
    }

}
