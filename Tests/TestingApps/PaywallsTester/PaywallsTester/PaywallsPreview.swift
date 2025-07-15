//
//  PaywallsPreview.swift
//  PaywallsPreview
//
//  Created by James Borthwick on 4/25/24.
//

import SwiftUI
import RevenueCat

@main
struct PaywallsPreview: App {

    struct IdentifiableString: Identifiable {

        let id: String
        
    }

    struct PaywallPreviewData: Identifiable {
        let paywallIDToShow: String
        let introOfferEligible: IntroEligibilityStatus
        var id: String { paywallIDToShow }
    }

    @StateObject
    private var application = ApplicationData()

    @State
    private var paywallPreviewData: PaywallPreviewData?

    @State
    private var webPurchaseRedemptionResultMessage: String?

    @State
    private var shouldShowWebPurchaseRedemptionResultAlert: Bool = false

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .sheet(item: $paywallPreviewData) { paywallID in
                    LoginWall { response in
                        PaywallForID(apps: response.apps, id: paywallID.id, introEligible: paywallID.introOfferEligible)
                    }
                }
                .onWebPurchaseRedemptionAttempt { result in
                    let message: String?
                    switch result {
                    case .success(_):
                        message = "Redeemed web purchase successfully!"
                    case let .error(error):
                        message = "Web purchase redemption failed: \(error.localizedDescription)"
                    case .invalidToken:
                        message = "Web purchase redemption failed due to invalid token"
                    case .purchaseBelongsToOtherUser:
                        message = "Redemption link has already been redeemed. Cannot be redeemed again."
                    case let .expired(obfuscatedEmail):
                        message = "Redemption link expired. A new one has been sent to \(obfuscatedEmail)"
                    @unknown default:
                        message = "Unrecognized web purchase redemption result"
                    }
                    self.webPurchaseRedemptionResultMessage = message
                    self.shouldShowWebPurchaseRedemptionResultAlert = true
                }
                .onOpenURL { URL in
                    // user taps a link on their phone
                    processURL(URL)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // user scans a QR code
                    guard let url = userActivity.webpageURL else { return }
                    processURL(url)
                }
                .alert(isPresented: self.$shouldShowWebPurchaseRedemptionResultAlert) {
                    return Alert(title: Text("Web purchase redemption attempt"),
                                 message: Text(self.webPurchaseRedemptionResultMessage ?? ""),
                                 dismissButton: .cancel(Text("Ok")) {
                        self.shouldShowWebPurchaseRedemptionResultAlert = false
                    })
                }
                .environmentObject(application)
        }
    }

}

// MARK: - Universal Links
extension PaywallsPreview {

    func processURL(_ url: URL) {
        if isDeepLinkTest(url) {
//            showAlert(title: "Deep Link", message: url.absoluteString)
        } else {
            // set to nil to trigger re-render if presenting same paywall with new data
            paywallPreviewData = nil
            paywallPreviewData = getPaywallDataFrom(incomingURL: url)
        }
    }

    func isDeepLinkTest(_ url: URL) -> Bool {
        return url.host == "deeplinktest"
    }

    func getPaywallDataFrom(incomingURL: URL) -> PaywallPreviewData? {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        guard let params = components.queryItems else { return nil }

        guard let paywallID = params.first(where: { $0.name == "pw" } )?.value else {
            return nil
        }

        let introElgibility: IntroEligibilityStatus

        if let ioStringValue = params.first(where: { $0.name == "io" })?.value,
           let ioIntValue = Int(ioStringValue)  {
            introElgibility = IntroEligibilityStatus(rawValue: ioIntValue) ?? .unknown
        } else {
            introElgibility = .unknown
        }

        return PaywallPreviewData(paywallIDToShow: paywallID, introOfferEligible: introElgibility)
    }

//    func showAlert(title: String, message: String) {
//        DispatchQueue.main.async {
//            guard let topVC = topMostViewController() else { return }
//
//            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//
//            topVC.present(alert, animated: true, completion: nil)
//        }
//    }
//
//    private func topMostViewController(controller: UIViewController? = UIApplication.shared.connectedScenes
//        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
//        .first?.rootViewController) -> UIViewController? {
//
//        if let nav = controller as? UINavigationController {
//            return topMostViewController(controller: nav.visibleViewController)
//        }
//
//        if let tab = controller as? UITabBarController {
//            return topMostViewController(controller: tab.selectedViewController)
//        }
//
//        if let presented = controller?.presentedViewController {
//            return topMostViewController(controller: presented)
//        }
//
//        return controller
//    }

}
