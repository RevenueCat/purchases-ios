//
//  IAMResponses.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

struct TokenResponse: Decodable, HTTPResponseBody {

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case scope = "scope"
        case expiresIn = "expires_in"
    }

    let accessToken: String
    let idToken: String?
    let refreshToken: String?
    let scope: String
    let expiresIn: Int
}
