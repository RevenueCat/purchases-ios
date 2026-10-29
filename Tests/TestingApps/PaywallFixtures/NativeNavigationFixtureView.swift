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
    @State private var modalPresented = false

    private var presentation: String {
        ProcessInfo.processInfo.environment["PAYWALL_NATIVE_PRESENTATION"] ?? "push"
    }

    var body: some View {
        NavigationStack(path: self.$path) {
            if self.dismissed {
                Text("Paywall dismissed")
            } else if self.presentation != "push" {
                Button("Show native paywall") { self.modalPresented = true }
                    .navigationTitle("Fixture host")
            } else {
                NavigationLink("Show native paywall", value: true)
                .navigationDestination(for: Bool.self) { _ in
                    self.presentedPaywall
                }
                .navigationTitle("Fixture host")
            }
        }
        .sheet(isPresented: Binding(
            get: { self.presentation == "sheet" && self.modalPresented },
            set: { self.modalPresented = $0 }
        )) { NavigationStack { self.presentedPaywall } }
        #if os(iOS)
        .fullScreenCover(isPresented: Binding(
            get: { self.presentation == "full_screen" && self.modalPresented },
            set: { self.modalPresented = $0 }
        )) { NavigationStack { self.presentedPaywall } }
        #endif
    }

    private var presentedPaywall: some View {
        self.paywall
            .onRequestedDismissal {
                self.dismissed = true
                self.path = []
                self.modalPresented = false
            }
            .navigationTitle("Native paywall")
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
                offering: ProcessInfo.processInfo.environment["PAYWALL_CAROUSEL_BUTTONS"] != nil
                    ? NativeNavigationFixture.carouselOffering : NativeNavigationFixture.sheetOffering,
                performPurchase: { _ in (userCancelled: true, error: nil) },
                performRestore: { (success: false, error: nil) }
            )
        }
    }
}

enum NativeNavigationFixture {
    static let context = Self.makeContext()

    static func makeContext(native: Bool = true, rootBack: Bool = false, analytics: Bool = false) -> WorkflowContext {
        do {
            let root = Self.data(title: "Workflow root", buttons: [
                Self.button("Continue", action: .workflowTrigger, id: "continue")
            ], headerClose: rootBack
                ? Self.button("Designed Back", action: .navigateBack, native: native)
                : try Self.closeWorkflow(native: native))
            let detail = Self.data(title: "Workflow detail", buttons: [
                Self.button("Designed Back", action: .navigateBack, native: native),
                Self.button("Continue without Close", action: .workflowTrigger, id: "no_close"),
                Self.button("Open inline sheet", action: .navigateTo(destination: .sheet(sheet: Self.inlineSheet)))
            ], headerClose: try Self.closeWorkflow(native: native))
            let withoutClose = Self.data(title: "Workflow without Close", buttons: [
                Self.button("Designed Back", action: .navigateBack, native: native)
            ])
            let workflow = PublishedWorkflow(
                id: "native-navigation-fixture", displayName: "Native navigation", initialStepId: "root",
                singleStepFallbackId: nil,
                steps: [
                    "root": try Self.step("root", component: "continue", next: "detail", analytics: analytics),
                    "detail": try Self.step("detail", component: "no_close", next: "no_close", analytics: analytics),
                    "no_close": try Self.step("no_close", analytics: analytics)
                ],
                screens: ["root": Self.screen(root), "detail": Self.screen(detail),
                          "no_close": Self.screen(withoutClose)]
            )
            let offering = Offering(identifier: Self.baseOffering.identifier, serverDescription: "Native navigation",
                                    availablePackages: Self.baseOffering.availablePackages, webCheckoutUrl: nil)
            return try WorkflowPreview.makeContext(workflow: workflow, offerings: [offering],
                                                   uiConfig: Self.baseUIConfig)
        } catch {
            fatalError("Invalid native navigation fixture: \(error)")
        }
    }

    private static func step(
        _ id: String, component: String? = nil, next: String? = nil, analytics: Bool
    ) throws -> WorkflowStep {
        var json: [String: Any] = ["id": id, "type": "screen", "screen_id": id]
        if let component, let next {
            json["triggers"] = [["type": "on_press", "action_id": "next", "component_id": component]]
            json["trigger_actions"] = ["next": ["type": "step", "step_id": next]]
        }
        if analytics { json["metadata"] = ["screen_type": ["paywall"]] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorkflowStep.self, from: JSONSerialization.data(withJSONObject: json))
    }

    static var inlineSheet: PaywallComponent.ButtonComponent.Sheet {
        .init(
            id: "native-inline-sheet", name: "Inline sheet",
            stack: .init(
                components: [Self.text("Sheet content"),
                             Self.badgedButton("Designed sheet Close")],
                size: .init(width: .fill, height: .fit(nil)), spacing: 24,
                backgroundColor: .init(light: .hex("#ffffff")),
                padding: .init(top: 32, bottom: 32, leading: 24, trailing: 24)
            ), backgroundBlur: true, size: .init(width: .fill, height: .fixed(280))
        )
    }

    static var sheetOffering: Offering {
        Offering(
            identifier: "native-sheet", serverDescription: "Native sheet",
            paywallComponents: .init(uiConfig: Self.baseUIConfig, data: Self.data(
                title: "Outer paywall", buttons: [
                    Self.badgedButton("Designed outer Close"),
                    Self.button("Open inline sheet", action: .navigateTo(destination: .sheet(sheet: Self.inlineSheet)))
                ]
            )), availablePackages: Self.baseOffering.availablePackages, webCheckoutUrl: nil
        )
    }

    // Match Catbone's Close-over-hero layout without fetching remote media.
    static var carouselOffering: Offering {
        let pages: [PaywallComponent.StackComponent] = (1...5).map { index in
            let close = PaywallComponent.button(.init(
                action: .navigateBack, stack: .init(
                    components: [Self.text("Carousel Close \(index)")],
                    dimension: .vertical(.center, .center),
                    size: .init(width: .fixed(32), height: .fixed(32)),
                    margin: .init(top: 16, bottom: 0, leading: 0, trailing: 16)
                ), useNativeIfPossible: ProcessInfo.processInfo.environment["PAYWALL_CAROUSEL_BUTTONS"] == "native"
            ))
            return .init(components: [
                .stack(.init(components: [
                    .stack(.init(components: [], size: .init(width: .fill, height: .fixed(380)),
                                 backgroundColor: .init(light: .hex("#EEEEFF")))),
                    .stack(.init(components: [.stack(.init(components: [close]))]))
                ], dimension: .zlayer(.topTrailing), size: .init(width: .fill, height: .fit(nil)))),
                Self.text("Carousel page \(index)")
            ], size: .init(width: .fill, height: .fit(nil)), spacing: 20)
        }
        var data = Self.data(title: "Outer paywall", buttons: [.carousel(.init(
            pages: pages, pageAlignment: .top, pagePeek: 0
        ))])
        data.componentsLocalizations["en_US"] = (data.componentsLocalizations["en_US"] ?? [:]).merging(
            Dictionary(uniqueKeysWithValues: (1...5).flatMap {
                ["Carousel page \($0)", "Carousel Close \($0)"]
            }.map { ($0, .string($0)) }), uniquingKeysWith: { _, new in new }
        )
        return Offering(identifier: "carousel-close", serverDescription: "Carousel Close",
                        paywallComponents: .init(uiConfig: Self.baseUIConfig, data: data),
                        availablePackages: Self.baseOffering.availablePackages, webCheckoutUrl: nil)
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

    private static func data(
        title: String, buttons: [PaywallComponent], headerClose: PaywallComponent? = nil
    ) -> PaywallComponentsData {
        .init(
            templateName: "native-navigation-fixture", assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: [Self.text(title)] + buttons,
                             dimension: .vertical(.center, .start),
                             size: .init(width: .fill, height: .fill), spacing: 24,
                             padding: .init(top: 0, bottom: 24, leading: 16, trailing: 16)),
                header: headerClose.map { close in
                    .init(stack: .init(components: [close], size: .init(width: .fill, height: .fixed(120)),
                                       backgroundColor: .init(light: .hex("#ff00ff"))))
                },
                stickyFooter: nil, background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": Dictionary(uniqueKeysWithValues: [
                "Workflow root", "Workflow detail", "Workflow without Close", "Continue", "Continue without Close",
                "Designed Back", "Designed Close",
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
        .button(.init(name: label, id: id, action: action,
                      stack: .init(components: [Self.text(label)],
                                   padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16)),
                      useNativeIfPossible: native))
    }

    private static func badgedButton(_ label: String) -> PaywallComponent {
        let mode = ProcessInfo.processInfo.environment["PAYWALL_BADGE_BUTTONS"]
        let button = Self.button(label, action: .navigateBack, native: mode != "embedded")
        guard mode != nil else { return button }
        return .stack(.init(
            components: [], size: .init(width: .fill, height: .fixed(64)),
            badge: .init(style: .nested, alignment: .top, stack: .init(components: [button]))
        ))
    }

    /// `close_workflow` is decode-only, so preserve its actual backend representation.
    private static func closeWorkflow(native: Bool = true) throws -> PaywallComponent {
        let encoded = try JSONEncoder().encode(Self.button("Designed Close", action: .navigateBack, native: native))
        guard var object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        object["action"] = ["type": "close_workflow", "use_native_if_possible": native]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PaywallComponent.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
