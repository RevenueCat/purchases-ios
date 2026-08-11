//
//  TokenManager.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

class TokenManager {

    fileprivate enum Key {
        case refresh(String)
        case access(String)
        case id(String)

        var identifier: String {
            switch self {
            case .refresh(let user): return "RC-refresh-\(user)"
            case .access(let user): return "RC-access-\(user)"
            case .id(let user): return "RC-id-\(user)"
            }
        }
    }

    private struct CurrentTokenRefreshState {
        let request: HTTPRequest
        var completions: Array<(Bool) -> Void>
    }

    let enabled: Bool
    private let storage: any SecureItemStorage

    weak var currentUserProvider: CurrentUserProvider?

    private var currentUser: String? { currentUserProvider?.currentAppUserID }

    private let currentRefreshState: Atomic<CurrentTokenRefreshState?> = Atomic(nil)

    init(enabled: Bool, storage: any SecureItemStorage) {
        self.enabled = enabled
        self.storage = storage
    }

    var reportError: ((PublicError) -> Void)?

    var hasCurrentAccessToken: Bool { currentAccessToken != nil }

    var currentRefreshToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .refresh(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .refresh(user))
        }
    }

    var currentAccessToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .access(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .access(user))
        }
    }

    var currentIDToken: String? {
        get {
            guard enabled == true else { return nil }
            guard let user = currentUser else { return nil }
            return storage.string(for: .id(user))
        }
        set {
            guard enabled == true else { return }
            guard let user = currentUser else { return }
            storage.setString(newValue, for: .id(user))
        }
    }

    var currentIdentitySources: Array<IdentitySource>? {
        guard let currentIDToken else { return nil }
        guard let jwt = try? JWT(from: currentIDToken) else { return nil }
        return jwt.amr?.compactMap { IdentitySource.source(with: $0) }
    }

    var currentIdentitySource: IdentitySource? {
        currentIdentitySources?.last
    }

    func idToken(for user: String) -> String? {
        storage.string(for: .id(user))
    }

    func saveTokens(refreshToken: String?, accessToken: String, idToken: String?, for userID: String) {
        storage.setString(refreshToken, for: .refresh(userID))
        storage.setString(accessToken, for: .access(userID))
        storage.setString(idToken, for: .id(userID))
    }

    func deleteTokens(for userID: String) {
        storage.setString(nil, for: .refresh(userID))
        storage.setString(nil, for: .access(userID))
        storage.setString(nil, for: .id(userID))
    }

    func deleteAccessToken(for userID: String) {
        storage.setString(nil, for: .access(userID))
    }

    func authorizationHeaders(for urlRequest: HTTPClient.Request) -> [String: String] {
        guard enabled else { return [:] }
        guard let currentAccessToken else { return [:] }

        // /auth/* paths want the API key
        if urlRequest.httpRequest.path.isIAMPath { return [:] }

        return [
            HTTPClient.RequestHeader.authorization.rawValue: "Bearer \(currentAccessToken)"
        ]
    }

    // MARK: - Refreshing Tokens

    enum TokenRefreshAction {
        case noAction
        case refresh(HTTPRequest)
        case waitingForOtherRequest
    }

    func tokenRefreshRequest(for initialRequest: HTTPClient.Request,
                             response: HTTPURLResponse?,
                             duplicateRequestHandler: @escaping (Bool) -> Void)
    -> TokenRefreshAction {

        guard self.enabled else { return .noAction }

        // IAM requests do not trigger a token refresh
        if initialRequest.httpRequest.path.isIAMPath { return .noAction }

        // only "401 Unauthorized" responses will trigger a refresh
        guard let response else { return .noAction }
        guard response.httpStatusCode == .unauthorized else { return .noAction }

        // we can only refresh if we have a refresh token
        guard let currentRefreshToken else { return .noAction }

        return self.currentRefreshState.modify {
            if $0 != nil {
                $0?.completions.append(duplicateRequestHandler)
                return .waitingForOtherRequest
            } else {
                let body = TokenRefreshOperation.Body(refreshToken: currentRefreshToken)
                let request = HTTPRequest(method: .post(body), path: .tokenRefresh, isRetryable: false)
                $0 = .init(request: request, completions: [])
                return .refresh(request)
            }
        }
    }

    func handleTokenRefreshResponse(_ result: VerifiedHTTPResponse<TokenResponse>.Result) -> Bool {
        guard self.enabled else { return false }

        // make sure this response is a successful one
        let didHandle: Bool
        let reportedError: PublicError?
        switch result {
        case .success(let response):
            if response.httpStatusCode == .success {
                let tokens = response.body

                self.currentRefreshToken = tokens.refreshToken
                self.currentAccessToken = tokens.accessToken
                self.currentIDToken = tokens.idToken

                reportedError = nil
                didHandle = true
            } else {
                // a non-successful response that somehow didn't get turned into an actual error
                reportedError = ErrorUtils.unknownError().asPublicError
                didHandle = false
            }
        case .failure(let error):
            reportedError = error.asPublicError
            didHandle = false
        }

        let handlers = self.currentRefreshState.modify { state in
            let handlers = state?.completions ?? []
            state = nil
            return handlers
        }

        defer {
            if let reportedError, let reportError {
                reportError(reportedError)
            }
        }

        handlers.forEach { $0(didHandle) }
        return didHandle
    }

}

extension SecureItemStorage {

    fileprivate func string(for key: TokenManager.Key) -> String? {
        guard let data = try? self.readItem(identifier: key.identifier) else {
            return nil
        }
        return String(bytes: data, encoding: .utf8)
    }

    fileprivate func setString(_ string: String?, for key: TokenManager.Key) {
        let data = string.map { Data($0.utf8) }
        try? self.modifyItem(identifier: key.identifier, contents: data)
    }

}
