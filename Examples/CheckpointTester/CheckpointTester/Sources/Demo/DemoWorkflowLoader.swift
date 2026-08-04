//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DemoWorkflowLoader.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Demo-only workflow loading. Production workflows are fetched from RevenueCat's server.
enum DemoWorkflowLoader {

    private static let workflowIdentifiers = [
        "result_picker",
        "soft_paywall",
        "hard_paywall",
        "onboarding"
    ]

    static func loadBundledWorkflowData() -> [String: Data] {
        return Dictionary(
            uniqueKeysWithValues: Self.workflowIdentifiers.compactMap { identifier in
                guard let url = Bundle.main.url(forResource: identifier, withExtension: "json"),
                      let data = try? Data(contentsOf: url) else {
                    return nil
                }
                return (identifier, data)
            }
        )
    }

}
