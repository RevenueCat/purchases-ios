import GoogleMobileAds
import SwiftUI

struct HomeView: View {
    @StateObject private var adManager = AdMobManager()

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
                    NavigationLink(destination: AdFormatDetailView(format: format, adManager: adManager)) {
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
}

private enum AdFormat: String, CaseIterable, Identifiable {
    case banner
    case interstitial
    case appOpen
    case rewarded
    case rewardedSSV
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
        case .rewardedSSV: return "Rewarded Ad (SSV)"
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
        case .rewarded: return "Rewards users after viewing"
        case .rewardedSSV: return "Rewarded with server-side verification"
        case .rewardedInterstitial: return "Interstitial that rewards users"
        case .native: return "Text + images integrated into UI"
        case .nativeVideo: return "Video content integrated into UI"
        case .errorTesting: return "Triggers ad load failure"
        }
    }
}

private struct AdFormatDetailView: View {
    let format: AdFormat
    @ObservedObject var adManager: AdMobManager
    @State private var showErrorFeedback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(self.detailDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                switch format {
                case .banner:
                    BannerAdView(adManager: adManager)
                        .frame(height: 50)

                case .interstitial:
                    self.statusAndButtons(
                        status: adManager.interstitialStatus,
                        onLoad: { adManager.loadInterstitialAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showInterstitialAd(from: rootVC)
                            }
                        },
                        canShow: adManager.interstitialStatus == "Ready"
                    )

                case .appOpen:
                    self.statusAndButtons(
                        status: adManager.appOpenStatus,
                        onLoad: { adManager.loadAppOpenAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showAppOpenAd(from: rootVC)
                            }
                        },
                        canShow: adManager.appOpenStatus == "Ready"
                    )

                case .rewarded:
                    self.statusAndButtons(
                        status: adManager.rewardedStatus,
                        onLoad: { adManager.loadRewardedAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showRewardedAd(from: rootVC) {}
                            }
                        },
                        canShow: adManager.rewardedStatus == "Ready"
                    )

                case .rewardedSSV:
                    self.statusAndButtons(
                        status: adManager.rewardedSSVStatus,
                        onLoad: { adManager.loadRewardedSSVAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showRewardedSSVAd(from: rootVC)
                            }
                        },
                        canShow: adManager.rewardedSSVStatus == "Ready"
                    )
                    if let result = adManager.rewardedSSVResult {
                        Text("SSV result: \(result)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .rewardedInterstitial:
                    self.statusAndButtons(
                        status: adManager.rewardedInterstitialStatus,
                        onLoad: { adManager.loadRewardedInterstitialAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showRewardedInterstitialAd(from: rootVC) {}
                            }
                        },
                        canShow: adManager.rewardedInterstitialStatus == "Ready"
                    )

                case .native:
                    self.nativeBlock(
                        status: adManager.nativeAdStatus,
                        onLoad: {
                            adManager.loadNativeAd(
                                adUnitID: Constants.AdMob.nativeAdUnitID,
                                placement: "native_main"
                            )
                        },
                        nativeAd: adManager.nativeAd
                    )

                case .nativeVideo:
                    self.nativeBlock(
                        status: adManager.nativeVideoAdStatus,
                        onLoad: {
                            adManager.loadNativeAd(
                                adUnitID: Constants.AdMob.nativeVideoAdUnitID,
                                placement: "native_video_main"
                            )
                        },
                        nativeAd: adManager.nativeVideoAd
                    )

                case .errorTesting:
                    Button("Trigger Ad Load Error") {
                        adManager.loadAdWithError()
                        showErrorFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            showErrorFeedback = false
                        }
                    }
                    .buttonStyle(.bordered)

                    if showErrorFeedback {
                        Text("Loading with invalid ID. Check console logs for failure tracking.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(format.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailDescription: String {
        switch format {
        case .banner:
            return "Always visible at the top. Tracks Loaded, Displayed, Opened, and Revenue."
        case .interstitial:
            return "Full-screen ad. Tracks Loaded, Displayed, Opened, and Revenue."
        case .appOpen:
            return "App launch/resume ad. Tracks Loaded, Displayed, Opened, and Revenue."
        case .rewarded:
            return "Reward ad with reward callback. Tracks Loaded, Displayed, Opened, and Revenue."
        case .rewardedSSV:
            return "Real rewarded ad with SSV enabled. After watching, RC polls the backend for verification. Result appears below the buttons."
        case .rewardedInterstitial:
            return "Interstitial format with reward callback and full tracking."
        case .native:
            return "Integrated native ad. Native test IDs can be unreliable; custom IDs are best for validation."
        case .nativeVideo:
            return "Integrated native video ad. Native video test IDs can be unreliable in test environments."
        case .errorTesting:
            return "Uses an intentionally invalid ad unit ID to trigger and track load failures."
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
                .disabled(status == "Loading...")

            Button("Show") { onShow() }
                .buttonStyle(.borderedProminent)
                .disabled(!canShow)
        }
    }

    @ViewBuilder
    private func nativeBlock(
        status: String,
        onLoad: @escaping () -> Void,
        nativeAd: NativeAd?
    ) -> some View {
        Text("Status: \(status)")
            .font(.caption)
            .foregroundColor(.secondary)

        Button("Load") { onLoad() }
            .buttonStyle(.bordered)
            .disabled(status == "Loading...")

        if let nativeAd {
            NativeAdViewRepresentable(nativeAd: nativeAd)
                .frame(height: 300)
                .padding(.top, 8)
        }
    }

    private static var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.rootViewController
    }
}

struct NativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()

        // Create UI elements
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Media view for images/videos
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFit

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 16)
        headlineLabel.numberOfLines = 0
        headlineLabel.text = nativeAd.headline

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.text = nativeAd.body

        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 8
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        ctaButton.configuration = configuration

        stackView.addArrangedSubview(mediaView)
        stackView.addArrangedSubview(headlineLabel)
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(ctaButton)

        // Set media view height constraint
        NSLayoutConstraint.activate([
            mediaView.heightAnchor.constraint(equalToConstant: 200)
        ])

        nativeAdView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12)
        ])

        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = ctaButton
        nativeAdView.nativeAd = nativeAd

        nativeAdView.backgroundColor = .secondarySystemBackground
        nativeAdView.layer.cornerRadius = 12

        return nativeAdView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) {
        uiView.nativeAd = nativeAd
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
    }
}

struct BannerAdView: UIViewRepresentable {
    let adManager: AdMobManager

    func makeUIView(context: Context) -> BannerView {
        return adManager.loadBannerAd()
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
