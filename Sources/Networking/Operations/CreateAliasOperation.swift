//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CreateAliasOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class CreateAliasOperation: CacheableNetworkOperation {

    private let aliasCallbackCache: CallbackCache<AliasCallback>
    private let newAppUserID: String
    private let configuration: UserSpecificConfiguration

    init(configuration: UserSpecificConfiguration,
         newAppUserID: String,
         aliasCallbackCache: CallbackCache<AliasCallback>) {
        self.aliasCallbackCache = aliasCallbackCache
        self.newAppUserID = newAppUserID
        self.configuration = configuration

        super.init(configuration: configuration, individualizedCacheKeyPart: configuration.appUserID + newAppUserID)
    }

    override func begin(completion: @escaping () -> Void) {
        createAlias(completion: completion)
    }

}

private extension CreateAliasOperation {

    func createAlias(completion: @escaping () -> Void) {
        guard let appUserID = try? configuration.appUserID.escapedOrError() else {
            self.aliasCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion?(.missingAppUserID())
            }

            completion()
            return
        }
        Logger.user(Strings.identity.creating_alias)

        let request = HTTPRequest(method: .post(Body(newAppUserID: newAppUserID)),
                                  path: .createAlias(appUserID: appUserID))

        httpClient.perform(request,
                           authHeaders: self.authHeaders) { (response: HTTPResponse<HTTPEmptyResponseBody>.Result) in
            self.aliasCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { aliasCallback in

                aliasCallback.completion?(response.error.map(BackendError.networkError))
            }

            completion()
        }
    }

}

private extension CreateAliasOperation {

    struct Body: Encodable {

        let newAppUserID: String

    }

}
