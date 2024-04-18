//
//  HTTPEndpoint.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation


public enum HTTPEndpoint {

    case login(user: String, password: String, code: String?)
    case me
    case offerings(projectID: String)
    case paywalls(projectID: String)

}

extension HTTPEndpoint {

    var path: String {
        switch self {
        case .login: return "login"
        case .me: return "me"
        case let .offerings(projectID): return "me/projects/\(projectID)/offerings"
        case let .paywalls(projectID): return "me/projects/\(projectID)/paywalls"
        }
    }

    var isInternal: Bool {
        switch self {
        case .login: false
        case .me: false
        case .offerings: true
        case .paywalls: true
        }
    }

    var parameters: [String: String?]? {
        switch self {
        case .login: return nil
        case .me: return nil
        case .offerings, .paywalls: return nil
        }
    }

    var body: Data? {
        get throws {
            switch self {
            case let .login(user, password, code):
                return try LoginRequestBody(email: user, password: password, otpCode: code).jsonEncodedData
            case .me: return nil
            case .offerings, .paywalls: return nil
            }
        }
    }

}

// MARK: -

private struct LoginRequestBody: Encodable {

    var email: String
    var password: String
    var otpCode: String?

}
