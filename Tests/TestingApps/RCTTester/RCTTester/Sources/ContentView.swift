//
//  ContentView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct ContentView: View {

    @State private var isConfigured = false
    @State private var configurationError: String?

    var body: some View {
        NavigationView {
            if isConfigured {
                MainView()
            } else {
                SetupView(error: configurationError)
            }
        }
        .navigationViewStyle(.stack)
        .task {
            await configure()
        }
    }

    private func configure() async {
        guard !Constants.apiKey.isEmpty else {
            configurationError = "REVENUECAT_API_KEY not set.\n\nAdd it to Local.xcconfig:\nREVENUECAT_API_KEY = your-api-key"
            return
        }

        Purchases.logLevel = .verbose
        Purchases.configure(withAPIKey: Constants.apiKey)
        isConfigured = true
    }
}

struct SetupView: View {
    let error: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Configuration Required")
                .font(.title)
                .bold()

            if let error = error {
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("RCTTester")
    }
}

struct MainView: View {
    var body: some View {
        VStack {
            Text("RCTTester")
                .font(.largeTitle)
                .padding()

            Text("Purchase Attribution Tester")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("SDK Configured Successfully")
                .foregroundColor(.green)

            Spacer()
        }
        .navigationTitle("RCTTester")
    }
}

#Preview {
    ContentView()
}
