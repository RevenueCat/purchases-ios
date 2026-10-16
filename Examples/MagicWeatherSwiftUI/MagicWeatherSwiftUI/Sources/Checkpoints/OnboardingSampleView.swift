//
//  OnboardingSampleView.swift
//  Magic Weather SwiftUI
//

import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 An onboarding flow that fires a checkpoint at its last step.
 Onboarding completes when it fires the checkpoint. It does not wait for the result.
 */

struct OnboardingSampleView: View {

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
                return "This flow fires a checkpoint before its last step."
            case .personalize:
                return "Imagine that the customer selects their preferences here."
            case .done:
                return "Onboarding is complete for each checkpoint result."
            }
        }
    }

    @State private var step: Step = .welcome
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
                }

                Spacer()

                switch self.step {
                case .welcome:
                    Button("Continue") {
                        self.step = .personalize
                    }
                    .buttonStyle(.borderedProminent)
                case .personalize:
                    Button("Finish onboarding", action: self.finishOnboarding)
                        .buttonStyle(.borderedProminent)
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

    private func finishOnboarding() {
        Purchases.shared.checkpoint(
            "onboarding_complete",
            customVariables: ["step": .string("personalize")]
        ) { result in
            self.checkpointResult = result.flow == nil
                ? "No completed flow."
                : "The checkpoint flow completed."
        }
        self.step = .done
    }

}
