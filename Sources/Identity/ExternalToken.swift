//
//  ExternalToken.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/8/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

@_spi(Experimental)
@objc(RCExternalToken)
public final class ExternalToken: NSObject {

    @objc public static func oidc(_ token: Data) -> ExternalToken {
        ExternalToken(token: .oidc(token))
    }

    internal let authToken: ExternalAuthToken

    private init(token: ExternalAuthToken) {
        self.authToken = token
        super.init()
    }

}

internal enum ExternalAuthToken: Hashable {
    case oidc(Data)

    internal var cacheIdentifier: String {
        switch self {
        case .oidc(let data): return "oidc-\(data.hashString)"
        }
    }

    internal var tokenData: Data {
        switch self {
        case .oidc(let data): return data
        }
    }
}
