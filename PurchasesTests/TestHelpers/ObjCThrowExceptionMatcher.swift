//
//  ObjCThrowExceptionMatcher.swift
//  PurchasesTests
//
//  Nimble's exception matcher isn't supported when installed via SPM.
//  See https://github.com/Quick/Nimble/blob/main/Sources/Nimble/Matchers/RaisesException.swift#L1
//  Also, Nimble's throwAssertion() matcher doesn't work for ARM64.
//  See https://github.com/Quick/Nimble/blob/main/Sources/Nimble/Matchers/ThrowAssertion.swift#L125
//  This solution solves both issues because assertions in Objc come over as an exception, so we can catch them, and
//  then treat them as errors, and then compare.
//
//  Created by Joshua Liebowitz on 6/10/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import Nimble

enum ObjCException: String {
    
    case parameterAssert = "NSInternalInconsistencyException"
    
}

func expectToThrowException(_ named: ObjCException? = nil, closure: @escaping  () -> Void) -> Void {
    do {
        try RCObjC.catchException {
            let _ = closure()
            fail("No exception thrown.")
        }
    } catch {
        let error = error as NSError
        print("Threw " + error.domain)
        let message = messageForError(error: error, named: named?.rawValue)
        let matches = errorMatchesNonNilFields(error, named: named?.rawValue)
        if !matches {
            Nimble.fail(message.expectedMessage)
        }
    }
}

func expectToNotThrowException(closure: @escaping  () -> Void) -> Void {
    do {
        try RCObjC.catchException {
            let _ = closure()
        }
    } catch {
        let error = error as NSError
        print("Threw " + error.domain)
        let message = messageForError(error: error, named: error.domain)
        Nimble.fail(message.expectedMessage)
    }
}

fileprivate func messageForError(error: NSError?, named: String?) -> ExpectationMessage {
    var rawMessage: String = "raise exception"

    if let named = named {
        rawMessage += " with name <\(named)>"
    }

    if named == nil {
        rawMessage = "raise any exception"
    }

    let actual: String
    if let realError = error {
        let errorString = stringify(realError)
        let errorDomain = "domain=\(realError.domain)"
        let errorDescription = "description=\(stringify(realError.description))"
        let errorUserInfo = "userInfo=\(stringify(realError.userInfo))"
        actual = "\(errorString) { \(errorDomain), '\(errorDescription)', \(errorUserInfo) }"
    } else {
        actual = "no exception"
    }

    return .expectedCustomValueTo(rawMessage, actual: actual)
}

 fileprivate func errorMatchesNonNilFields(_ error: NSError?, named: String?) -> Bool {
    var matches = false

    if let error = error {
        matches = true

        if let named = named, error.domain != named {
            matches = false
        }
    }
    return matches
}
