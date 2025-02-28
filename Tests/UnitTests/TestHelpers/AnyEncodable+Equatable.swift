//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyEncodable+Equatable.swift
//
//  Created by Antonio Pallares on 28/2/25.

import Foundation
@testable import RevenueCat

extension AnyEncodable: @retroactive Equatable {

    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        do {
            let lhsData = try lhs.prettyPrintedData
            let rhsData = try rhs.prettyPrintedData
            return lhsData == rhsData
        } catch {
            return false
        }
    }

}
