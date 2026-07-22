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
