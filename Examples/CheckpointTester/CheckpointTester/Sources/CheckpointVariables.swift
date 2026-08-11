//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointVariables.swift
//
//  Created by Rick van der Linden.
//

import Combine
import Foundation
import RevenueCatUI

final class CheckpointVariables: ObservableObject {

    @Published var variables = [
        CheckpointVariable(name: "source", value: "CheckpointTester"),
    ]

    var checkpointParams: CheckpointParams {
        var customProperties: [String: CheckpointValue] = [:]

        for variable in self.variables {
            let name = variable.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                customProperties[name] = .string(variable.value)
            }
        }

        return CheckpointParams(customProperties: customProperties)
    }

}

struct CheckpointVariable: Identifiable {

    let id = UUID()
    var name = ""
    var value = ""

}
