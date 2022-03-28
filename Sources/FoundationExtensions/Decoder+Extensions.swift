//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Decoder+Extensions.swift
//
//  Created by Joshua Liebowitz on 10/25/21.

import Foundation

extension Decoder {

    func throwValueNotFoundError(expectedType: Any.Type, message: String) -> CodableError {
        let context = DecodingError.Context(codingPath: codingPath,
                                            debugDescription: message,
                                            underlyingError: nil)
        return CodableError.valueNotFound(value: expectedType, context: context)
    }

}
