//
//  ApplicationManager.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation


public protocol ApplicationManagerType {

    func loadApplicationData() async throws -> DeveloperResponse
    func signOut()

}

public final class ApplicationManager: ApplicationManagerType {

    private var client = HTTPClient.shared

    public init() {}

    /// - Throws: ``ApplicationManager/Error``
    public func loadApplicationData() async throws -> DeveloperResponse {
        do {
            return try await self.client.perform(
                .init(method: .get, endpoint: .me)
            )
        } catch HTTPClient.Error.errorResponse(.unauthorized, _, _, _),
                HTTPClient.Error.errorResponse(.forbidden, _, _, _){
            throw Error.unauthenticated
        } catch let error as HTTPClient.Error {
            throw Error.requestError(error)
        } catch URLError.cancelled, is CancellationError {
            throw Error.operationCancelled
        } catch {
            throw Error.unknown(error)
        }
    }

    public func signOut() {
        self.client.removeCookies()
    }

}

// MARK: - Errors

public extension ApplicationManager {

    enum Error: Swift.Error {
        case unauthenticated
        case requestError(HTTPClient.Error)
        case operationCancelled
        case unknown(Swift.Error)
    }

}
