//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Error+Extensions.swift
//
//  Created by Joshua Liebowitz on 8/6/21.

import Foundation

extension Error {

    /**
     * Addes a sub-error to the userInfo of a new `error` object as some extra context. Sometimes we have multiple error
     * Conditions but only a single place to surface them. This adds the second error as extra context to help during
     * debugging.
     * - Returns: a new error matching `self` but with the `extraContext` and `error` added.
     */
    func addingUnderlyingError(_ error: Error?, extraContext: String? = nil) -> Error {
        guard let underlyingNSError = error as NSError? else {
            return self
        }

        let asNSError = self as NSError
        var userInfo = asNSError.userInfo as [NSError.UserInfoKey: Any]
        userInfo[NSUnderlyingErrorKey as NSString] = underlyingNSError
        userInfo[.extraContext] = extraContext ?? underlyingNSError.localizedDescription
        let nsErrorWithUserInfo = NSError(domain: asNSError.domain,
                                          code: asNSError.code,
                                          userInfo: userInfo as [String: Any])
        return nsErrorWithUserInfo as Error
    }

}

extension NSError {

    var subscriberAttributesErrors: [String: String]? {
        return self.userInfo[ErrorDetails.attributeErrorsKey] as? [String: String]
    }

}
