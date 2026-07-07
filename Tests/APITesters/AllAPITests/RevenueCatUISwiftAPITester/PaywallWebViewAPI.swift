//
//  PaywallWebViewAPI.swift
//  RevenueCatUISwiftAPITester
//
//  Compile-time checks for the Paywalls V2 web_view public API surface.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewApp: View {

    var body: some View {
        Text("")
            .onPaywallWebViewMessage { (message: PaywallWebViewMessage, controller: PaywallWebViewController) in
                let componentID: String = message.componentID
                let type: String = message.type
                let responses: [String: PaywallWebViewValue]? = message.responses
                let error: String? = message.error

                controller.postVariables(
                    componentID: componentID,
                    variables: ["custom": .object(["plan": .string("annual")])]
                )
                controller.postMessage(componentID: componentID, type: type, variables: [:])

                _ = (responses, error)
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func checkPaywallWebViewMessageAPI() {
    let message = PaywallWebViewMessage(
        componentID: "",
        type: "rc:step-complete",
        responses: ["selected_plan": .string("annual")],
        error: nil
    )
    let sameMessage: Bool = message == message
    _ = sameMessage
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func checkPaywallWebViewValueAPI() {
    let string: PaywallWebViewValue = .string("s")
    let number: PaywallWebViewValue = .number(1.5)
    let bool: PaywallWebViewValue = .bool(true)
    let array: PaywallWebViewValue = .array([string, number])
    let object: PaywallWebViewValue = .object(["key": bool])
    let null: PaywallWebViewValue = .null

    let _: String? = string.stringValue
    let _: Double? = number.numberValue
    let _: Bool? = bool.boolValue
    let _: [PaywallWebViewValue]? = array.arrayValue
    let _: [String: PaywallWebViewValue]? = object.objectValue
    let _: Bool = null.isNull
    let _: Set<PaywallWebViewValue> = [string, number]
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
func checkPaywallWebViewMessageActionAPI(
    message: PaywallWebViewMessage,
    controller: PaywallWebViewController
) {
    let action = PaywallWebViewMessageAction { (_: PaywallWebViewMessage, _: PaywallWebViewController) in }
    action(message, controller)
}

#endif
