//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomVariables.swift
//
//  Created by Rick van der Linden.
//

import Combine
import Foundation
@_spi(CheckpointsInternal) import RevenueCatUI

final class CustomVariables: ObservableObject {

    @Published var variables = [
        CustomVariable(name: "source", value: "CheckpointTester"),
    ]

    var checkpointCustomVariables: [String: CustomVariableValue] {
        var customVariables: [String: CustomVariableValue] = [:]

        for variable in self.variables {
            let name = variable.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                customVariables[name] = .string(variable.value)
            }
        }

        return customVariables
    }

}

struct CustomVariable: Identifiable {

    let id = UUID()
    var name = ""
    var value = ""

}
