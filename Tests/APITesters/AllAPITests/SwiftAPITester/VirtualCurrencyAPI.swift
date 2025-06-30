//
//  VirtualCurrencyAPI.swift
//  SwiftAPITester
//
//  Created by Will Taylor on 2/28/25.
//

import Foundation
import RevenueCat

func checkVirtualCurrency(virtualCurrency: VirtualCurrency) {
    let balance: Int = virtualCurrency.balance
    let name: String = virtualCurrency.name
    let code: String = virtualCurrency.code
    let serverDescription: String? = virtualCurrency.serverDescription

    // Ensure that we don't break the nullability of serverDescription.
    // Just ensuring that it's a String? isn't enough since a String can be automatically casted
    // to a String?, like so:
    //
    // let string1: String = ""
    // let string2: String? = string1
    var serverDescriptionNullabilityTest: String? = virtualCurrency.serverDescription
    serverDescriptionNullabilityTest = nil
}
