import Foundation
import GoogleMobileAds
import RevenueCat
import RevenueCatAdMob
import SwiftUI

@MainActor
struct RewardedDetailView: View {

    private static let adUnitID = ProcessInfo.processInfo.environment["ADMOB_REWARDED_AD_UNIT_ID"]
        ?? "ca-app-pub-3940256099942544/1712485313"

    @State private var usesRewardVerification = true
    @State private var message: Message?
    @State private var promptSession = RewardedAdPromptSession()
    @State private var loadRequestID: UUID?
    @State private var loadedAd: GoogleMobileAds.RewardedAd?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Load the ad, then accept the offer to present it.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Toggle("Reward Verification", isOn: self.$usesRewardVerification)

                if Constants.isRevenueCatAPIKeyConfigured {
                    HStack(spacing: 12) {
                        Button {
                            self.loadAd()
                        } label: {
                            HStack {
                                if self.isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(self.isLoading ? "Loading" : "Load")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(self.isLoading)
                        .fixedSize(horizontal: true, vertical: false)

                        if let rewardedAd = self.loadedAd {
                            self.rewardedAdPrompt(ad: rewardedAd)
                        }
                    }
                } else {
                    ResultCard(message: Message.Rewarded.configurationRequired)
                }

                if let message = self.message {
                    ResultCard(message: message)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Rewarded Ad")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: self.usesRewardVerification) { _ in
            self.resetPrompt()
        }
    }

    @ViewBuilder
    private func rewardedAdPrompt(ad rewardedAd: GoogleMobileAds.RewardedAd) -> some View {
        if self.usesRewardVerification {
            RewardedAdPrompt(
                session: self.promptSession,
                ad: rewardedAd,
                placement: "rewarded_main",
                onResult: { result in
                    self.finishLoading(with: self.message(for: result))
                },
                content: { prompt in
                    self.promptButton(prompt)
                }
            )
        } else {
            RewardedAdPromptWithoutVerification(
                session: self.promptSession,
                ad: rewardedAd,
                placement: "rewarded_main",
                onResult: { result in
                    self.finishLoading(with: self.message(for: result))
                },
                content: { prompt in
                    self.promptButton(prompt)
                }
            )
        }
    }

    private func promptButton(_ prompt: RewardedAdPromptContext) -> some View {
        Button {
            self.message = Message.Rewarded.waitingForReward
            prompt.accept()
        } label: {
            Text(self.offerTitle(prompt.rewardConfiguration))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .onAppear {
            self.isLoading = false
            self.message = self.usesRewardVerification
                ? Message.Rewarded.readyWithVerification
                : Message.Rewarded.readyWithoutVerification
        }
    }

    private func loadAd() {
        self.resetPrompt()
        self.message = nil
        self.isLoading = true
        let loadRequestID = UUID()
        self.loadRequestID = loadRequestID

        Task {
            do {
                let rewardedAd = try await GoogleMobileAds.RewardedAd.loadAndTrack(
                    withAdUnitID: Self.adUnitID,
                    request: Request(),
                    placement: "rewarded_main"
                )
                guard self.loadRequestID == loadRequestID else { return }
                self.loadedAd = rewardedAd
                self.isLoading = false
            } catch {
                guard self.loadRequestID == loadRequestID else { return }
                self.finishLoading(with: Message.Rewarded.loadFailed(error))
            }
        }
    }

    private func finishLoading(with message: Message) {
        self.message = message
        self.isLoading = false
        self.loadRequestID = nil
        self.loadedAd = nil
    }

    private func resetPrompt() {
        self.loadRequestID = nil
        self.loadedAd = nil
        self.isLoading = false
        self.message = nil
    }

    private func message(for result: RewardedAdPromptVerificationResult) -> Message {
        switch result.kind {
        case .verificationCompleted:
            guard let verificationResult = result.rewardVerificationResult else { return .failed }
            return Message.forVerificationResult(verificationResult)
        case .dismissed:
            return Message.Rewarded.dismissedBeforeReward
        case .notPresented:
            guard let error = result.presentationError else { return .failed }
            return Message.Rewarded.notPresented(error)
        default:
            return .failed
        }
    }

    private func message(for result: RewardedAdPromptUnverifiedResult) -> Message {
        switch result.kind {
        case .rewardEarned:
            return Message.Rewarded.rewardEarned
        case .dismissed:
            return Message.Rewarded.dismissedBeforeReward
        case .notPresented:
            guard let error = result.presentationError else { return .failed }
            return Message.Rewarded.notPresented(error)
        default:
            return .failed
        }
    }

    private func offerTitle(_ configuredRewards: ConfiguredAdRewards?) -> String {
        guard let configuredRewards else {
            return "Watch an ad to earn a reward"
        }
        let rewards = [configuredRewards.configuredReward].compactMap { $0 } + configuredRewards.moreRewards
        guard !rewards.isEmpty else { return "Watch an ad to earn a reward" }
        return "Watch an ad to earn " + rewards.map(self.rewardDescription).joined(separator: " + ")
    }

    private func rewardDescription(_ reward: AdRewardConfiguration) -> String {
        if let virtualCurrency = reward.virtualCurrency {
            return "\(virtualCurrency.amount) \(virtualCurrency.code)"
        } else if let entitlement = reward.entitlement {
            let duration = entitlement.duration
            return "\(duration.value) \(self.description(for: duration.unit, value: duration.value)) of "
                + entitlement.identifier
        } else {
            return "the configured reward"
        }
    }

    private func description(for unit: AdRewardDuration.Unit, value: Int) -> String {
        let description: String
        switch unit {
        case .second: description = "second"
        case .minute: description = "minute"
        case .hour: description = "hour"
        case .day: description = "day"
        case .week: description = "week"
        case .month: description = "month"
        case .year: description = "year"
        default: description = "unit"
        }
        return value == 1 ? description : description + "s"
    }

}
