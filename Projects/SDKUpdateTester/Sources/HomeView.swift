//
//  HomeView.swift
//  SDKUpdateTester
//
//  Created by Antonio Pallares on 2/10/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import RevenueCat
import SwiftUI

struct HomeView: View {

    @State private var appUserID: String = Purchases.shared.appUserID
    @State private var isLoggingIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Differs between the release and the local builds, so keep it out of the screenshots' crop areas.
                Text("RevenueCat SDK \(Purchases.frameworkVersion)")
                    .font(.footnote)
                    .accessibilityIdentifier("sdk_version")

                VStack(spacing: 8) {
                    Text("App User ID")
                        .font(.headline)
                    Text(appUserID)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .accessibilityIdentifier("app_user_id")
                }

                Button("Log in") {
                    logIn()
                }
                .buttonStyle(.borderedProminent)
                .disabled(Constants.appUserIDToLogIn == nil || isLoggingIn)
                .accessibilityIdentifier("log_in_button")

                NavigationLink("Go to purchase screen") {
                    PurchaseView()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("purchase_screen_button")

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("error_message")
                }
            }
            .padding()
            // Top-aligned so messages appearing below don't shift the screenshotted labels.
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("SDK Update Tester")
        }
    }

    private func logIn() {
        guard let appUserIDToLogIn = Constants.appUserIDToLogIn else { return }

        isLoggingIn = true
        errorMessage = nil
        Task {
            do {
                _ = try await Purchases.shared.logIn(appUserIDToLogIn)
            } catch {
                errorMessage = "Log in failed: \(error.localizedDescription)"
            }
            appUserID = Purchases.shared.appUserID
            isLoggingIn = false
        }
    }

}
