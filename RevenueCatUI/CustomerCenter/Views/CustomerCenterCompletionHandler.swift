//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterCompletionHandler.swift
//
//  Created by Cesar de la Vega on 6/7/24.

import Foundation
import SwiftUI

final class CustomerCenterCompletionHandler: ObservableObject {

    @Published
    fileprivate(set) var customerCenterResult: CustomerCenterResult?

    static func `default`() -> Self {
        return .init()
    }

    func supportContacted() {
        self.customerCenterResult = CustomerCenterResult(status: .contactSupport)
    }

}

struct CustomerCenterResult: Equatable {

    var status: CustomerCenterStatus
    // swiftlint:disable:next todo
    // TODO: store error

    init(status: CustomerCenterStatus) {
        self.status = status
    }

    init?(status: CustomerCenterStatus?) {
        guard let status else { return nil }
        self.init(status: status)
    }

}

struct CustomerCenterResultPreferenceKey: PreferenceKey {

    static var defaultValue: CustomerCenterResult?

    static func reduce(value: inout CustomerCenterResult?, nextValue: () -> CustomerCenterResult?) {
        value = nextValue()
    }

}
