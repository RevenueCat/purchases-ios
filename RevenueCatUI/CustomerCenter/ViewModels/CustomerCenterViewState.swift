//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewState.swift
//
//
//  Created by Cesar de la Vega on 11/6/24.
//

import Foundation

enum CustomerCenterViewState: Equatable {

    case notLoaded
    case success
    case error(Error)

    static func == (lhs: CustomerCenterViewState, rhs: CustomerCenterViewState) -> Bool {
        switch (lhs, rhs) {
        case (.notLoaded, .notLoaded):
            return true
        case (.success, .success):
            return true
        case (let .error(lhsError), let .error(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

}
