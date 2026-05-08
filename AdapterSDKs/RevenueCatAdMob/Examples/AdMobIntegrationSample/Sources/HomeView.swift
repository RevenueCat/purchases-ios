import SwiftUI

struct HomeView: View {

    @StateObject private var bannerAdManager = BannerAdManager()
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @StateObject private var appOpenAdManager = AppOpenAdManager()
    @StateObject private var rewardedAdManager = RewardedAdManager()
    @StateObject private var verifiedRewardedAdManager = VerifiedRewardedAdManager()
    @StateObject private var rewardedInterstitialAdManager = RewardedInterstitialAdManager()
    @StateObject private var verifiedRewardedInterstitialAdManager = VerifiedRewardedInterstitialAdManager()
    @StateObject private var nativeAdManager = NativeAdManager()
    @StateObject private var nativeVideoAdManager = NativeVideoAdManager()
    @StateObject private var errorTestingAdManager = ErrorTestingAdManager()

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

    private var content: some View {
        List {
            Section {
                Text("Select an ad format to test. Check Xcode console logs for detailed event tracking.")
                    .font(.subheadline)
            }

            Section {
                ForEach(AdFormat.allCases) { format in
                    NavigationLink(destination: self.destination(for: format)) {
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
        .navigationTitle("AdMob + RevenueCat")
    }

    @ViewBuilder
    private func destination(for format: AdFormat) -> some View {
        switch format {
        case .banner:
            BannerDetailView(manager: self.bannerAdManager)
        case .interstitial:
            InterstitialDetailView(manager: self.interstitialAdManager)
        case .appOpen:
            AppOpenDetailView(manager: self.appOpenAdManager)
        case .rewarded:
            RewardedDetailView(
                rewardedAdManager: self.rewardedAdManager,
                verifiedRewardedAdManager: self.verifiedRewardedAdManager
            )
        case .rewardedInterstitial:
            RewardedInterstitialDetailView(
                rewardedInterstitialAdManager: self.rewardedInterstitialAdManager,
                verifiedRewardedInterstitialAdManager: self.verifiedRewardedInterstitialAdManager
            )
        case .native:
            NativeDetailView(manager: self.nativeAdManager)
        case .nativeVideo:
            NativeVideoDetailView(manager: self.nativeVideoAdManager)
        case .errorTesting:
            ErrorTestingDetailView(manager: self.errorTestingAdManager)
        }
    }

}

private enum AdFormat: String, CaseIterable, Identifiable {

    case banner
    case appOpen
    case interstitial
    case rewarded
    case rewardedInterstitial
    case native
    case nativeVideo
    case errorTesting

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .banner: return "Banner Ad"
        case .interstitial: return "Interstitial Ad"
        case .appOpen: return "App Open Ad"
        case .rewarded: return "Rewarded Ad"
        case .rewardedInterstitial: return "Rewarded Interstitial Ad"
        case .native: return "Native Ad"
        case .nativeVideo: return "Native Video Ad"
        case .errorTesting: return "Error Testing"
        }
    }

    var subtitle: String {
        switch self {
        case .banner: return "Always visible, auto-loaded"
        case .interstitial: return "Full-screen ad"
        case .appOpen: return "App launch/resume ad"
        case .rewarded: return "Rewards users after viewing with optional server-side verification"
        case .rewardedInterstitial: return "Interstitial that rewards users with optional server-side verification"
        case .native: return "Text + images integrated into UI"
        case .nativeVideo: return "Video content integrated into UI"
        case .errorTesting: return "Triggers ad load failure"
        }
    }

}
