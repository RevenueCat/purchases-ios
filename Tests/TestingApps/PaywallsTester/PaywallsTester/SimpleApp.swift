//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import SwiftUI

@main
struct SimpleApp: App {

    struct IdentifiableString: Identifiable {
        let id: String
    }

    @State
    private var application = ApplicationData()

    @State
    private var paywallIDToShow: IdentifiableString?

    func getPaywallIdFrom(incomingURL: URL) -> IdentifiableString? {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        guard let params = components.queryItems else { return nil }

        guard let paywallID = params.first(where: { $0.name == "paywall" } )?.value else {
            return nil
        }

        return IdentifiableString(id: paywallID)
    }

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .sheet(item: $paywallIDToShow) { paywallID in
                    LoginWall { response in
                        PaywallForID(apps: response.apps, id: paywallID.id)
                    }
                }
                .onOpenURL { URL in
                    paywallIDToShow = getPaywallIdFrom(incomingURL: URL)
                }
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { //ofrngb173f388db
                        paywallIDToShow = getPaywallIdFrom(incomingURL: URL(string: "https://app.revenuecat.com/?paywall=ofrng71bdfc2037")!)
                    }
                }
        }
        .environment(application)
    }

}
