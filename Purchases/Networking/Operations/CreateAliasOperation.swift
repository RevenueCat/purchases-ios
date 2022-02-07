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
    private let createAliasResponseHandler: NoContentResponseHandler
    private let newAppUserID: String
    private let configuration: UserSpecificConfiguration

    init(configuration: UserSpecificConfiguration,
         newAppUserID: String,
         aliasCallbackCache: CallbackCache<AliasCallback>,
         createAliasResponseHandler: NoContentResponseHandler = NoContentResponseHandler()) {
        self.createAliasResponseHandler = createAliasResponseHandler
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
                callback.completion?(ErrorUtils.missingAppUserIDError())
            }

            completion()
            return
        }
        Logger.user(Strings.identity.creating_alias)

        let path = "/subscribers/\(appUserID)/alias"
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["new_app_user_id": newAppUserID],
                                      headers: authHeaders) { statusCode, response, error in
            self.aliasCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { aliasCallback in

                guard let completion = aliasCallback.completion else {
                    return
                }

                self.createAliasResponseHandler.handle(response: response,
                                                       statusCode: statusCode,
                                                       error: error,
                                                       completion: completion)
            }

            completion()
        }
    }

}
