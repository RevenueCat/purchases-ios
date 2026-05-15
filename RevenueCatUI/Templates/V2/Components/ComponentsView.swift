//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentsView.swift
//
//  Created by Josh Holtz on 11/17/24.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentsView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @Environment(\.overlaidHeaderHeight)
    private var overlaidHeaderHeight

    let componentViewModels: [PaywallComponentViewModel]
    /// When true, applies safe area top padding to all children except the first.
    /// Used for ZStacks where the first child is a hero image that bleeds into the safe area.
    private let pushNonFirstChildrenBelowSafeArea: Bool
    private let onDismiss: () -> Void
    private let defaultPackage: Package?
    /// When true, text components suppress their accessibilityIdentifier and are hidden from
    /// the accessibility tree. This prevents button label content from being exposed as separate
    /// accessible elements, which would prevent the button's own label from being shown.
    private let isInsideButtonLabel: Bool

    init(
        componentViewModels: [PaywallComponentViewModel],
        pushNonFirstChildrenBelowSafeArea: Bool = false,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package? = nil,
        isInsideButtonLabel: Bool = false
    ) {
        self.componentViewModels = componentViewModels
        self.pushNonFirstChildrenBelowSafeArea = pushNonFirstChildrenBelowSafeArea
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
        self.isInsideButtonLabel = isInsideButtonLabel
    }

    var body: some View {
        ForEach(Array(componentViewModels.enumerated()), id: \.offset) { index, item in
            view(for: item)
                .padding(
                    .top,
                    index > 0 && pushNonFirstChildrenBelowSafeArea
                        ? max(safeAreaInsets.top, overlaidHeaderHeight)
                        : 0
                )
        }
    }

    @ViewBuilder
    // swiftlint:disable:next cyclomatic_complexity
    private func view(for item: PaywallComponentViewModel) -> some View {
        switch item {
        case .root(let viewModel):
            RootView(viewModel: viewModel, onDismiss: onDismiss, defaultPackage: defaultPackage)
        case .text(let viewModel):
            TextComponentView(viewModel: viewModel)
                // The text always gets its identifier + extractor metadata so
                // the cross-platform layout extractor can find it. In
                // production, when this text sits inside a button label, we
                // additionally hide it from VoiceOver so the button reads as a
                // single unit. The extractor needs to see every text though,
                // so the hide flips off in extractor mode.
                .accessibilityIdentifier(viewModel.componentId ?? "text")
                .extractorAccessibilityContainer()
                .extractorMetadata(type: "text", name: viewModel.componentName)
                .accessibilityHidden(isInsideButtonLabel && !PaywallDebugMode.isLayoutExtractorActive)
        case .image(let viewModel):
            ImageComponentView(viewModel: viewModel)
                .accessibilityLabel(viewModel.componentName ?? "image")
                .accessibilityIdentifier(viewModel.componentId ?? "image")
                .extractorAccessibilityContainer()
                .extractorMetadata(type: "image", name: viewModel.componentName)
        case .icon(let viewModel):
            IconComponentView(viewModel: viewModel)
                .accessibilityLabel(viewModel.componentName)
                .accessibilityIdentifier(viewModel.componentId ?? viewModel.componentName)
                .extractorAccessibilityContainer()
                .extractorMetadata(type: "icon", name: viewModel.componentName)
        case .stack(let viewModel):
            StackComponentView(
                viewModel: viewModel,
                onDismiss: onDismiss,
                accessibilityLabel: isInsideButtonLabel
                    ? nil
                    : viewModel.component.name ?? viewModel.component.dimension.typeName,
                accessibilityIdentifier: isInsideButtonLabel
                    ? nil
                    : viewModel.component.id ?? "stack",
                isInsideButtonLabel: isInsideButtonLabel
            )
            .applyIf(!isInsideButtonLabel) { view in
                view.extractorMetadata(type: "stack", name: viewModel.component.name)
            }
        case .button(let viewModel):
            ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityIdentifier(viewModel.component.id ?? viewModel.id ?? "button")
                .extractorAccessibilityContainer()
                .extractorMetadata(type: "button", name: viewModel.component.name)
        case .package(let viewModel):
            PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.componentName ?? "package")
                .accessibilityIdentifier(viewModel.componentId ?? "package")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "package", name: viewModel.componentName)
        case .purchaseButton(let viewModel):
            PurchaseButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .extractorMetadata(type: "purchase_button", name: viewModel.componentName)
        case .stickyFooter(let viewModel):
            StickyFooterComponentView(viewModel: viewModel)
                .accessibilityLabel("sticky_footer")
                .accessibilityIdentifier(viewModel.component.id ?? "sticky_footer")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "sticky_footer", name: viewModel.component.name)
        case .timeline(let viewModel):
            TimelineComponentView(viewModel: viewModel)
                .accessibilityLabel("timeline")
                .accessibilityIdentifier(viewModel.componentId ?? "timeline")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "timeline", name: viewModel.componentName)
        case .tabs(let viewModel):
            TabsComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.name ?? "tabs")
                .accessibilityIdentifier(viewModel.componentId ?? "tabs")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "tabs", name: viewModel.name)
        case .tabControl(let viewModel):
            TabControlComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel("tab_control")
                .accessibilityIdentifier(viewModel.component.id ?? "tab_control")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "tab_control", name: viewModel.component.name)
        case .tabControlButton(let viewModel):
            TabControlButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "tab_control_button")
                .accessibilityIdentifier(viewModel.component.id ?? viewModel.component.tabId)
                .extractorAccessibilityContainer()
                .extractorMetadata(type: "tab_control_button", name: viewModel.component.name)
        case .tabControlToggle(let viewModel):
            TabControlToggleComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "tab_control_toggle")
                .accessibilityIdentifier(viewModel.component.id ?? "tab_control_toggle")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "tab_control_toggle", name: viewModel.component.name)
        case .carousel(let viewModel):
            CarouselComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.componentName ?? "carousel")
                .accessibilityIdentifier(viewModel.componentId ?? "carousel")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "carousel", name: viewModel.componentName)
        case .video(let viewModel):
            VideoComponentView(viewModel: viewModel)
                .accessibilityLabel(viewModel.componentName ?? "video")
                .accessibilityIdentifier(viewModel.componentId ?? "video")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "video", name: viewModel.componentName)
        case .countdown(let viewModel):
            CountdownComponentView(viewModel: viewModel, onDismiss: onDismiss)
                .accessibilityLabel(viewModel.component.name ?? "countdown")
                .accessibilityIdentifier(viewModel.component.id ?? "countdown")
                .accessibilityElement(children: .contain)
                .extractorMetadata(type: "countdown", name: viewModel.component.name)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension View {
    /// Marks this view as a distinct accessibility container — but only when
    /// the cross-platform layout extractor is active (see `PaywallDebugMode`).
    /// In production, the default SwiftUI behavior applies so VoiceOver can
    /// merge component content into the most useful navigation units.
    @ViewBuilder
    func extractorAccessibilityContainer() -> some View {
        if PaywallDebugMode.isLayoutExtractorActive {
            self.accessibilityElement(children: .contain)
        } else {
            self
        }
    }

    /// In extractor mode, attaches the dashboard `type` (and optional `name`)
    /// to the view as `accessibilityValue`, JSON-encoded with short keys to
    /// minimize the XCUITest payload:
    ///
    /// ```
    /// {"t":"button","n":"Subscribe"}
    /// ```
    ///
    /// The cross-platform layout extractor reads this off each XCUITest
    /// element snapshot to recover the dashboard semantic info (type,
    /// human-readable name) without round-tripping through the offerings
    /// JSON. In production the modifier is a no-op so VoiceOver continues
    /// to read SwiftUI's default `accessibilityValue` (e.g. the content of
    /// a `Text` view, the value of a `Toggle`, etc.).
    @ViewBuilder
    func extractorMetadata(type: String, name: String? = nil) -> some View {
        if PaywallDebugMode.isLayoutExtractorActive {
            self.accessibilityValue(serializeExtractorMetadata(type: type, name: name))
        } else {
            self
        }
    }
}

/// Encodes a `(type, name)` pair into the JSON payload that
/// `extractorMetadata` writes to `accessibilityValue`. Kept top-level so the
/// formatting is testable in isolation if we ever need to.
private func serializeExtractorMetadata(type: String, name: String?) -> String {
    var dict: [String: String] = ["t": type]
    if let name = name, !name.isEmpty {
        dict["n"] = name
    }
    guard let data = try? JSONSerialization.data(withJSONObject: dict),
          let str = String(data: data, encoding: .utf8) else {
        return ""
    }
    return str
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Dimension {
    var typeName: String {
        switch self {
        case .vertical: return "VStack"
        case .horizontal: return "HStack"
        case .zlayer: return "ZStack"
        }
    }
}

#endif
