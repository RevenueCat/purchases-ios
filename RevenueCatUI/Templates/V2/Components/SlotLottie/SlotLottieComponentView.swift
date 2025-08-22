//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SlotComponentView.swift
//
//  Created by Josh Holtz on 8/15/25.

import Foundation
import SwiftUI
import WebKit

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotLottieComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    let viewModel: SlotLottieComponentViewModel

    var body: some View {
        self.viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            )
        ) { style in
            switch style.value {
            case .url(let url):
                LottieWebView(
                    source: .url(url),
                    loop: true,
                    autoplay: true,
                    explicitWidth: style.explicitWidth,
                    explicitHeight: style.explicitHeight
                )
                .clipped()
                // Style the carousel
                .padding(style.padding)
                .padding(style.margin)
            case .unknown:
                EmptyView()
            }
        }
    }

}

// MARK: - Platform bridges

#if os(iOS)
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformColor = UIColor
private let platformNoIntrinsicMetric = UIView.noIntrinsicMetric
#elseif os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformColor = NSColor
private let platformNoIntrinsicMetric = NSView.noIntrinsicMetric
#endif

// MARK: - LottieWebView

struct LottieWebView: PlatformViewRepresentable {

    // MARK: API

    static let defaultScript = URL(string: "https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js")!

    enum Source: Equatable { case url(URL) } // file:// or https://

    let source: Source

    /// Lottie *web* SDK to use (remote or local). If file://, it’s inlined into the HTML.
    var lottieScriptURL: URL? = LottieWebView.defaultScript

    var loop: Bool = true
    var autoplay: Bool = true
    var backgroundColor: PlatformColor = .clear

    /// Optional explicit sizing. If only one dimension is provided, the other is computed
    /// from the animation's intrinsic aspect ratio (w/h) once known.
    var explicitWidth: CGFloat? = nil
    var explicitHeight: CGFloat? = nil

    init(
        source: Source,
        lottieScriptURL: URL? = LottieWebView.defaultScript,
        loop: Bool = true,
        autoplay: Bool = true,
        backgroundColor: PlatformColor = .clear,
        explicitWidth: CGFloat? = nil,
        explicitHeight: CGFloat? = nil
    ) {
        self.source = source
        self.lottieScriptURL = lottieScriptURL
        self.loop = loop
        self.autoplay = autoplay
        self.backgroundColor = backgroundColor
        self.explicitWidth = explicitWidth
        self.explicitHeight = explicitHeight
    }

    // MARK: - Representable conformance

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    #if os(iOS)
    func makeUIView(context: Context) -> SizingWKWebView { makeWebView(context: context) }
    func updateUIView(_ uiView: SizingWKWebView, context: Context) { updateWebView(uiView, context: context) }
    #elseif os(macOS)
    func makeNSView(context: Context) -> SizingWKWebView { makeWebView(context: context) }
    func updateNSView(_ nsView: SizingWKWebView, context: Context) { updateWebView(nsView, context: context) }
    #endif

    private func makeWebView(context: Context) -> SizingWKWebView {
        let webView = SizingWKWebView(frame: .zero)

        // Transparent background
        #if os(iOS)
        webView.isOpaque = false
        webView.backgroundColor = backgroundColor
        webView.scrollView.isScrollEnabled = false
        #elseif os(macOS)
        // WKWebView on macOS draws its own background; disable it for transparency
        webView.setValue(false, forKey: "drawsBackground")
        #endif

        context.coordinator.load(
            into: webView,
            source: source,
            loop: loop,
            autoplay: autoplay,
            lottieScriptURL: lottieScriptURL,
            explicitWidth: explicitWidth,
            explicitHeight: explicitHeight
        )
        return webView
    }

    private func updateWebView(_ webView: SizingWKWebView, context: Context) {
        let newKey = Coordinator.Key(
            source: source,
            loop: loop,
            autoplay: autoplay,
            lottieScriptURL: lottieScriptURL,
            explicitWidth: explicitWidth,
            explicitHeight: explicitHeight
        )
        if context.coordinator.lastKey != newKey {
            context.coordinator.load(
                into: webView,
                source: source,
                loop: loop,
                autoplay: autoplay,
                lottieScriptURL: lottieScriptURL,
                explicitWidth: explicitWidth,
                explicitHeight: explicitHeight
            )
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        struct Key: Equatable {
            let source: LottieWebView.Source
            let loop: Bool
            let autoplay: Bool
            let lottieScriptURL: URL?
            let explicitWidth: CGFloat?
            let explicitHeight: CGFloat?
        }

        private let parent: LottieWebView
        fileprivate var lastKey: Key?
        private var lastIntrinsic: CGSize? // from Lottie meta

        init(_ parent: LottieWebView) { self.parent = parent }

        private struct LottieMeta: Decodable { let w: CGFloat; let h: CGFloat }

        func load(
            into webView: SizingWKWebView,
            source: LottieWebView.Source,
            loop: Bool,
            autoplay: Bool,
            lottieScriptURL: URL?,
            explicitWidth: CGFloat?,
            explicitHeight: CGFloat?
        ) {
            lastKey = Key(
                source: source, loop: loop, autoplay: autoplay,
                lottieScriptURL: lottieScriptURL,
                explicitWidth: explicitWidth, explicitHeight: explicitHeight
            )

            func applyPreferredSize(intrinsic: CGSize?) {
                lastIntrinsic = intrinsic
                webView.preferredSize = computePreferredSize(
                    intrinsic: intrinsic,
                    explicitWidth: explicitWidth,
                    explicitHeight: explicitHeight
                )
            }

            func handleData(_ data: Data) {
                // Decode intrinsic size from JSON (best-effort)
                let intrinsic: CGSize? = {
                    if let meta = try? JSONDecoder().decode(LottieMeta.self, from: data),
                       meta.w > 0, meta.h > 0 {
                        return CGSize(width: meta.w, height: meta.h)
                    }
                    return nil
                }()

                // Update native view size before rendering
                applyPreferredSize(intrinsic: intrinsic)

                // Build HTML (embed JSON as base64 to avoid CORS)
                let html = Self.html(
                    for: data, loop: loop, autoplay: autoplay, lottieScriptURL: lottieScriptURL
                )
                webView.loadHTMLString(html, baseURL: nil)
            }

            switch source {
            case .url(let url):
                if url.isFileURL {
                    do { handleData(try Data(contentsOf: url)) }
                    catch {
                        webView.loadHTMLString(Self.errorHTML("Failed to read local Lottie: \(error)"), baseURL: nil)
                    }
                } else {
                    var req = URLRequest(url: url)
                    req.cachePolicy = .returnCacheDataElseLoad
                    URLSession.shared.dataTask(with: req) { data, _, err in
                        DispatchQueue.main.async {
                            if let err = err {
                                webView.loadHTMLString(Self.errorHTML("Network error: \(err.localizedDescription)"), baseURL: nil)
                                return
                            }
                            guard let data = data else {
                                webView.loadHTMLString(Self.errorHTML("No data received."), baseURL: nil)
                                return
                            }
                            handleData(data)
                        }
                    }.resume()
                }
            }
        }

        // Compute final preferred size from explicit and intrinsic inputs.
        private func computePreferredSize(intrinsic: CGSize?, explicitWidth: CGFloat?, explicitHeight: CGFloat?) -> CGSize? {
            // Both provided -> exact
            if let w = explicitWidth, let h = explicitHeight, w > 0, h > 0 {
                return CGSize(width: w, height: h)
            }
            // Only width -> compute height when intrinsic known
            if let w = explicitWidth, w > 0 {
                if let intr = intrinsic, intr.width > 0, intr.height > 0 {
                    let ratio = intr.height / intr.width
                    return CGSize(width: w, height: w * ratio)
                }
                return nil // wait for intrinsic
            }
            // Only height -> compute width when intrinsic known
            if let h = explicitHeight, h > 0 {
                if let intr = intrinsic, intr.width > 0, intr.height > 0 {
                    let ratio = intr.width / intr.height
                    return CGSize(width: h * ratio, height: h)
                }
                return nil // wait for intrinsic
            }
            // Neither provided -> use intrinsic (if known)
            return intrinsic
        }

        // MARK: - HTML builder

        private static func html(for jsonData: Data, loop: Bool, autoplay: Bool, lottieScriptURL: URL?) -> String {
            let b64 = jsonData.base64EncodedString()
            let loopFlag = loop ? "true" : "false"
            let autoplayFlag = autoplay ? "true" : "false"

            // Include lottie-web:
            // - file://  -> inline JS inside <script>…</script>
            // - https://  -> <script src="…"></script>
            // - nil       -> fallback CDN
            let scriptTag: String = {
                if let url = lottieScriptURL {
                    if url.isFileURL, let js = (try? String(contentsOf: url, encoding: .utf8)) {
                        return "<script>\n\(js)\n</script>"
                    } else {
                        return #"<script src="\#(url.absoluteString)"></script>"#
                    }
                } else {
                    return #"<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>"#
                }
            }()

            // The web content fills the native WKWebView bounds; the native view dictates final size.
            return """
            <!doctype html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <style>
                html,body,#lottie { margin:0; height:100%; width:100%; background:transparent; overflow:hidden; }
              </style>
            </head>
            <body>
              <div id="lottie"></div>
              \(scriptTag)
              <script>
                (function() {
                  try {
                    const jsonText = atob("\(b64)");
                    const animationData = JSON.parse(jsonText);
                    lottie.loadAnimation({
                      container: document.getElementById('lottie'),
                      renderer: 'svg',
                      loop: \(loopFlag),
                      autoplay: \(autoplayFlag),
                      animationData
                    });
                  } catch (e) {
                    document.body.innerHTML = "<pre style='font-family: -apple-system; padding:16px'>Failed to load Lottie: " + e + "</pre>";
                  }
                })();
              </script>
            </body>
            </html>
            """
        }

        private static func errorHTML(_ message: String) -> String {
            """
            <!doctype html><html><body>
              <pre style="font-family:-apple-system;padding:16px;color:#c00">\(message)</pre>
            </body></html>
            """
        }
    }
}

// MARK: - Intrinsic sizing WKWebView

final class SizingWKWebView: WKWebView {
    var preferredSize: CGSize? {
        didSet { invalidateIntrinsicContentSize() }
    }

    override var intrinsicContentSize: CGSize {
        if let s = preferredSize, s.width > 0, s.height > 0 {
            return s
        }
        return CGSize(width: platformNoIntrinsicMetric, height: platformNoIntrinsicMetric)
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotLottieComponentView_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Default
        VStack {
            SlotLottieComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    component: .init(
                        identifier: "",
                        value: .url(URL(string: "https://lottie.host/c255f574-25eb-4fa9-848a-5797950d3eff/lxodHspupk.json")!)
                    )
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 100, height: 100))
        .previewDisplayName("Default")

    }
}

#endif

#endif
