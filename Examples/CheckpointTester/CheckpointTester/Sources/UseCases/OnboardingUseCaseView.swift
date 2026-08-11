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
import RevenueCatUI
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

    @ObservedObject var checkpointVariables: CheckpointVariables

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

        do {
            let result = try await Purchases.shared.checkpoint(
                "onboarding_complete",
                params: self.personalizationCheckpointParams
            )
            self.checkpointResult = Self.describe(result)
        } catch {
            self.checkpointResult = "Checkpoint failed: \(error.localizedDescription)"
        }

        self.isRunning = false
        self.step = .done
    }

    private static func describe(_ result: CheckpointResult) -> String {
        switch result {
        case let presented as CheckpointPaywallPresentedResult:
            return Self.describe(presented.paywallOutcome)
        case let noAction as CheckpointNoActionResult:
            return "No paywall shown (\(noAction.reason.value))."
        default:
            return "Unknown checkpoint result."
        }
    }

    private static func describe(_ outcome: CheckpointPaywallOutcome) -> String {
        switch outcome {
        case is CheckpointPaywallPurchasedOutcome:
            return "Purchased during onboarding."
        case is CheckpointPaywallRestoredOutcome:
            return "Restored during onboarding."
        case is CheckpointPaywallDismissedOutcome:
            return "Paywall dismissed."
        case let failed as CheckpointPaywallErrorOutcome:
            return "Paywall failed: \(failed.error.localizedDescription)"
        default:
            return "Unknown paywall outcome."
        }
    }

    private var personalizationCheckpointParams: CheckpointParams {
        var customProperties = self.checkpointVariables.checkpointParams.customProperties
        customProperties["step"] = .string("personalize")
        return CheckpointParams(customProperties: customProperties)
    }

}
