//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewModel: Hashable {

    let urlString: String
    let size: PaywallComponent.Size
    let visible: Bool
    let componentID: String

    lazy var url: URL? = Self.validatedHTTPSURL(from: self.urlString)

    #if canImport(WebKit)
    /// Canonical origin derived from ``url``. Because ``url`` is already validated as HTTPS with a
    /// host, this should always resolve; a `nil` result is logged and keeps the web view unrendered
    /// (the ``WebViewComponentView`` body gates on it) rather than showing an inert bridge.
    lazy var origin: WebViewOrigin? = {
        guard let url = self.url else {
            return nil
        }
        guard let origin = WebViewOrigin(url: url) else {
            Logger.warning(Strings.paywall_web_view_invalid_expected_origin(self.urlString))
            return nil
        }
        return origin
    }()
    #endif

    init(component: PaywallComponent.WebViewComponent) {
        self.urlString = component.url
        self.size = component.size
        self.visible = component.visible ?? true
        self.componentID = component.id
    }

    private static func validatedHTTPSURL(from urlString: String) -> URL? {
        guard !urlString.contains("{{"),
              let url = URL(string: urlString),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false else {
            return nil
        }
        return url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.urlString)
        hasher.combine(self.componentID)
        hasher.combine(self.size)
        hasher.combine(self.visible)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.urlString == rhs.urlString &&
            lhs.componentID == rhs.componentID &&
            lhs.size == rhs.size &&
            lhs.visible == rhs.visible
    }
}

#endif
