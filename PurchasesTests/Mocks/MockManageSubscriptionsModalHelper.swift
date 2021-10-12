//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockManageSubsModalHelper.swift
//
//  Created by César de la Vega on 10/8/21.

import Foundation
@testable import RevenueCat

class MockManageSubscriptionsModalHelper: ManageSubscriptionsModalHelper {

    var mockError: ManageSubscriptionsModalError?

#if os(iOS) || os(macOS)
    @available(iOS 9.0, *)
    @available(macOS 10.12, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func showManageSubscriptionModal(completion: @escaping (Result<Void, ManageSubscriptionsModalError>) -> Void) {
        if let manageSubscriptionsModalError = mockError {
            completion(.failure(manageSubscriptionsModalError))
        } else {
            completion(.success(Void()))
        }
    }
#endif

}
