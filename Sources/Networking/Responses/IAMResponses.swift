//
//  IAMResponses.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

struct TokenResponse: Decodable, HTTPResponseBody {
    let accessToken: String
    let idToken: String?
    let refreshToken: String?
    let scope: String
    let expiresIn: Int
}
