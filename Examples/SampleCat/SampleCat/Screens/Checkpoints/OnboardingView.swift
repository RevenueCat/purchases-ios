import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 An onboarding flow that fires a checkpoint at its last step.
 Onboarding completes when it fires the checkpoint. It does not wait for the result.
 */
struct OnboardingView: View {
    private enum Step: Int, CaseIterable {
        case welcome
        case personalize
        case done

        var title: String {
            switch self {
            case .welcome: "Welcome"
            case .personalize: "Personalize"
            case .done: "You're ready"
            }
        }

        var message: String {
            switch self {
            case .welcome: "This flow fires a checkpoint before its last step."
            case .personalize: "Imagine that the customer selects their preferences here."
            case .done: "Onboarding is complete for each checkpoint result."
            }
        }
    }

    @State private var step: Step = .welcome
    @State private var checkpointStatus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))

            Text(step.title)
                .font(.title.bold())
            Text(step.message)
                .foregroundStyle(.secondary)

            if let checkpointStatus {
                GroupBox("Checkpoint result") {
                    Text(checkpointStatus)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

            HStack {
                if step == .personalize {
                    Button("Back") { step = .welcome }
                }

                Spacer()

                switch step {
                case .welcome:
                    Button("Continue") { step = .personalize }
                        .buttonStyle(.borderedProminent)
                case .personalize:
                    Button("Finish onboarding", action: finishOnboarding)
                        .buttonStyle(.borderedProminent)
                case .done:
                    Button("Restart onboarding") {
                        step = .welcome
                        checkpointStatus = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("Onboarding")
    }

    private func finishOnboarding() {
        Purchases.shared.checkpoint(CheckpointIdentifiers.onboardingComplete,
                                    customVariables: ["step": .string("personalize")]) { result in
            checkpointStatus = result.flow == nil ? "No flow was presented." : "The checkpoint flow ended."
        }
        step = .done
    }
}
