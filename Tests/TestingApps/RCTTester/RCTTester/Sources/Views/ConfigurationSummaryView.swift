//
//  ConfigurationSummaryView.swift
//  RCTTester
//

import SwiftUI

struct ConfigurationSummaryView: View {

    @Binding var configuration: SDKConfiguration

    // MARK: - Body

    var body: some View {
        Group {
            ConfigurationRow(label: "API Key", value: redactedAPIKey, monospace: true)
            ConfigurationRow(label: "StoreKit Version", value: configuration.storeKitVersion.displayName)
            ConfigurationRow(label: "Purchases Completed By", value: configuration.purchasesAreCompletedBy.displayName)

            if configuration.purchasesAreCompletedBy == .myApp {
                ConfigurationRow(label: "Purchase Logic", value: configuration.purchaseLogic.displayName)
            }
        }
    }

    // MARK: - Helpers

    private var redactedAPIKey: String {
        let apiKey = configuration.apiKey
        guard !apiKey.isEmpty else { return "—" }

        let prefix: String
        if let underscoreIndex = apiKey.firstIndex(of: "_") {
            prefix = String(apiKey[...underscoreIndex])
        } else {
            prefix = String(apiKey.prefix(4))
        }

        let suffix = String(apiKey.suffix(4))

        // Avoid showing duplicates if key is too short
        if apiKey.count <= prefix.count + 4 {
            return apiKey
        }

        return "\(prefix)•••••\(suffix)"
    }
}

// MARK: - Configuration Row

private struct ConfigurationRow: View {
    let label: String
    let value: String
    var monospace: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(monospace ? .system(.body, design: .monospaced) : .body)
        }
    }
}

#Preview {
    List {
        Section("SDK Configuration") {
            ConfigurationSummaryView(configuration: .constant(.default))
        }
    }
}
