//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorCode+Conformances.swift
//
//  Created by Álvaro Brey on 6/10/26.
//

import Foundation

extension ErrorCode: DescribableError {}

// MARK: - PurchasesErrorConvertible

/// An `Error` that can be converted into a `PurchasesError`
protocol PurchasesErrorConvertible: Swift.Error {

    /// Convert the receiver into a `PurchasesError` with all the necessary context.
    ///
    /// ### Related symbols:
    /// - ``ErrorUtils``
    /// - ``ErrorCode``
    var asPurchasesError: PurchasesError { get }

}

extension PurchasesErrorConvertible {

    var asPublicError: PublicError {
        return self.asPurchasesError.asPublicError
    }

    var description: String {
        return self.asPurchasesError.localizedDescription
    }

}
