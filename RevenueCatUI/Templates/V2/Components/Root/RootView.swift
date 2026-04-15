//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootView.swift
//
//  Created by Jay Shortway on 24/10/2024.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @EnvironmentObject
    private var packageContext: PackageContext

    private let viewModel: RootViewModel
    private let onDismiss: () -> Void
    private let defaultPackage: Package?

    @State private var sheetViewModel: SheetViewModel?
    @State private var overlaidHeaderHeight: CGFloat = 0

    internal init(
        viewModel: RootViewModel,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package?
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let headerViewModel = viewModel.headerViewModel,
               !viewModel.shouldOverlayHeader {
                HeaderComponentView(
                    viewModel: headerViewModel,
                    onDismiss: onDismiss
                )
                .fixedSize(horizontal: false, vertical: true)
            }

            ZStack(alignment: .top) {
                StackComponentView(
                    viewModel: viewModel.stackViewModel,
                    isScrollableByDefault: true,
                    onDismiss: onDismiss
                )
                .environment(\.overlaidHeaderHeight, overlaidHeaderHeight)

                if let headerViewModel = viewModel.headerViewModel,
                   viewModel.shouldOverlayHeader {
                    HeaderComponentView(
                        viewModel: headerViewModel,
                        onDismiss: onDismiss
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay(GeometryReader { proxy in
                        Color.clear.preference(
                            key: OverlaidHeaderHeightKey.self,
                            value: proxy.size.height
                        )
                    })
                }
            }
            .onPreferenceChange(OverlaidHeaderHeightKey.self) { height in
                overlaidHeaderHeight = height
            }

            if let stickyFooterViewModel = viewModel.stickyFooterViewModel {
                StackComponentView(
                    viewModel: stickyFooterViewModel.stackViewModel,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: safeAreaInsets.bottom,
                        trailing: 0
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .environment(\.openSheet, { sheet in
            self.sheetViewModel = sheet
        })
        .bottomSheet(sheet: $sheetViewModel, safeAreaInsets: self.safeAreaInsets)
        .onChangeOf(sheetViewModel) { newValue in
            if newValue == nil {
                // Reset package selection to default when sheet is dismissed to prevent
                // purchasing a hidden package that was selected in the sheet
                packageContext.package = defaultPackage
            }
        }
    }

}

/// PreferenceKey that propagates the measured height of the overlaid header.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OverlaidHeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Environment key for the overlaid header height so child views can adjust their layout.
private struct OverlaidHeaderHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var overlaidHeaderHeight: CGFloat {
        get { self[OverlaidHeaderHeightEnvironmentKey.self] }
        set { self[OverlaidHeaderHeightEnvironmentKey.self] = newValue }
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum RootViewPreviewData {

    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    static let heroImageURL = Self.makeLocalPreviewImageURL(
        filename: "root-view-preview-hero.png",
        base64: [
            "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGNgYPjP",
            "wMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
        ].joined()
    )

    static let offering = Offering(
        identifier: "preview",
        serverDescription: "",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    static let localizationProvider: LocalizationProvider = .init(
        locale: .current,
        localizedStrings: [
            "paywall_title": .string("Unlock your smartest study routine"),
            "paywall_subtitle": .string("The first root image should extend through the top safe area."),
            "header_title": .string("This text header should start below the safe area")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
    static let rootHeroPreviewName = "RootView: first root image ignores top safe area"
    static let textHeaderPreviewName = "RootView: text header respects top safe area"
    static let rootHeroPreviewTitle = "Root image fills the highlighted top guide"
    static let rootHeroPreviewSubtitle =
        "The tinted top band marks the safe area. The first root image should fill it."
    static let textHeaderPreviewTitle = "Text header clears the highlighted top guide"
    static let textHeaderPreviewSubtitle =
        "The tinted top band marks the safe area. A non-image header should begin below it."

    static func makeLocalPreviewImageURL(
        filename: String,
        base64: String
    ) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: url.path) {
            guard let data = Data(base64Encoded: base64) else {
                fatalError("Invalid base64 preview image for RootView preview")
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                fatalError("Failed to write RootView preview image: \(error)")
            }
        }

        return url
    }

    static func contentStack(
        topMargin: CGFloat = 0
    ) -> PaywallComponent.StackComponent {
        .init(
        components: [
            .stack(.init(
                components: [
                    .text(.init(
                        text: "paywall_title",
                        fontWeight: .black,
                        color: .init(light: .hex("#151515")),
                        padding: .zero,
                        margin: .zero,
                        fontSize: 32,
                        horizontalAlignment: .center
                    )),
                    .text(.init(
                        text: "paywall_subtitle",
                        color: .init(light: .hex("#5C5C5C")),
                        padding: .zero,
                        margin: .zero,
                        fontSize: 16,
                        horizontalAlignment: .center
                    ))
                ],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fit),
                spacing: 12,
                backgroundColor: .init(light: .hex("#FFFFFF")),
                padding: .init(top: 28, bottom: 28, leading: 24, trailing: 24),
                margin: .init(top: topMargin, bottom: 0, leading: 0, trailing: 0)
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 0,
        backgroundColor: .init(light: .hex("#FFFFFF"))
    )
    }

    static let heroRootStack = PaywallComponent.StackComponent(
        components: [
            .image(
                .init(
                    source: .init(
                        light: .init(
                            width: 750,
                            height: 530,
                            original: heroImageURL,
                            heic: heroImageURL,
                            heicLowRes: heroImageURL
                        )
                    ),
                    size: .init(width: .fill, height: .fixed(300)),
                    fitMode: .fill
                )
            ),
            .stack(Self.contentStack())
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 0,
        backgroundColor: .init(light: .hex("#FFFFFF"))
    )

    static let textHeaderStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "header_title",
                fontWeight: .bold,
                color: .init(light: .hex("#FFFFFF")),
                backgroundColor: .init(light: .hex("#2D5BFF")),
                padding: .init(top: 20, bottom: 20, leading: 24, trailing: 24),
                margin: .zero,
                fontSize: 18,
                horizontalAlignment: .center
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 0
    )

    static let headerBodyStack = Self.contentStack()

    static func rootViewModel(
        stack: PaywallComponent.StackComponent,
        headerStack: PaywallComponent.StackComponent
    ) -> RootViewModel {
        self.rootViewModel(stack: stack, headerStack: .some(headerStack))
    }

    static func rootViewModel(
        stack: PaywallComponent.StackComponent,
        headerStack: PaywallComponent.StackComponent?
    ) -> RootViewModel {
        var factory = ViewModelFactory()

        do {
            return try factory.toRootViewModel(
                componentsConfig: .init(
                    stack: stack,
                    header: headerStack.map { .init(stack: $0) },
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                ),
                offering: self.offering,
                localizationProvider: self.localizationProvider,
                uiConfigProvider: self.uiConfigProvider,
                colorScheme: .light
            )
        } catch {
            fatalError("Invalid RootView preview configuration: \(error)")
        }
    }

    static func preview(
        stack: PaywallComponent.StackComponent,
        headerStack: PaywallComponent.StackComponent,
        title: String,
        subtitle: String,
        name: String
    ) -> some View {
        self.preview(
            stack: stack,
            headerStack: .some(headerStack),
            title: title,
            subtitle: subtitle,
            name: name
        )
    }

    static func preview(
        stack: PaywallComponent.StackComponent,
        headerStack: PaywallComponent.StackComponent?,
        title: String,
        subtitle: String,
        name: String
    ) -> some View {
        SafeAreaPreviewShell(
            title: title,
            subtitle: subtitle,
            previewDisplayName: name,
            safeAreaInsets: self.safeAreaInsets
        ) {
            RootView(
                viewModel: self.rootViewModel(stack: stack, headerStack: headerStack),
                onDismiss: {},
                defaultPackage: nil
            )
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            RootViewPreviewData.preview(
                stack: RootViewPreviewData.heroRootStack,
                headerStack: nil,
                title: RootViewPreviewData.rootHeroPreviewTitle,
                subtitle: RootViewPreviewData.rootHeroPreviewSubtitle,
                name: RootViewPreviewData.rootHeroPreviewName
            )

            RootViewPreviewData.preview(
                stack: RootViewPreviewData.headerBodyStack,
                headerStack: RootViewPreviewData.textHeaderStack,
                title: RootViewPreviewData.textHeaderPreviewTitle,
                subtitle: RootViewPreviewData.textHeaderPreviewSubtitle,
                name: RootViewPreviewData.textHeaderPreviewName
            )
        }
    }

}

#endif

#endif
