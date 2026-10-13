@preconcurrency import IronSource
import SwiftUI

struct HomeView: View {
    @StateObject private var adManager = LevelPlayManager()

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    self.content
                }
            } else {
                NavigationView {
                    self.content
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.adManager.initializationState {
        case .initializing:
            ProgressView("Initializing LevelPlay…")

        case .failed(let message):
            VStack(spacing: 12) {
                Text("LevelPlay initialization failed")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

        case .initialized:
            List {
                Section {
                    Text("Select an ad format to test. Check Xcode console logs for detailed event tracking.")
                        .font(.subheadline)
                }

                Section {
                    ForEach(AdFormat.allCases) { format in
                        NavigationLink(destination: AdFormatDetailView(format: format, adManager: self.adManager)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.title)
                                    .font(.headline)
                                Text(format.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("LevelPlay + RC")
        }
    }
}

private enum AdFormat: String, CaseIterable, Identifiable {
    case banner
    case interstitial
    case rewarded
    case errorTesting

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .banner: return "Banner Ad"
        case .interstitial: return "Interstitial Ad"
        case .rewarded: return "Rewarded Ad"
        case .errorTesting: return "Error Testing"
        }
    }

    var subtitle: String {
        switch self {
        case .banner: return "Always visible, auto-loaded"
        case .interstitial: return "Full-screen ad"
        case .rewarded: return "Rewards users after viewing"
        case .errorTesting: return "Triggers ad load failure"
        }
    }
}

private struct AdFormatDetailView: View {
    let format: AdFormat
    @ObservedObject var adManager: LevelPlayManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(self.detailDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                switch self.format {
                case .banner:
                    Text("Status: \(self.adManager.bannerStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    BannerAdView(adManager: self.adManager)
                        .frame(height: 50)

                case .interstitial:
                    self.statusAndButtons(
                        status: self.adManager.interstitialStatus,
                        onLoad: { self.adManager.loadInterstitialAd() },
                        onShow: {
                            if let rootViewController = Self.rootViewController {
                                self.adManager.showInterstitialAd(from: rootViewController)
                            }
                        },
                        canShow: self.adManager.interstitialStatus == "Loaded - ready to show"
                    )

                case .rewarded:
                    self.statusAndButtons(
                        status: self.adManager.rewardedStatus,
                        onLoad: { self.adManager.loadRewardedAd() },
                        onShow: {
                            if let rootViewController = Self.rootViewController {
                                self.adManager.showRewardedAd(from: rootViewController)
                            }
                        },
                        canShow: self.adManager.rewardedStatus == "Loaded - ready to show"
                    )
                    .onAppear {
                        self.adManager.trackRewardedPromptShown()
                    }

                case .errorTesting:
                    Text("Status: \(self.adManager.errorTestStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Trigger Ad Load Error") {
                        self.adManager.loadAdWithError()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(self.format.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailDescription: String {
        switch self.format {
        case .banner:
            return "Auto-loaded banner. Tracks Loaded, Displayed, Opened, and Revenue."
        case .interstitial:
            return "Full-screen ad. Tracks Loaded, Displayed, Opened, and Revenue."
        case .rewarded:
            return "Reward ad. Tracks Prompt Shown, Prompt Accepted, Loaded, Displayed, Opened, and Revenue."
        case .errorTesting:
            return "Uses an intentionally invalid LevelPlay ad unit ID to trigger and track a load failure."
        }
    }

    @ViewBuilder
    private func statusAndButtons(
        status: String,
        onLoad: @escaping () -> Void,
        onShow: @escaping () -> Void,
        canShow: Bool
    ) -> some View {
        Text("Status: \(status)")
            .font(.caption)
            .foregroundColor(.secondary)

        HStack {
            Button("Load") { onLoad() }
                .buttonStyle(.bordered)
                .disabled(status == "Loading…")

            Button("Show") { onShow() }
                .buttonStyle(.borderedProminent)
                .disabled(!canShow)
        }
    }

    private static var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }

        return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windowScene.windows.first?.rootViewController
    }
}

private struct BannerAdView: UIViewRepresentable {
    let adManager: LevelPlayManager

    func makeUIView(context: Context) -> UIView {
        guard let viewController = Self.rootViewController else {
            return UIView()
        }

        return self.adManager.makeBannerAd(from: viewController)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Void) {
        (uiView as? LPMBannerAdView)?.destroy()
    }

    private static var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }

        return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windowScene.windows.first?.rootViewController
    }
}
