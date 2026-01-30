import SwiftUI
import GoogleMobileAds

struct HomeView: View {
    @StateObject private var adManager = AdMobManager()
    @State private var showErrorFeedback = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Banner Ad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Banner Ad")
                            .font(.headline)
                        BannerAdView(adManager: adManager)
                            .frame(height: 50)
                    }

                    Divider()

                    // Interstitial Ad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. Interstitial Ad")
                            .font(.headline)
                        Text("Status: \(adManager.interstitialStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Button("Load") {
                                adManager.loadInterstitialAd()
                            }
                            .buttonStyle(.bordered)
                            .disabled(adManager.interstitialStatus == "Loading...")

                            Button("Show") {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    adManager.showInterstitialAd(from: rootVC)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(adManager.interstitialStatus != "Ready")
                        }
                    }

                    Divider()

                    // App Open Ad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3. App Open Ad")
                            .font(.headline)
                        Text("Status: \(adManager.appOpenStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Button("Load") {
                                adManager.loadAppOpenAd()
                            }
                            .buttonStyle(.bordered)
                            .disabled(adManager.appOpenStatus == "Loading...")

                            Button("Show") {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    adManager.showAppOpenAd(from: rootVC)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(adManager.appOpenStatus != "Ready")
                        }
                    }

                    Divider()

                    // Native Ad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4. Native Ad")
                            .font(.headline)
                        Text("Status: \(adManager.nativeAdStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Load Native Ad") {
                            adManager.loadNativeAd(adUnitID: Constants.AdMob.nativeAdUnitID, placement: "native_main")
                        }
                        .buttonStyle(.bordered)
                        .disabled(adManager.nativeAdStatus == "Loading...")

                        if let nativeAd = adManager.nativeAd {
                            NativeAdView(nativeAd: nativeAd)
                                .frame(height: 300)
                                .padding(.top, 8)
                        }
                    }

                    Divider()

                    // Native Video Ad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("5. Native Video Ad")
                            .font(.headline)
                        Text("Status: \(adManager.nativeVideoAdStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Load Native Video Ad") {
                            adManager.loadNativeAd(adUnitID: Constants.AdMob.nativeVideoAdUnitID, placement: "native_video_main")
                        }
                        .buttonStyle(.bordered)
                        .disabled(adManager.nativeVideoAdStatus == "Loading...")

                        if let nativeVideoAd = adManager.nativeVideoAd {
                            NativeAdView(nativeAd: nativeVideoAd)
                                .frame(height: 300)
                                .padding(.top, 8)
                        }
                    }

                    Divider()

                    // Error Handling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("6. Error Handling")
                            .font(.headline)
                        Text("Test ad failure tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Load Invalid Ad") {
                            adManager.loadAdWithError()
                            showErrorFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                showErrorFeedback = false
                            }
                        }
                        .buttonStyle(.bordered)

                        if showErrorFeedback {
                            Text("⚠️ Loading with invalid ID - check console logs for failure tracking")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AdMob Integration")
        }
    }
}

// MARK: - Native Ad View

struct NativeAdView: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let nativeAdView = GADNativeAdView()

        // Create UI elements
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Media view for images/videos
        let mediaView = GADMediaView()
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
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)

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

    func updateUIView(_ uiView: GADNativeAdView, context: Context) {}
}

struct BannerAdView: UIViewRepresentable {
    let adManager: AdMobManager

    func makeUIView(context: Context) -> GADBannerView {
        return adManager.loadBannerAd()
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
