// swiftlint:disable file_length type_body_length function_parameter_count
import GoogleMobileAds
import SwiftUI

struct HomeView: View {
    @StateObject private var bannerAdManager = BannerAdManager()
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @StateObject private var appOpenAdManager = AppOpenAdManager()
    @StateObject private var rewardedAdManager = RewardedAdManager()
    @StateObject private var rewardedInterstitialAdManager = RewardedInterstitialAdManager()
    @StateObject private var nativeAdManager = NativeAdManager()
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
                    NavigationLink(
                        destination: AdFormatDetailView(
                            format: format,
                            bannerAdManager: bannerAdManager,
                            interstitialAdManager: interstitialAdManager,
                            appOpenAdManager: appOpenAdManager,
                            rewardedAdManager: rewardedAdManager,
                            rewardedInterstitialAdManager: rewardedInterstitialAdManager,
                            nativeAdManager: nativeAdManager,
                            errorTestingAdManager: errorTestingAdManager
                        )
                    ) {
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
    @ObservedObject var bannerAdManager: BannerAdManager
    @ObservedObject var interstitialAdManager: InterstitialAdManager
    @ObservedObject var appOpenAdManager: AppOpenAdManager
    @ObservedObject var rewardedAdManager: RewardedAdManager
    @ObservedObject var rewardedInterstitialAdManager: RewardedInterstitialAdManager
    @ObservedObject var nativeAdManager: NativeAdManager
    @ObservedObject var errorTestingAdManager: ErrorTestingAdManager
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
                    BannerAdView(manager: bannerAdManager)
                        .frame(height: 50)

                case .interstitial:
                    self.statusAndButtons(
                        message: interstitialAdManager.message,
                        onLoad: { interstitialAdManager.loadAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                interstitialAdManager.showAd(from: rootVC)
                            }
                        },
                        canShow: interstitialAdManager.message == "Ready"
                    )

                case .appOpen:
                    self.statusAndButtons(
                        message: appOpenAdManager.message,
                        onLoad: { appOpenAdManager.loadAd() },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                appOpenAdManager.showAd(from: rootVC)
                            }
                        },
                        canShow: appOpenAdManager.message == "Ready"
                    )

                case .rewarded:
                    self.rewardedBlock(
                        message: rewardedAdManager.message,
                        usesRewardVerification: $rewardedUsesRewardVerification,
                        onLoad: {
                            rewardedAdManager.loadAd(withRewardVerification: rewardedUsesRewardVerification)
                        },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                rewardedAdManager.showAd(from: rootVC)
                            }
                        },
                        canShow: rewardedAdManager.message == "Ready",
                        rewardResult: rewardedAdManager.result,
                        verificationResult: rewardedAdManager.verificationResult
                    )

                case .rewardedInterstitial:
                    self.rewardedBlock(
                        message: rewardedInterstitialAdManager.message,
                        usesRewardVerification: $rewardedInterstitialUsesRewardVerification,
                        onLoad: {
                            rewardedInterstitialAdManager.loadAd(
                                withRewardVerification: rewardedInterstitialUsesRewardVerification
                            )
                        },
                        onShow: {
                            if let rootVC = Self.rootViewController {
                                rewardedInterstitialAdManager.showAd(from: rootVC)
                            }
                        },
                        canShow: rewardedInterstitialAdManager.message == "Ready",
                        rewardResult: rewardedInterstitialAdManager.result,
                        verificationResult: rewardedInterstitialAdManager.verificationResult
                    )

                case .native:
                    self.nativeBlock(
                        message: nativeAdManager.nativeAdMessage,
                        onLoad: {
                            nativeAdManager.loadAd(.native)
                        },
                        nativeAd: nativeAdManager.nativeAd
                    )

                case .nativeVideo:
                    self.nativeBlock(
                        message: nativeAdManager.nativeVideoAdMessage,
                        onLoad: {
                            nativeAdManager.loadAd(.nativeVideo)
                        },
                        nativeAd: nativeAdManager.nativeVideoAd
                    )

                case .errorTesting:
                    Button("Trigger Ad Load Error") {
                        errorTestingAdManager.loadAd()
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
                rewardedAdManager.resetSelection()
            }
        }
        .onChange(of: rewardedInterstitialUsesRewardVerification) { _ in
            if format == .rewardedInterstitial {
                rewardedInterstitialAdManager.resetSelection()
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
        message: String,
        onLoad: @escaping () -> Void,
        onShow: @escaping () -> Void,
        canShow: Bool
    ) -> some View {
        Text("Status: \(message)")
            .font(.caption)
            .foregroundColor(.secondary)

        HStack {
            Button("Load") { onLoad() }
                .buttonStyle(.bordered)
                .disabled(message == "Loading...")

            Button("Show") { onShow() }
                .buttonStyle(.borderedProminent)
                .disabled(!canShow)
        }
    }

    @ViewBuilder
    private func nativeBlock(
        message: String,
        onLoad: @escaping () -> Void,
        nativeAd: NativeAd?
    ) -> some View {
        Text("Status: \(message)")
            .font(.caption)
            .foregroundColor(.secondary)

        Button("Load") { onLoad() }
            .buttonStyle(.bordered)
            .disabled(message == "Loading...")

        if let nativeAd {
            NativeAdViewRepresentable(nativeAd: nativeAd)
                .frame(height: 300)
                .padding(.top, 8)
        }
    }

    private func resultCard(message: String) -> some View {
        let tint = self.resultTint(for: message)

        return VStack(alignment: .leading, spacing: 10) {
            if self.shouldAnimateEllipsis(message: message) {
                TimelineView(.periodic(from: .now, by: 0.45)) { context in
                    Text(self.animatedEllipsisMessage(for: message, at: context.date))
                        .font(.body)
                        .foregroundColor(.primary)
                }
            } else if let emphasis = self.emphasizedTwoLineMessage(for: message) {
                Text(emphasis.firstLine)
                    .font(.body)
                    .foregroundColor(.primary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(emphasis.secondLabel):")
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(emphasis.secondValue)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            } else if let twoLine = self.simpleTwoLineMessage(for: message) {
                Text(twoLine.firstLine)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(twoLine.secondLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            } else {
                Text(message)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
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

    private func emphasizedTwoLineMessage(
        for message: String
    ) -> (firstLine: String, secondLabel: String, secondValue: String)? {
        let lines = message.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count == 2 else { return nil }
        guard let separatorIndex = lines[1].firstIndex(of: ":") else { return nil }

        let label = String(lines[1][..<separatorIndex]).trimmingCharacters(in: .whitespaces)
        let value = String(lines[1][lines[1].index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty, !value.isEmpty else { return nil }

        return (lines[0], label, value)
    }

    private func simpleTwoLineMessage(for message: String) -> (firstLine: String, secondLine: String)? {
        let lines = message.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count == 2 else { return nil }
        guard self.emphasizedTwoLineMessage(for: message) == nil else { return nil }

        return (lines[0], lines[1])
    }

    @ViewBuilder
    private func rewardedBlock(
        message: String,
        usesRewardVerification: Binding<Bool>,
        onLoad: @escaping () -> Void,
        onShow: @escaping () -> Void,
        canShow: Bool,
        rewardResult: String?,
        verificationResult: String?
    ) -> some View {
        Text("Status: \(message)")
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
        .disabled(message == "Loading...")

        Button("Load") { onLoad() }
            .buttonStyle(.bordered)
            .disabled(message == "Loading...")

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
    let manager: BannerAdManager

    func makeUIView(context: Context) -> BannerView {
        return manager.loadAd()
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
