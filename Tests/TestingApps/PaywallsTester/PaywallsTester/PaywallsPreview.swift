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

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .sheet(item: $paywallPreviewData) { paywallID in
                    LoginWall { response in
                        PaywallForID(apps: response.apps, id: paywallID.id, introEligible: paywallID.introOfferEligible)
                    }
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
                .environmentObject(application)
        }
    }

}

// MARK: - Universal Links
extension PaywallsPreview {

    func processURL(_ url: URL) {
        // set to nil to trigger re-render if presenting same paywall with new data
        paywallPreviewData = nil
        paywallPreviewData = getPaywallDataFrom(incomingURL: url)
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
    
}
