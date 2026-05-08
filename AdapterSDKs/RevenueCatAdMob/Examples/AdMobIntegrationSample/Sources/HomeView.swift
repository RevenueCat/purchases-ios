// swiftlint:disable file_length type_body_length function_parameter_count
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

private struct AdFormatDetailView: View {
    let format: AdFormat
    @ObservedObject var adManager: AdMobManager
    @State private var showErrorFeedback = false
    @State private var rewardedUsesRewardVerification = false
    @State private var rewardedInterstitialUsesRewardVerification = false

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
                    self.rewardedBlock(
                        status: adManager.rewardedStatus,
                        usesRewardVerification: $rewardedUsesRewardVerification,
                        onLoad: {
                            adManager.loadRewardedAd(withRewardVerification: rewardedUsesRewardVerification)
                        },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showRewardedAd(from: rootVC)
                            }
                        },
                        canShow: adManager.rewardedStatus == "Ready",
                        rewardResult: adManager.rewardedResult,
                        verificationResult: adManager.rewardedVerificationResult
                    )

                case .rewardedInterstitial:
                    self.rewardedBlock(
                        status: adManager.rewardedInterstitialStatus,
                        usesRewardVerification: $rewardedInterstitialUsesRewardVerification,
                        onLoad: {
                            adManager.loadRewardedInterstitialAd(
                                withRewardVerification: rewardedInterstitialUsesRewardVerification
                            )
                        },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                adManager.showRewardedInterstitialAd(from: rootVC)
                            }
                        },
                        canShow: adManager.rewardedInterstitialStatus == "Ready",
                        rewardResult: adManager.rewardedInterstitialResult,
                        verificationResult: adManager.rewardedInterstitialVerificationResult
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(format.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: rewardedUsesRewardVerification) { _ in
            if format == .rewarded {
                adManager.resetRewardedAdSelection()
            }
        }
        .onChange(of: rewardedInterstitialUsesRewardVerification) { _ in
            if format == .rewardedInterstitial {
                adManager.resetRewardedInterstitialAdSelection()
            }
        }
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
            return "Load with or without Reward Verification, then tap Show to present the loaded mode."
        case .rewardedInterstitial:
            return "Load with or without Reward Verification, then tap Show to present the loaded mode."
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

    private func resultCard(message: String) -> some View {
        let tint = self.resultTint(for: message)

        return Group {
            if self.shouldAnimateEllipsis(message: message) {
                TimelineView(.periodic(from: .now, by: 0.45)) { context in
                    Text(self.animatedEllipsisMessage(for: message, at: context.date))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(message)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
            }
        }
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
    }

    private func shouldAnimateEllipsis(message: String) -> Bool {
        message.hasPrefix("⏳") && message.hasSuffix("...")
    }

    private func animatedEllipsisMessage(for message: String, at date: Date) -> String {
        guard self.shouldAnimateEllipsis(message: message) else { return message }

        let base = String(message.dropLast(3))
        let dots = Int(date.timeIntervalSinceReferenceDate * 2).quotientAndRemainder(dividingBy: 3).remainder + 1
        return base + String(repeating: ".", count: dots)
    }

    @ViewBuilder
    private func rewardedBlock(
        status: String,
        usesRewardVerification: Binding<Bool>,
        onLoad: @escaping () -> Void,
        onShow: @escaping () -> Void,
        canShow: Bool,
        rewardResult: String?,
        verificationResult: String?
    ) -> some View {
        Text("Status: \(status)")
            .font(.caption)
            .foregroundColor(.secondary)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Toggle("", isOn: usesRewardVerification)
                    .labelsHidden()
                    .tint(.green)
                    .fixedSize()

                Text("Reward Verification")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text("Applies to the next loaded ad")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator).opacity(0.45), lineWidth: 1)
        )
        .disabled(status == "Loading...")

        Button("Load") { onLoad() }
            .buttonStyle(.bordered)
            .disabled(status == "Loading...")

        Button("Show") { onShow() }
            .buttonStyle(.borderedProminent)
            .disabled(!canShow)

        if let rewardResult {
            self.resultCard(message: rewardResult)
        } else if let verificationResult {
            self.resultCard(message: verificationResult)
        }
    }

    private func resultTint(for message: String) -> Color {
        if message.hasPrefix("✅") || message.hasPrefix("🎁") {
            return .green
        } else if message.hasPrefix("⚠️") {
            return .orange
        } else if message.hasPrefix("❌") {
            return .red
        } else {
            return .blue
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
