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
        var completions: [(Bool) -> Void]
    }

    let enabled: Bool
    private let storage: any SecureItemStorage
    private let dpop: (any DPoPStrategy)?

    weak var currentUserProvider: CurrentUserProvider?

    private var currentUser: String? { currentUserProvider?.currentAppUserID }

    private let currentRefreshState: Atomic<CurrentTokenRefreshState?> = Atomic(nil)

    init(enabled: Bool, storage: any SecureItemStorage) {
        self.enabled = enabled
        self.storage = storage
        // DPoP binds IAM tokens to this install's key, so it's only needed when IAM is enabled
        self.dpop = enabled ? Self.makeDPoPStrategy(storage: storage) : nil
    }

    private static func makeDPoPStrategy(storage: any SecureItemStorage) -> any DPoPStrategy {
        let keychainStrategy = KeychainDPoPStrategy(storage: storage)
        guard SecureEnclaveDPoPStrategy.isAvailable else { return keychainStrategy }

        return SecureEnclaveDPoPStrategy(storage: storage, fallback: keychainStrategy)
    }

    var reportTokenUpdate: ((Result<String?, PublicError>) -> Void)?

    var hasCurrentAccessToken: Bool { currentAccessToken != nil }

    var currentIdentitySources: [IdentitySource]? {
        guard let currentIDToken else { return nil }
        guard let jwt = try? JWT(from: currentIDToken) else { return nil }
        return jwt.amr?.compactMap { IdentitySource.source(with: $0) }
    }

    var isCurrentIdentityAnonymous: Bool {
        // returns true iff all (1+) the identity sources are "anonymous"
        guard let sources = currentIdentitySources else { return false }
        if sources.isEmpty { return false }
        return sources.allSatisfy { $0 == .anonymous }
    }

    var currentIdentitySource: IdentitySource? {
        currentIdentitySources?.last
    }

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

    func idToken(for user: String) -> String? {
        storage.string(for: .id(user))
    }

    func saveTokens(refreshToken: String?, accessToken: String, idToken: String?, for userID: String) {
        storage.setString(refreshToken, for: .refresh(userID))
        storage.setString(accessToken, for: .access(userID))
        storage.setString(idToken, for: .id(userID))
        reportTokenUpdate?(.success(accessToken))
    }

    func deleteTokens(for userID: String) {
        storage.setString(nil, for: .refresh(userID))
        storage.setString(nil, for: .access(userID))
        storage.setString(nil, for: .id(userID))
        reportTokenUpdate?(.success(nil))
    }

    func deleteAccessToken(for userID: String) {
        storage.setString(nil, for: .access(userID))
    }

    /// - Parameters:
    ///   - request: The request being sent.
    ///   - url: The exact URL the request is sent to. DPoP proofs are bound to it.
    func authorizationHeaders(for request: HTTPClient.Request, url: URL) -> [String: String] {
        guard enabled else { return [:] }

        // /auth/* paths want the API key, but carry a DPoP proof so the tokens they issue are bound to our key
        if request.httpRequest.path.isIAMPath {
            return self.dpopHeaders(for: request, url: url, accessToken: nil)
        }

        guard let currentAccessToken else { return [:] }

        // only a bound token needs a proof, and it must use the `DPoP` scheme rather than `Bearer`
        let isBound = (try? JWT(from: currentAccessToken))?.dpopKeyThumbprint != nil
        guard isBound else {
            return [
                HTTPClient.RequestHeader.authorization.rawValue: "Bearer \(currentAccessToken)"
            ]
        }

        var headers = self.dpopHeaders(for: request, url: url, accessToken: currentAccessToken)
        headers[HTTPClient.RequestHeader.authorization.rawValue] = "DPoP \(currentAccessToken)"
        return headers
    }

    private func dpopHeaders(for request: HTTPClient.Request, url: URL, accessToken: String?) -> [String: String] {
        guard let dpop else { return [:] }

        do {
            let proof = try dpop.proof(httpMethod: request.method.httpMethod,
                                       url: url,
                                       accessToken: accessToken,
                                       issuedAt: Date())
            return [HTTPClient.RequestHeader.dpop.rawValue: proof]
        } catch {
            Logger.error(Strings.authentication.dpopProofCreationFailed(error))
            return [:]
        }
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

        // retried requests do not trigger a token refresh
        // this is based on the assumption that the request was retried because it previously failed
        // this check prevents us from getting caught in infinite re-auth loops
        guard initialRequest.retried == false else { return .noAction }

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
        let reportedResult: Result<String?, PublicError>
        switch result {
        case .success(let response):
            if response.httpStatusCode == .success {
                let tokens = response.body

                self.currentRefreshToken = tokens.refreshToken
                self.currentAccessToken = tokens.accessToken
                self.currentIDToken = tokens.idToken

                reportedResult = .success(tokens.accessToken)
                didHandle = true
            } else {
                // a non-successful response that somehow didn't get turned into an actual error
                reportedResult = .failure(ErrorUtils.unknownError().asPublicError)
                didHandle = false
            }
        case .failure(let error):
            reportedResult = .failure(error.asPublicError)
            didHandle = false
        }

        let handlers = self.currentRefreshState.modify { state in
            let handlers = state?.completions ?? []
            state = nil
            return handlers
        }

        defer {
            reportTokenUpdate?(reportedResult)
        }

        handlers.forEach { $0(didHandle) }
        return didHandle
    }

}

extension SecureItemStorage {

    fileprivate func string(for key: TokenManager.Key) -> String? {
        guard let data = try? self.readItem(identifier: key.identifier) else {
            Logger.debug(Strings.authentication.unknownItem(key.identifier))
            return nil
        }
        return String(bytes: data, encoding: .utf8)
    }

    fileprivate func setString(_ string: String?, for key: TokenManager.Key) {
        let data = string.map { Data($0.utf8) }

        // tokens may be bound to a DPoP key that never leaves this device, so they mustn't either
        var attributes = SecureItemAttributes()
        attributes.includedInBackup = false

        do {
            try self.modifyItem(identifier: key.identifier, contents: data, attributes: attributes)
        } catch {
            Logger.warn(Strings.authentication.failedModification(key.identifier, error))
        }
    }

}
