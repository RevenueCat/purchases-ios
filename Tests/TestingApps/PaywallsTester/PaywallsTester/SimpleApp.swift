//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by James Borthwick on 4/25/24.
//

import SwiftUI
import RevenueCat

@main
struct SimpleApp: App {

    struct IdentifiableString: Identifiable {

        let id: String
        
    }

    struct PaywallPreviewData: Identifiable {
        let paywallIDToShow: String
        let introOfferEligible: IntroEligibilityStatus
        var id: String { paywallIDToShow }
    }

    @State
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
        }
        .environment(application)
    }

}

// MARK: - Universal Links
extension SimpleApp {
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

        let showIntroOffer = params.first(where: { $0.name == "io" })?.value.flatMap { value -> IntroEligibilityStatus in
            if value == "1" {
                return .eligible
            } else if value == "0" {
                return .ineligible
            } else if value == "n" {
                return .noIntroOfferExists
            } else {
                return .unknown
            }
        } ?? .unknown

        return PaywallPreviewData(paywallIDToShow: paywallID, introOfferEligible: showIntroOffer)
    }
}
