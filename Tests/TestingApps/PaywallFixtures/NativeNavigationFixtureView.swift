//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import SwiftUI
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI

/// Uses the real paywall renderer and a caller-owned navigation stack. No purchases or backend fetches.
struct NativeNavigationFixtureView: View {
    static let workflowName = "native_workflow_navigation"
    static let sheetName = "native_inline_sheet"
    let workflow: Bool
    @State private var dismissed = false
    @State private var path: [Bool] = []

    var body: some View {
        NavigationStack(path: self.$path) {
            if self.dismissed {
                Text("Paywall dismissed")
            } else {
                NavigationLink("Show native paywall", value: true)
                .navigationDestination(for: Bool.self) { _ in
                    self.paywall
                        .onRequestedDismissal {
                            self.dismissed = true
                            self.path = []
                        }
                        .navigationTitle("Native paywall")
                }
                .navigationTitle("Fixture host")
            }
        }
    }

    @ViewBuilder private var paywall: some View {
        if self.workflow {
            PaywallView(
                workflowContext: NativeNavigationFixture.context,
                performPurchase: { _ in (userCancelled: true, error: nil) },
                performRestore: { (success: false, error: nil) }
            )
        } else {
            PaywallView(
                offering: NativeNavigationFixture.sheetOffering,
                performPurchase: { _ in (userCancelled: true, error: nil) },
                performRestore: { (success: false, error: nil) }
            )
        }
    }
}

private enum NativeNavigationFixture {
    static let context: WorkflowContext = {
        do {
            let root = Self.data(title: "Workflow root", buttons: [
                Self.button("Continue", action: .workflowTrigger, id: "continue"),
                try Self.closeWorkflow()
            ])
            let detail = Self.data(title: "Workflow detail", buttons: [
                Self.button("Designed Back", action: .navigateBack, native: true),
                try Self.closeWorkflow()
            ])
            let workflow = PublishedWorkflow(
                id: "native-navigation-fixture", displayName: "Native navigation", initialStepId: "root",
                singleStepFallbackId: nil,
                steps: [
                    "root": WorkflowStep(
                        id: "root", type: "screen", screenId: "root",
                        triggers: [.init(name: nil, type: .onPress, actionId: "next", componentId: "continue")],
                        triggerActions: ["next": .step(stepId: "detail")]
                    ),
                    "detail": WorkflowStep(id: "detail", type: "screen", screenId: "detail")
                ],
                screens: ["root": Self.screen(root), "detail": Self.screen(detail)]
            )
            let offering = Offering(identifier: Self.baseOffering.identifier, serverDescription: "Native navigation",
                                    availablePackages: Self.baseOffering.availablePackages, webCheckoutUrl: nil)
            return try WorkflowPreview.makeContext(workflow: workflow, offerings: [offering],
                                                   uiConfig: Self.baseUIConfig)
        } catch {
            fatalError("Invalid native navigation fixture: \(error)")
        }
    }()

    static var sheetOffering: Offering {
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "native-inline-sheet", name: "Inline sheet",
            stack: .init(
                components: [Self.text("Sheet content"),
                             Self.button("Designed sheet Close", action: .navigateBack, native: true)],
                size: .init(width: .fill, height: .fit(nil)), spacing: 24,
                backgroundColor: .init(light: .hex("#ffffff")),
                padding: .init(top: 32, bottom: 32, leading: 24, trailing: 24)
            ), backgroundBlur: true, size: .init(width: .fill, height: .fixed(280))
        )
        return Offering(
            identifier: "native-sheet", serverDescription: "Native sheet",
            paywallComponents: .init(uiConfig: Self.baseUIConfig, data: Self.data(
                title: "Outer paywall", buttons: [
                    Self.button("Designed outer Close", action: .navigateBack, native: true),
                    Self.button("Open inline sheet", action: .navigateTo(destination: .sheet(sheet: sheet)))
                ]
            )), availablePackages: Self.baseOffering.availablePackages, webCheckoutUrl: nil
        )
    }

    private static var baseOffering: Offering { PaywallFixture.sheetOverContent.offering }
    private static var baseUIConfig: UIConfig {
        guard let components = Self.baseOffering.paywallComponents else {
            fatalError("Sheet fixture must include components")
        }
        return components.uiConfig
    }

    private static func screen(_ data: PaywallComponentsData) -> WorkflowScreen {
        .init(name: nil, templateName: data.templateName, assetBaseURL: data.assetBaseURL,
              componentsConfig: data.componentsConfig, componentsLocalizations: data.componentsLocalizations,
              defaultLocale: "en_US", offeringIdentifier: Self.baseOffering.identifier)
    }

    private static func data(title: String, buttons: [PaywallComponent]) -> PaywallComponentsData {
        .init(
            templateName: "native-navigation-fixture", assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: [Self.text(title)] + buttons,
                             dimension: .vertical(.center, .start),
                             size: .init(width: .fill, height: .fill), spacing: 24,
                             padding: .init(top: 32, bottom: 24, leading: 16, trailing: 16)),
                stickyFooter: nil, background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": Dictionary(uniqueKeysWithValues: [
                "Workflow root", "Workflow detail", "Continue", "Designed Back", "Designed Close",
                "Outer paywall", "Designed outer Close", "Open inline sheet", "Sheet content", "Designed sheet Close"
            ].map { ($0, .string($0)) })], revision: 1, defaultLocaleIdentifier: "en_US"
        )
    }

    private static func text(_ label: String) -> PaywallComponent {
        .text(.init(text: label, color: .init(light: .hex("#000000"))))
    }

    private static func button(
        _ label: String, action: PaywallComponent.ButtonComponent.Action, id: String? = nil, native: Bool = false
    ) -> PaywallComponent {
        .button(.init(id: id, action: action,
                      stack: .init(components: [Self.text(label)],
                                   padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16)),
                      useNativeIfPossible: native))
    }

    /// `close_workflow` is decode-only, so preserve its actual backend representation.
    private static func closeWorkflow() throws -> PaywallComponent {
        let encoded = try JSONEncoder().encode(Self.button("Designed Close", action: .navigateBack, native: true))
        guard var object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        object["action"] = ["type": "close_workflow", "use_native_if_possible": true]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PaywallComponent.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
