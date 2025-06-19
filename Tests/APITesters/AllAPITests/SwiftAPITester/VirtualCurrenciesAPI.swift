//
//  VirtualCurrenciesAPI.swift
//  SwiftAPITester
//
//  Created by Will Taylor on 6/10/25.
//

import Foundation
import RevenueCat

class VirtualCurrenciesAPI {
    func checkVirtualCurrencies(_ virtualCurrencies: VirtualCurrencies) {
        let all: [String: VirtualCurrency] = virtualCurrencies.all
        let subscriptTest: VirtualCurrency? = virtualCurrencies["test"]
    }
}
