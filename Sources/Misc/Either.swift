//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Either.swift
//
//  Created by Nacho Soto on 10/7/22.

import Foundation

/// A type that may contain one of two possible values.
internal enum Either<Left, Right> {

    case left(Left)
    case right(Right)

}

extension Either {

    var left: Left? {
        switch self {
        case let .left(left): return left
        case .right: return nil
        }
    }

    var right: Right? {
        switch self {
        case .left: return nil
        case let .right(right): return right
        }
    }

}
