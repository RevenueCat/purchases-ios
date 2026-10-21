import Foundation
import GoogleMobileAds
import RevenueCat
import RevenueCatAdMob
import SwiftUI

@MainActor
struct RewardedDetailView: View {

    private static let adUnitID = ProcessInfo.processInfo.environment["ADMOB_REWARDED_AD_UNIT_ID"]
        ?? "ca-app-pub-3940256099942544/1712485313"

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        return formatter
    }()

    @State private var usesRewardVerification = true
    @State private var message: Message?
    @State private var promptSession = RewardedAdPromptSession()
    @State private var loadRequestID: UUID?
    @State private var loadedAd: GoogleMobileAds.RewardedAd?
    @State private var isLoading = false
    @State private var hasRewardOutcome = false

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

                        if let rewardedAd = self.loadedAd, let requestID = self.loadRequestID {
                            self.rewardedAdPrompt(ad: rewardedAd, requestID: requestID)
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
    private func rewardedAdPrompt(ad rewardedAd: GoogleMobileAds.RewardedAd, requestID: UUID) -> some View {
        if self.usesRewardVerification {
            RewardedAdPrompt(
                session: self.promptSession,
                ad: rewardedAd,
                placement: "rewarded_main",
                onVerificationCompleted: { result in
                    self.showRewardMessage(Message.forVerificationResult(result), for: requestID)
                },
                onDismiss: {
                    self.finishLoading(
                        for: requestID, with: self.hasRewardOutcome ? nil : Message.Rewarded.dismissed
                    )
                },
                onPresentationFailed: { error in
                    self.finishLoading(for: requestID, with: Message.Rewarded.notPresented(error))
                },
                content: { prompt in
                    self.promptButton(title: self.offerTitle(prompt.rewardConfiguration), accept: prompt.accept)
                }
            )
        } else {
            RewardedAdPromptWithoutVerification(
                session: self.promptSession,
                ad: rewardedAd,
                placement: "rewarded_main",
                onRewardEarned: {
                    // Grant the app-defined reward here, even if another ad has since loaded.
                    self.showRewardMessage(Message.Rewarded.rewardEarned, for: requestID)
                },
                onDismiss: {
                    self.finishLoading(
                        for: requestID, with: self.hasRewardOutcome ? nil : Message.Rewarded.dismissed
                    )
                },
                onPresentationFailed: { error in
                    self.finishLoading(for: requestID, with: Message.Rewarded.notPresented(error))
                },
                content: { prompt in
                    self.promptButton(title: "Watch an ad to earn a reward", accept: prompt.accept)
                }
            )
        }
    }

    private func promptButton(title: String, accept: @escaping @MainActor () -> Void) -> some View {
        Button {
            self.message = Message.Rewarded.waitingForReward
            accept()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
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
                self.message = self.usesRewardVerification
                    ? Message.Rewarded.readyWithVerification
                    : Message.Rewarded.readyWithoutVerification
            } catch {
                guard self.loadRequestID == loadRequestID else { return }
                self.finishLoading(for: loadRequestID, with: Message.Rewarded.loadFailed(error))
            }
        }
    }

    private func finishLoading(for requestID: UUID, with message: Message?) {
        guard self.loadRequestID == requestID else { return }
        if let message { self.message = message }
        self.isLoading = false
        self.loadedAd = nil
        // Keep the request identity so a reward arriving after dismissal can update this offer's message.
    }

    private func showRewardMessage(_ message: Message, for requestID: UUID) {
        guard self.loadRequestID == requestID else { return }
        self.hasRewardOutcome = true
        self.message = message
    }

    private func resetPrompt() {
        self.loadRequestID = nil
        self.loadedAd = nil
        self.isLoading = false
        self.hasRewardOutcome = false
        self.message = nil
    }

    private func offerTitle(_ configuredRewards: ConfiguredAdRewards?) -> String {
        guard let configuredRewards else {
            return "Watch an ad to earn a reward"
        }
        let rewards = [configuredRewards.reward].compactMap { $0 } + configuredRewards.moreRewards
        guard !rewards.isEmpty else { return "Watch an ad to earn a reward" }
        return "Watch an ad to earn " + rewards.map(self.rewardDescription).joined(separator: " + ")
    }

    private func rewardDescription(_ reward: AdRewardConfiguration) -> String {
        if let virtualCurrency = reward.virtualCurrency {
            return "\(virtualCurrency.amount) \(virtualCurrency.code)"
        } else if let entitlement = reward.entitlement {
            let duration = Self.durationFormatter.string(from: entitlement.duration)
                ?? "\(Int(entitlement.duration)) seconds"
            return "\(duration) of \(entitlement.identifier)"
        } else {
            return "the configured reward"
        }
    }

}
