//
//  ApplicationData.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

import OSLog

@MainActor
final class ApplicationData: ObservableObject {

    @Published
    private(set) var authenticationStatus: AuthenticationStatus = .unknown {
        didSet {
            Self.logger.info("Changed authentication: \(String(describing: self.authenticationStatus))")
        }
    }

    func loadApplicationData() async throws {
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

    var isSignedIn: Bool {
        if case .signedIn = self.authenticationStatus {
            return true
        }
        return false
    }

    private var manager: ApplicationManagerType = ApplicationManager()
    private static let logger = Logging.shared.logger(category: "ApplicationData")

}

extension ApplicationData {
  
    enum AuthenticationStatus: Equatable {

        case signedIn(DeveloperResponse)
        case signedOut
        case unknown

    }

}
