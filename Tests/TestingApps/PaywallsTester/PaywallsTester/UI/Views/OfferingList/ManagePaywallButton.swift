//
//  ManagePaywallButton.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-30.
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct ManagePaywallButton: View {

    @State
    var error: Error?

    enum Kind: String {
        case edit
        case new

        var image: some View {
            Group {
                switch self {
                case .edit:
                    Image(systemName: "slider.horizontal.2.square.on.square")
                case .new:
                    Image(systemName: "escape")
                        .rotationEffect(Angle(degrees: 90))
                }
            }
        }

        var defaultName: String {
            switch self {
            case .edit:
                "Edit Paywall"
            case .new:
                "New Paywall"
            }
        }
    }

    var body: some View {
        Button {
            guard let url = dashboardPaywallURL else { return }
            openURL(url)
        } label: {
            HStack {
                Text(buttonName ?? kind.defaultName)
                    .font(.headline)
                Spacer()
                kind.image
            }
        }
        .displayError($error)
    }

    init(kind: Kind, appID: String, offeringID: String, buttonName: String? = nil) {
        self.kind = kind
        self.appID = appID
        self.offeringID = offeringID
        self.buttonName = buttonName
    }

    private let kind: Kind
    private let appID: String
    private let offeringID: String
    private let buttonName: String?

    private var dashboardPaywallURL: URL? {
        let urlString = "https://app.revenuecat.com/projects/\(appID)/paywalls/\(offeringID)/\(kind.rawValue)"

        guard let url = URL(string: urlString) else {
            Self.logger.log(level: .error, "Could not create URL for \(urlString)")
            self.error = URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Could not create URL",
                                               NSLocalizedFailureReasonErrorKey: "Attempted with \(urlString)"])
            return nil
        }

        return url
    }

    private func openURL(_ url: URL) {
        #if os(watchOS)
        WKExtension.shared().openSystemURL(url)
        #elseif os(macOS)
        if !NSWorkspace.shared.open(url) {
            Self.logger.log(level: .error, "Could not open URL for \(url)")
            self.error = URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Could not open URL",
                                               NSLocalizedFailureReasonErrorKey: "Could not open \(url)"])
        }
        #else
        guard UIApplication.shared.canOpenURL(url) else {
            Self.logger.log(level: .error, "Could not open URL for \(url)")
            self.error = URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Could not open URL",
                                               NSLocalizedFailureReasonErrorKey: "Could not open \(url)"])
            return
        }
        UIApplication.shared.open(url)
        #endif
    }

    private static var logger = Logging.shared.logger(category: "Paywalls Tester")
}


#Preview {
    List {
        ManagePaywallButton(kind: .new, appID: "abc", offeringID: "efg")
        ManagePaywallButton(kind: .edit, appID: "abc", offeringID: "efg")
    }
}
