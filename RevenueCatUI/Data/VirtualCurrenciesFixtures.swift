//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencies+Mock.swift
//
//  Created by Will Taylor on 6/11/25.

import Foundation
import RevenueCat

internal enum VirtualCurrenciesFixtures {
    static var noVirtualCurrencies: RevenueCat.VirtualCurrencies {
        let emptyJSONData = "{\"all\":{}}".data(using: .utf8)
        // swiftlint:disable:next force_try force_unwrapping
        return try! JSONDecoder().decode(RevenueCat.VirtualCurrencies.self, from: emptyJSONData!)
    }

    static var fourVirtualCurrencies: RevenueCat.VirtualCurrencies {
        let jsonData = """
                {
                  "all": {
                    "GLD": {
                      "balance": 100,
                      "code": "GLD",
                      "description": "It's gold",
                      "name": "Gold"
                    },
                    "SLV": {
                      "balance": 200,
                      "code": "SLV",
                      "description": "It's silver",
                      "name": "Silver"
                    },
                    "BRNZ": {
                      "balance": 300,
                      "code": "BRNZ",
                      "description": "It's bronze",
                      "name": "Bronze"
                    },
                    "PLTNM": {
                      "balance": 400,
                      "code": "PLTNM",
                      "description": "It's platinum",
                      "name": "Platinum"
                    }
                  }
                }
                """.data(using: .utf8)

        // swiftlint:disable:next force_try force_unwrapping
        return try! JSONDecoder().decode(RevenueCat.VirtualCurrencies.self, from: jsonData!)
    }

    static var fiveVirtualCurrencies: RevenueCat.VirtualCurrencies {
        let jsonData = """
                {
                  "all": {
                    "GLD": {
                      "balance": 100,
                      "code": "GLD",
                      "description": "It's gold",
                      "name": "Gold"
                    },
                    "SLV": {
                      "balance": 200,
                      "code": "SLV",
                      "description": "It's silver",
                      "name": "Silver"
                    },
                    "BRNZ": {
                      "balance": 300,
                      "code": "BRNZ",
                      "description": "It's bronze",
                      "name": "Bronze"
                    },
                    "PLTNM": {
                      "balance": 400,
                      "code": "PLTNM",
                      "description": "It's platinum",
                      "name": "Platinum"
                    },
                    "RC_COIN": {
                      "balance": 1,
                      "code": "RC_COIN",
                      "description": "It's RevenueCat Coin",
                      "name": "RevenueCat Coin"
                    }
                  }
                }
                """.data(using: .utf8)

        // swiftlint:disable:next force_try force_unwrapping
        return try! JSONDecoder().decode(RevenueCat.VirtualCurrencies.self, from: jsonData!)
    }

    static var oneVirtualCurrency: RevenueCat.VirtualCurrencies {
        let jsonData = """
                {
                  "all": {
                    "GLD": {
                      "balance": 100,
                      "code": "GLD",
                      "description": "It's gold",
                      "name": "Gold"
                    }
                  }
                }
                """.data(using: .utf8)

        // swiftlint:disable:next force_try force_unwrapping
        return try! JSONDecoder().decode(RevenueCat.VirtualCurrencies.self, from: jsonData!)
    }

    static var virtualCurrenciesWithZeroBalance: RevenueCat.VirtualCurrencies {
        let jsonData = """
                {
                  "all": {
                    "GLD": {
                      "balance": 0,
                      "code": "GLD",
                      "description": "It's gold",
                      "name": "Gold"
                    },
                    "SLV": {
                      "balance": 0,
                      "code": "SLV",
                      "description": "It's silver",
                      "name": "Silver"
                    }
                  }
                }
                """.data(using: .utf8)

        // swiftlint:disable:next force_try force_unwrapping
        return try! JSONDecoder().decode(RevenueCat.VirtualCurrencies.self, from: jsonData!)
    }
}
