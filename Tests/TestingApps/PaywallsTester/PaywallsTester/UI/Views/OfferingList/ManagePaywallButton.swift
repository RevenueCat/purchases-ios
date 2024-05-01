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

    var body: some View {
        Button {
            guard let url = dashboardPaywallURL else { return }
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
        self.buttonName = buttonName
        self.dashboardPaywallURL = {
            let urlString = "https://app.revenuecat.com/projects/\(appID)/paywalls/\(offeringID)/\(kind.rawValue)"
            guard let url = URL(string: urlString) else {
                Self.logger.log(level: .error, "Could not create URL for \(urlString)")
                return nil
            }

            return url
        }()
    }

    private let kind: Kind
    private let buttonName: String?
    private let dashboardPaywallURL: URL?

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
