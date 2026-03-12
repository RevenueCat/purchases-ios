//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMAPI.swift
//
//  Created by RevenueCat.

import Foundation

/// Handles IAM authentication API calls: `/auth/login` and token refresh.
class IAMAPI {

    typealias LoginResponseHandler = (Result<IAMSession, BackendError>) -> Void

    private let backendConfig: BackendConfiguration
    private let sessionManager: IAMSessionManager

    init(backendConfig: BackendConfiguration, sessionManager: IAMSessionManager) {
        self.backendConfig = backendConfig
        self.sessionManager = sessionManager
    }

    /// Whether an active IAM session exists (i.e. the user has authenticated at least once).
    var hasSession: Bool { return sessionManager.hasSession }

    /// Authenticates using the given login method and stores the resulting session.
    ///
    /// On success the session is automatically saved in ``IAMSessionManager``.
    func login(method: IAMLoginMethod, completion: @escaping LoginResponseHandler) {
        let operation = IAMLoginOperation(
            configuration: self.backendConfig,
            loginMethod: method
        ) { [weak self] result in
            if case let .success(session) = result {
                self?.sessionManager.saveSession(session)
            }
            completion(result)
        }

        self.backendConfig.operationQueue.addOperation(operation)
    }

}

// @unchecked because class is not `final` (it could be mocked).
extension IAMAPI: @unchecked Sendable {}
