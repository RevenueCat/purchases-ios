//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ASIdentifierManagerProxy.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 14/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// We need this class to avoid Kid apps being rejected for getting idfa. It seems like App
// Review uses some grep to find the class names, so we ended up creating a fake class that
// exposes the same methods we're looking for in ASIdentifierManager to call the same methods and mangling
// the class names. So that Apple can't find them during the review, but we can still access them on runtime.
class FakeASIdentifierManager: NSObject {

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func sharedManager() -> FakeASIdentifierManager {
        FakeASIdentifierManager()
    }

}

// TODO (post-migration): Make all the things internal again if possible. Test if Objc can be removed.
@objc(RCASIdentifierManagerProxy)
public class ASIdentifierManagerProxy: NSObject {

    static let mangledIdentifierClassName = "NFVqragvsvreZnantre"
    static let mangledIdentifierPropertyName = "nqiregvfvatVqragvsvre"

    static var identifierClass: AnyClass? {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in the AdSupport.framework. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        NSClassFromString(Self.mangledIdentifierClassName.rot13())
    }

    @objc public var adsIdentifier: UUID? {
        guard let classType: AnyClass = Self.identifierClass else {
            return nil
        }
        return classType.sharedManager().value(forKey: Self.mangledIdentifierPropertyName.rot13()) as? UUID
    }

}
