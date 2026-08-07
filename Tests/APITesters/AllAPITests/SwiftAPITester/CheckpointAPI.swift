//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointAPI.swift
//
//  Created by Rick van der Linden.
//

#if ENABLE_CHECKPOINTS

import RevenueCat

func checkCheckpointCoreAPI() {
    let string: CheckpointValue = .string("value")
    let integer: CheckpointValue = .integer(2)
    let double: CheckpointValue = .double(4.5)
    let boolean: CheckpointValue = .boolean(true)
    let _: Any = string.foundationValue

    let params = CheckpointParams(customProperties: [
        "string": string,
        "integer": integer,
        "double": double,
        "boolean": boolean
    ])
    let _: [String: CheckpointValue] = params.customProperties
}

#endif
