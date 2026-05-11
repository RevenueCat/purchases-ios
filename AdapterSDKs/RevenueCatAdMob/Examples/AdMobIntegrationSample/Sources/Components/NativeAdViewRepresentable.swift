import GoogleMobileAds
import SwiftUI

struct NativeAdViewRepresentable: UIViewRepresentable {

    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFit

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 16)
        headlineLabel.numberOfLines = 0
        headlineLabel.text = self.nativeAd.headline

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.text = self.nativeAd.body

        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(self.nativeAd.callToAction, for: .normal)
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
        nativeAdView.nativeAd = self.nativeAd

        nativeAdView.backgroundColor = .secondarySystemBackground
        nativeAdView.layer.cornerRadius = 12

        return nativeAdView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) {
        uiView.nativeAd = self.nativeAd
        (uiView.headlineView as? UILabel)?.text = self.nativeAd.headline
        (uiView.bodyView as? UILabel)?.text = self.nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(self.nativeAd.callToAction, for: .normal)
    }

}
