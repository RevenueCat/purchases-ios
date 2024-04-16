//
//  AuthenticationActor.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public protocol AuthenticationActorType {
    
    func logIn(user: String, password: String, code: String?) async throws

}

public actor AuthenticationActor: AuthenticationActorType {

    private var client: HTTPClient = HTTPClient.shared

    public init() {}

    /// - Returns: authentication code
    /// - Throws: ``AuthenticationActor/Error``
    public func logIn(user: String, password: String, code: String?) async throws {
        do {
            let _: LoginResponse = try await self.client.perform(
                .init(
                    method: .post,
                    endpoint: .login(
                        user: user,
                        password: password,
                        code: code?.notEmptyOrWhitespaces
                    )
                )
            )
        } catch HTTPClient.Error.errorResponse(_, .optCodeRequired, _, _) {
            throw Error.codeRequired
        } catch HTTPClient.Error.errorResponse(.unauthorized, _, _, _),
                    HTTPClient.Error.errorResponse(.forbidden, _, _, _) {
            throw Error.invalidCredentials
        } catch let error as HTTPClient.Error {
            throw Error.requestError(error)
        } catch {
            throw Error.unknown(error)
        }
    }

}

// MARK: - Errors

public extension AuthenticationActor {

    enum Error: Swift.Error {
        case codeRequired
        case invalidCredentials
        case requestError(HTTPClient.Error)
        case unknown(Swift.Error)
    }

}

extension AuthenticationActor.Error: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .codeRequired:
            return "Code required"
        case .invalidCredentials:
            return "Error"
        case .requestError, .unknown:
            return nil
        }
    }

    public var failureReason: String? {
        switch self {
        case .codeRequired: 
            return "This account required 2FA"

        case .invalidCredentials:
            return "Invalid credentials"

        case let .requestError(error):
            return error.failureReason

        case let .unknown(error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

}
