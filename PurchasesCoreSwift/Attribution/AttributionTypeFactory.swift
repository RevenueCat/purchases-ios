//
//  AttributionTypeFactory.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 9/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal the class and all these protocols and properties.

public typealias AttributionDetailsBlock = ([String: Any]?, Error?) -> Void

@objc public enum FakeTrackingManagerAuthorizationStatus: Int {
    case notDetermined = 0
    case restricted
    case denied
    case authorized
}

@objc public protocol FakeAdClient: AnyObject {
    static func sharedClient() -> FakeAdClient
    @objc(requestAttributionDetailsWithBlock:)
    func requestAttributionDetails(_ completionHandler: AttributionDetailsBlock)
}

@objc public protocol FakeASIdentifierManager: AnyObject {
    static func sharedManager() -> FakeASIdentifierManager
}

@objc public protocol FakeTrackingManager: AnyObject {
    static func trackingAuthorizationStatus() -> Int
}

@objc(RCAttributionTypeFactory)
open class AttributionTypeFactory: NSObject {
    let mangledIdentifierClassName = "NFVqragvsvreZnantre"
    let mangledIdentifierPropertyName = "nqiregvfvatVqragvsvre"
    let mangledAuthStatusPropertyName = "genpxvatNhgubevmngvbaFgnghf"
    let mangledTrackingClassName = "NGGenpxvatZnantre"

    @objc open func adClientClass() -> FakeAdClient.Type? {
        NSClassFromString("ADClient") as? FakeAdClient.Type
    }

    @objc open func atTrackingClass() -> FakeTrackingManager.Type? {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in ATTrackingTransparency. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        let className = mangledTrackingClassName.rot13()
        return NSClassFromString(className) as? FakeTrackingManager.Type
    }

    @objc public func asIdentifierClass() -> FakeASIdentifierManager.Type? {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in the AdSupport.framework. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        let className = mangledIdentifierClassName.rot13()
        return NSClassFromString(className) as? FakeASIdentifierManager.Type
    }

    @objc public var asIdentifierPropertyName: String {
        mangledIdentifierPropertyName.rot13()
    }

    @objc public var authorizationStatusPropertyName: String {
        mangledAuthStatusPropertyName.rot13()
    }
}
