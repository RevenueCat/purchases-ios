//
//  ConfigurationSummaryView.swift
//  RCTTester
//

import SwiftUI

struct ConfigurationSummaryView: View {

    let configuration: SDKConfiguration

    var body: some View {
        Group {
            ConfigurationRow(label: "StoreKit Version", value: configuration.storeKitVersion.displayName)
            ConfigurationRow(label: "Purchases Completed By", value: configuration.purchasesAreCompletedBy.displayName)

            if configuration.purchasesAreCompletedBy == .myApp {
                ConfigurationRow(label: "Purchase Logic", value: configuration.purchaseLogic.displayName)
            }
        }
    }
}

// MARK: - Configuration Row

private struct ConfigurationRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    List {
        Section("SDK Configuration") {
            ConfigurationSummaryView(configuration: .default)
        }
    }
}
