//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallInteractionEvent.swift
//

import Foundation

// swiftlint:disable missing_docs

public typealias PaywallInteractionHandler = @MainActor (_ event: PaywallInteractionEvent) -> Void

/// A paywall control interaction.
@objc(RCPaywallInteractionEvent)
public final class PaywallInteractionEvent: NSObject, @unchecked Sendable {

    /// The interaction as snake-case keys (``Key/name``) for analytics SDKs; keys that do not apply are absent.
    @objc public let rawProperties: [String: Any]

    init(rawProperties: [String: Any]) {
        self.rawProperties = rawProperties
        super.init()
    }

    /// The value for `key`, or `nil` when it does not apply to this interaction.
    public func property<Value>(for key: Key<Value>) -> Value? {
        return self.rawProperties[key.name] as? Value
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PaywallInteractionEvent else { return false }
        return (self.rawProperties as NSDictionary).isEqual(to: other.rawProperties)
    }

    public override var hash: Int {
        return (self.rawProperties as NSDictionary).hash
    }

    public override var description: String {
        return "PaywallInteractionEvent(\(self.rawProperties))"
    }

    public struct Key<Value>: Sendable {

        public let name: String

        init(_ name: String) {
            self.name = name
        }

    }

    public struct Keys {
        private init() {}

        /// Milliseconds since the epoch.
        public static let timestamp = Key<UInt64>("timestamp")
        public static let sessionId = Key<String>("session_id")
        public static let offeringId = Key<String>("offering_id")
        public static let paywallId = Key<String>("paywall_id")
        public static let paywallRevision = Key<Int>("paywall_revision")
        public static let displayMode = Key<String>("display_mode")
        public static let darkMode = Key<Bool>("dark_mode")
        public static let locale = Key<String>("locale")

        public static let componentType = Key<String>("component_type")
        public static let componentValue = Key<String>("component_value")
        public static let componentName = Key<String>("component_name")
        public static let componentUrl = Key<String>("component_url")
        public static let originIndex = Key<Int>("origin_index")
        public static let destinationIndex = Key<Int>("destination_index")
        public static let originContextName = Key<String>("origin_context_name")
        public static let destinationContextName = Key<String>("destination_context_name")
        public static let defaultIndex = Key<Int>("default_index")
        public static let originPackageId = Key<String>("origin_package_id")
        public static let destinationPackageId = Key<String>("destination_package_id")
        public static let defaultPackageId = Key<String>("default_package_id")
        public static let currentPackageId = Key<String>("current_package_id")
        public static let resultingPackageId = Key<String>("resulting_package_id")
        public static let originProductId = Key<String>("origin_product_id")
        public static let destinationProductId = Key<String>("destination_product_id")
        public static let defaultProductId = Key<String>("default_product_id")
        public static let currentProductId = Key<String>("current_product_id")
        public static let resultingProductId = Key<String>("resulting_product_id")

        static let all: Set<String> = [
            timestamp.name, sessionId.name, offeringId.name, paywallId.name, paywallRevision.name,
            displayMode.name, darkMode.name, locale.name,
            componentType.name, componentValue.name, componentName.name, componentUrl.name,
            originIndex.name, destinationIndex.name, originContextName.name, destinationContextName.name,
            defaultIndex.name,
            originPackageId.name, destinationPackageId.name, defaultPackageId.name,
            currentPackageId.name, resultingPackageId.name,
            originProductId.name, destinationProductId.name, defaultProductId.name,
            currentProductId.name, resultingProductId.name
        ]
    }

    /// Known values of ``Keys/componentType``.
    public struct ComponentTypes {
        private init() {}

        public static let tab = "tab"
        public static let `switch` = "switch"
        public static let carousel = "carousel"
        public static let button = "button"
        public static let text = "text"
        public static let package = "package"
        public static let packageSelectionSheet = "package_selection_sheet"
        public static let purchaseButton = "purchase_button"
    }

}
