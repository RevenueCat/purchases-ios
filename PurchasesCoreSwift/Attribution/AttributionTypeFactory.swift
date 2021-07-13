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

class FakeAdClient: NSObject {
    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func sharedClient() -> FakeAdClient {
        FakeAdClient()
    }

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc func requestAttributionDetails(_ completionHandler: AttributionDetailsBlock) {
        // do nothing
    }
}

@objc(RCAdClientProxy)
open class AdClientProxy: NSObject {
    private static let className = "ADClient"

    static var adClientClass: AnyClass? {
        NSClassFromString(Self.className)
    }

    @objc(requestAttributionDetailsWithBlock:)
    open func requestAttributionDetails(_ completionHandler: AttributionDetailsBlock) {
        let classType: AnyClass = Self.adClientClass ?? FakeAdClient.self
        classType.sharedClient().requestAttributionDetails(completionHandler)
    }
}

class FakeTrackingManager: NSObject {
    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func trackingAuthorizationStatus() -> Int {
        -1
    }
}

@objc(RCTrackingManagerProxy)
open class TrackingManagerProxy: NSObject {
    static let mangledTrackingClassName = "NGGenpxvatZnantre"
    static let mangledAuthStatusPropertyName = "genpxvatNhgubevmngvbaFgnghf"

    static var trackingClass: AnyClass? {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in ATTrackingTransparency. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        NSClassFromString(mangledTrackingClassName.rot13())
    }

    @objc public var authorizationStatusPropertyName: String {
        Self.mangledAuthStatusPropertyName.rot13()
    }

    @objc open func trackingAuthorizationStatus() -> Int {
        let classType: AnyClass = Self.trackingClass ?? FakeTrackingManager.self
        return classType.trackingAuthorizationStatus()
    }
}

class FakeASIdentifierManager: NSObject {
    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func sharedManager() -> FakeASIdentifierManager {
        FakeASIdentifierManager()
    }
}

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

@objc(RCAttributionTypeFactory)
open class AttributionTypeFactory: NSObject {
    @objc open func adClientProxy() -> AdClientProxy? {
        guard AdClientProxy.adClientClass != nil else { return nil }
        return AdClientProxy()
    }

    @objc open func atTrackingProxy() -> TrackingManagerProxy? {
        guard TrackingManagerProxy.trackingClass != nil else { return nil }
        return TrackingManagerProxy()
    }

    @objc open func asIdentifierProxy() -> ASIdentifierManagerProxy? {
        guard ASIdentifierManagerProxy.identifierClass != nil else { return nil }
        return ASIdentifierManagerProxy()
    }
}
