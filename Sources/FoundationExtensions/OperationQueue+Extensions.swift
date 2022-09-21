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

    func addCacheableOperation(_ operation: CacheableNetworkOperation, cacheStatus: CallbackCacheStatus) {
        switch cacheStatus {
        case .firstCallbackAddedToList:
            self.addOperation(operation)
        case .addedToExistingInFlightList:
            Logger.debug(Strings.network.reusing_existing_request_for_operation(operation))
            return
        }
    }

}
