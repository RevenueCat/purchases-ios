//
//  IAMCallbacks.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

struct TokenCallback: CacheKeyProviding {

    let cacheKey: String
    let completion: TokenAPI.TokenResponseHandler

}

struct TokenRevokeCallback: CacheKeyProviding {
    let cacheKey: String
    let completion: (BackendError?) -> Void
}
