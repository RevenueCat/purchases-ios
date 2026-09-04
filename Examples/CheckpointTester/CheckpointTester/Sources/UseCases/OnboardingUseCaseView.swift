//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OnboardingUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct OnboardingUseCaseView: View {

    private enum Step: Int, CaseIterable {
        case welcome
        case personalize
        case done

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .personalize: return "Personalize"
            case .done: return "You're ready"
            }
        }

        var message: String {
            switch self {
            case .welcome:
                return "This flow runs a checkpoint before its final step."
            case .personalize:
                return "Imagine the customer selected their preferences here."
            case .done:
                return "Onboarding completed regardless of the checkpoint result."
            }
        }
    }

    @ObservedObject var customVariables: CustomVariables

    @State private var step: Step = .welcome
    @State private var isRunning = false
    @State private var checkpointResult: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(self.step.rawValue + 1), total: Double(Step.allCases.count))

            Text(self.step.title)
                .font(.title.bold())
            Text(self.step.message)
                .foregroundStyle(.secondary)

            if let checkpointResult {
                GroupBox("Checkpoint result") {
                    Text(checkpointResult)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

            HStack {
                if self.step == .personalize {
                    Button("Back") {
                        self.step = .welcome
                    }
                    .disabled(self.isRunning)
                }

                Spacer()

                switch self.step {
                case .welcome:
                    Button("Continue") {
                        self.step = .personalize
                    }
                    .buttonStyle(.borderedProminent)
                case .personalize:
                    Button(self.isRunning ? "Running checkpoint…" : "Finish onboarding") {
                        Task { @MainActor in
                            await self.finishOnboarding()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.isRunning)
                case .done:
                    Button("Restart onboarding") {
                        self.step = .welcome
                        self.checkpointResult = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("Onboarding")
    }

    @MainActor
    private func finishOnboarding() async {
        guard !self.isRunning else { return }
        self.isRunning = true

        let result = await Purchases.shared.checkpoint(
            "onboarding_complete",
            customVariables: self.personalizationCheckpointCustomVariables
        )
        self.checkpointResult = Self.describe(result)
        self.step = .done
        self.isRunning = false
    }

    private static func describe(_ result: CheckpointGateResult) -> String {
        if let reason = result.noActionReason {
            return "No paywall shown (\(reason))."
        }
        if !result.entitlements.isEmpty {
            return "Access granted: \(result.entitlements.map(\.identifier).joined(separator: ", "))."
        }
        return "Paywall completed without granting a new entitlement."
    }

    private var personalizationCheckpointCustomVariables: [String: CustomVariableValue] {
        var customVariables = self.customVariables.checkpointCustomVariables
        customVariables["step"] = .string("personalize")
        return customVariables
    }

}
