//
//  ApplicationData.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

import OSLog

@Observable
final class ApplicationData {

    private(set) var authenticationStatus: AuthenticationStatus = .unknown {
        didSet {
            Self.logger.info("Changed authentication: \(String(describing: self.authenticationStatus))")
        }
    }

    @MainActor
    func loadApplicationData() async throws {
        self.authenticationStatus = .unknown

        do {
            self.authenticationStatus = .signedIn(try await self.manager.loadApplicationData())
        } catch ApplicationManager.Error.unauthenticated {
            Self.logger.warning("Received unauthentication error when loading application data")
            self.authenticationStatus = .signedOut
        }
    }

    func signOut() {
        self.manager.signOut()
        self.authenticationStatus = .signedOut
    }

    @ObservationIgnored
    private var manager: ApplicationManagerType = ApplicationManager()
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.revenuecat.PaywallsTester",
                                       category: "ApplicationData")

}

extension ApplicationData {
  
    enum AuthenticationStatus: Equatable {

        case signedIn(DeveloperResponse)
        case signedOut
        case unknown

    }

}
