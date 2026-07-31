//
//  Authenticator.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/30/26.
//

import Foundation

internal protocol InternalAuthenticatorDelegate: AnyObject {
    func authenticatorDidLogIn(info: CustomerInfo?, error: PublicError?)
    func authenticatorDidChangeIdentity(completion: @escaping (Result<CustomerInfo, PublicError>) -> Void)
}

@_spi(Experimental)
@objc(RCPurchasesAuthenticator)
public final class Authenticator: NSObject {

    private let backend: Backend
    private let identityManager: IdentityManager
    private let operationDispatcher: OperationDispatcher
    private let systemInfo: SystemInfo
    internal weak var internalDelegate: InternalAuthenticatorDelegate?

    internal init(backend: Backend, identityManager: IdentityManager, operationDispatcher: OperationDispatcher, systemInfo: SystemInfo, internalDelegate: InternalAuthenticatorDelegate? = nil) {
        self.backend = backend
        self.identityManager = identityManager
        self.operationDispatcher = operationDispatcher
        self.systemInfo = systemInfo
        self.internalDelegate = internalDelegate
    }

    @available(*, deprecated, message: """
    The appUserID passed to logIn is a constant string known at compile time.
    This is likely a programmer error. This ID is used to identify the current user.
    See https://docs.revenuecat.com/docs/user-ids for more information.
    """)
    public func identifyCurrentUser(as appUserID: StaticString,
                                    completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        Logger.warn(Strings.identity.logging_in_with_static_string)
        self.identifyCurrentUser(as: appUserID.description, completion: completion)
    }

    @_disfavoredOverload
    @objc(identifyCurrentUserAsID:completion:)
    public func identifyCurrentUser(as appUserID: String,
                                    completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        let normalizedAppUserID = appUserID.trimmingWhitespacesAndNewLines

        self.identityManager.logIn(appUserID: normalizedAppUserID) { result in
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.value?.info, result.value?.created ?? false, result.error?.asPublicError)
            }

            guard case .success = result else {
                return
            }

            self.internalDelegate?.authenticatorDidLogIn(info: result.value?.info, error: result.error?.asPublicError)
        }

    }

    @objc(logInUsingToken:completion:)
    public func logIn(using token: ExternalToken, completion: @escaping (CustomerInfo?, PublicError?) -> Void) {
        guard self.backend.token.enabled else {
            let error = NewErrorUtils.unsupportedError(message: "Token login requires .with(iamEnabled: true)")
            completion(nil, error.asPublicError)
            return
        }

        self.identityManager.logIn(externalToken: token) { result in
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.value?.info, result.error?.asPublicError)
            }

            guard case .success = result else {
                return
            }

            self.internalDelegate?.authenticatorDidLogIn(info: result.value?.info,
                                                         error: result.error?.asPublicError)
        }
    }

    @objc
    public func logOut(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
            completion?(nil, NewErrorUtils.featureNotAvailableInCustomEntitlementsComputationModeError().asPublicError)
            return
       }

        self.identityManager.logOut { error in
            guard error == nil else {
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, error?.asPublicError)
                    }
                }
                return
            }

            self.internalDelegate?.authenticatorDidChangeIdentity { result in
                completion?(result.value, result.error)
            }
        }
    }

    public func _revokeCurrentAccessToken(completion: ((PublicError?) -> Void)?) {
        guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
            completion?(NewErrorUtils.featureNotAvailableInCustomEntitlementsComputationModeError().asPublicError)
            return
       }

        self.identityManager.revokeCurrentAccessToken { error in
            if let completion = completion {
                self.operationDispatcher.dispatchOnMainThread {
                    completion(error?.asPublicError)
                }
            }
        }
    }

    // MARK: - Async

    @available(*, deprecated, message: """
    The appUserID passed to logIn is a constant string known at compile time.
    This is likely a programmer error. This ID is used to identify the current user.
    See https://docs.revenuecat.com/docs/user-ids for more information.
    """)
    public func identifyCurrentUser(as appUserID: StaticString) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        Logger.warn(Strings.identity.logging_in_with_static_string)
        return try await identifyCurrentUser(as: appUserID.description)
    }

    @_disfavoredOverload
    public func identifyCurrentUser(as appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await withUnsafeThrowingContinuation { continuation in
            self.identifyCurrentUser(as: appUserID, completion: { customerInfo, created, error in
                continuation.resume(with: Result(customerInfo, error)
                    .map { ($0, created) })
            })
        }
    }

    public func logIn(using token: ExternalToken) async throws -> CustomerInfo {
        return try await withUnsafeThrowingContinuation { continuation in
            self.logIn(using: token, completion: { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            })
        }
    }

    public func logOut() async throws -> CustomerInfo {
        return try await withUnsafeThrowingContinuation { continuation in
            self.logOut(completion: { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            })
        }
    }

    public func _revokeCurrentAccessToken() async throws {
        try await withUnsafeThrowingContinuation { continuation in
            self._revokeCurrentAccessToken(completion: { error in
                let result: Result<Void, Error> = error.map { .failure($0) } ?? .success(())
                continuation.resume(with: result)
            })
        }
    }

}
