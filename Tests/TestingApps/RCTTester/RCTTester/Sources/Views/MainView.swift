//
//  MainView.swift
//  RCTTester
//

import SwiftUI

struct MainView: View {

    let configuration: SDKConfiguration
    let onReconfigure: () -> Void

    var body: some View {
        VStack {
            Text("RCTTester")
                .font(.largeTitle)
                .padding()

            Text("Purchase Attribution Tester")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            ConfigurationSummaryView(configuration: configuration)

            Spacer()
        }
        .navigationTitle("RCTTester")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reconfigure") {
                    onReconfigure()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        MainView(configuration: .default, onReconfigure: {})
    }
}
