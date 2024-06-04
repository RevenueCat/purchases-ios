//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperationQueue+Extensions.swift
//
//  Created by Joshua Liebowitz on 1/20/22.

import Foundation

extension OperationQueue {

    final func addCacheableOperation<T: CacheableNetworkOperation>(
        with factory: CacheableNetworkOperationFactory<T>,
        cacheStatus: CallbackCacheStatus
    ) {
        switch cacheStatus {
        case .firstCallbackAddedToList:
            self.addOperation(factory.create())

            Logger.verbose(Strings.network.enqueing_operation(factory.operationType,
                                                              cacheKey: factory.cacheKey))

        case .addedToExistingInFlightList:
            Logger.debug(
                Strings.network.reusing_existing_request_for_operation(
                    T.self,
                    Logger.verboseLogsEnabled
                    ? factory.cacheKey
                    : factory.cacheKey.prefix(15) + "…"
                )
            )
            return
        }
    }

}
