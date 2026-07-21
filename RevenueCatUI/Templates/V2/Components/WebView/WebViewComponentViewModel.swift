import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewComponentViewModel: Hashable {

    let urlString: String
    let size: PaywallComponent.Size
    let visible: Bool
    let componentID: String

    var url: URL? {
        guard !self.urlString.contains("{{"),
              let url = URL(string: self.urlString),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false else {
            return nil
        }
        return url
    }

    init(component: PaywallComponent.WebViewComponent, localizationProvider: LocalizationProvider) {
        self.urlString = component.url
        self.size = component.size
        self.visible = component.visible ?? true
        self.componentID = component.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.urlString)
        hasher.combine(self.componentID)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.urlString == rhs.urlString && lhs.componentID == rhs.componentID
    }
}

#endif
