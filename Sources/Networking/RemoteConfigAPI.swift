//
//  RemoteConfigAPI.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

class RemoteConfigAPI {

    typealias RemoteConfigResponseHandler = Backend.ResponseHandler<RemoteConfigFetchResult>

    private let callbackCache: CallbackCache<RemoteConfigCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func getRemoteConfig(
        request: RemoteConfigRequest = .init(),
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    ) {
        let factory = GetRemoteConfigOperation.createFactory(
            configuration: self.backendConfig,
            callbackCache: self.callbackCache,
            request: request
        )

        let callback = RemoteConfigCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}

enum RemoteConfigFetchResult {

    case updated(container: RCContainer, verificationResult: VerificationResult)
    case notModified(verificationResult: VerificationResult)

    var container: RCContainer? {
        switch self {
        case let .updated(container, _):
            return container
        case .notModified:
            return nil
        }
    }

    var verificationResult: VerificationResult {
        switch self {
        case let .updated(_, verificationResult),
             let .notModified(verificationResult):
            return verificationResult
        }
    }

    init(response: VerifiedHTTPResponse<RCContainer?>) {
        if let container = response.body {
            self = .updated(container: container, verificationResult: response.verificationResult)
        } else {
            self = .notModified(verificationResult: response.verificationResult)
        }
    }

}
