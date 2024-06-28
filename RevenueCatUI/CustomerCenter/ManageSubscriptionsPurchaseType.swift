//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsPurchaseType.swift
//
//
//  Created by Cesar de la Vega on 12/6/24.
//

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol ManageSubscriptionsPurchaseType: Sendable {

    @Sendable
    func customerInfo() async throws -> CustomerInfo

    @Sendable
    func products(_ productIdentifiers: [String]) async -> [StoreProduct]

    @Sendable
    func showManageSubscriptions() async throws

    @Sendable
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus

}
