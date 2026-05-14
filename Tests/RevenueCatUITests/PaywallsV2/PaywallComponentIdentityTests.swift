//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallComponentIdentityTests: TestCase {

    func testCopiedPaywallsWithSameComponentIDHaveDifferentObservableIdentity() {
        let original = PaywallComponentIdentity(
            paywallID: "paywall_original",
            componentID: "component_title",
            type: "text",
            name: "Title"
        )
        let copy = PaywallComponentIdentity(
            paywallID: "paywall_copy",
            componentID: "component_title",
            type: "text",
            name: "Title"
        )

        XCTAssertNotEqual(original, copy)
    }

    func testSamePaywallAndComponentIDHaveSameObservableIdentity() {
        let left = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: "First"
        )
        let right = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: "Renamed"
        )

        XCTAssertEqual(left, right)
    }

    func testSamePaywallAndComponentIDIgnoresTypeMetadata() {
        let textIdentity = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: nil
        )
        let wrappedIdentity = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "stack",
            name: nil
        )

        XCTAssertEqual(textIdentity, wrappedIdentity)
    }

    func testRuntimeScopesSeparateSamePaywallRenderedTwice() {
        let identity = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: nil
        )
        let firstScope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 7,
            workflowPageID: nil
        )
        let secondScope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 7,
            workflowPageID: nil
        )

        XCTAssertNotEqual(
            PaywallStateKey(scope: firstScope, component: identity, field: .component("visible")),
            PaywallStateKey(scope: secondScope, component: identity, field: .component("visible"))
        )
    }

    func testComponentFieldCanBeBuiltFromOverridePropertyName() {
        let builder = PaywallOverridePropertyKeyBuilder()

        XCTAssertEqual(
            PaywallStateKey.Field.component("color").rawValue,
            "component.color"
        )
        XCTAssertEqual(
            builder.field(forPropertyPath: "iconName").rawValue,
            "component.iconName"
        )
        XCTAssertEqual(
            builder.field(forPropertyPath: "font_weight").rawValue,
            "component.font_weight"
        )
    }

    func testPaywallKeyUsesSyntheticPaywallComponentIdentity() {
        let scope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 7,
            workflowPageID: nil
        )

        let key = PaywallStateKey.paywall(scope: scope, field: .rootSelectedPackageID)

        XCTAssertEqual(key.scope, scope)
        XCTAssertEqual(key.field, .rootSelectedPackageID)
        XCTAssertEqual(key.component.paywallID, "paywall_a")
        XCTAssertEqual(key.component.componentID, "paywall")
        XCTAssertEqual(key.component.type, "paywall")
    }

}

#endif
