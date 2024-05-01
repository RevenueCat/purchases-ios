//
//  ManagePaywallButton.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-30.
//

import SwiftUI

struct ManagePaywallButton: View {

    enum Kind: String {
        case edit
        case new

        var systemImageName: String {
            switch self {
            case .edit:
                return "slider.horizontal.2.square.on.square"
            case .new:
                return "plus.square.on.square"
            }
        }
    }

    let kind: Kind
    let appID: String
    let offeringID: String
    let buttonName: String?

    var body: some View {
        Button {
            let urlString = urlString(appID: appID, offeringID: offeringID)
            guard let url = URL(string: urlString) else {
                Self.logger.log(level: .error, "Could not create URL for \(urlString)")
                return
            }
            openURL(url)
        } label: {
            switch kind {
            case .edit:
                HStack {
                    Text(buttonName ?? "Edit Paywall")
                        .font(.headline)
                    Spacer()
                    Image(systemName: kind.systemImageName)
                }
            case .new:
                HStack {
                    Text(buttonName ?? "New Paywall")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "escape")
                        .rotationEffect(Angle(degrees: 90))
                }
            }

        }
    }

    init(kind: Kind, appID: String, offeringID: String, buttonName: String? = nil) {
        self.kind = kind
        self.appID = appID
        self.offeringID = offeringID
        self.buttonName = buttonName
    }

    private func urlString(appID: String, offeringID: String) -> String {
        "https://app.revenuecat.com/projects/\(appID)/paywalls/\(offeringID)/\(kind.rawValue)"
    }

    private func openURL(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            Self.logger.log(level: .error, "Could not open URL for \(url)")
            return
        }
        UIApplication.shared.open(url)
    }

    private static var logger = Logging.shared.logger(category: "Paywalls Tester")
}


#Preview {
    List {
        ManagePaywallButton(kind: .new, appID: "abc", offeringID: "efg")
        ManagePaywallButton(kind: .edit, appID: "abc", offeringID: "efg")
    }
}
