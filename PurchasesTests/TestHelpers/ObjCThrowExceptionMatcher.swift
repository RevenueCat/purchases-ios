//
//  ObjCThrowExceptionMatcher.swift
//  PurchasesTests
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

internal func messageForError(error: NSError?, named: String?) -> ExpectationMessage {
    var rawMessage: String = "raise exception"

    if let named = named {
        rawMessage += " with name <\(named)>"
    }

    if named == nil {
        rawMessage = "raise any exception"
    }

    let actual: String
    if let realError = error {
        // swiftlint:disable:next line_length
        actual = "\(String(describing: type(of: realError))) { domain=\(realError.domain), description='\(stringify(realError.description))', userInfo=\(stringify(realError.userInfo)) }"
    } else {
        actual = "no exception"
    }

    return .expectedCustomValueTo(rawMessage, actual: actual)
}

internal func errorMatchesNonNilFields(_ error: NSError?, named: String?) -> Bool {
    var matches = false

    if let error = error {
        matches = true

        if let named = named, error.domain != named {
            matches = false
        }
    }
    return matches
}
