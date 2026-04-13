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
    @State private var overlayHeaderHeight: CGFloat = 0

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
        let heroOverlayTopInset = self.viewModel.shouldOverlayHeader && self.viewModel.rootStartsWithHeroImage
            ? max(self.overlayHeaderHeight, self.safeAreaInsets.top)
            : nil

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
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: viewModel.stickyFooterViewModel == nil ? safeAreaInsets.bottom : 0,
                        trailing: 0
                    ),
                    safeAreaTopInsetOverride: heroOverlayTopInset
                )

                if let headerViewModel = viewModel.headerViewModel,
                   viewModel.shouldOverlayHeader {
                    HeaderComponentView(
                        viewModel: headerViewModel,
                        onDismiss: onDismiss
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .onSizeChange { self.overlayHeaderHeight = $0.height }
                }
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

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum RootViewPreviewData {

    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    static let heroImageURL = makeLocalPreviewImageURL(
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
    static let rootHeroPreviewTitle = "Root image fills the top safe area"
    static let rootHeroPreviewSubtitle = "Verifies that the first root image extends through the top inset."
    static let textHeaderPreviewTitle = "Text header starts below the top inset"
    static let textHeaderPreviewSubtitle = "Verifies that a non-image header behaves as the safe-area extension."

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
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ZStack(alignment: .top) {
                Color.white

                RootView(
                    viewModel: self.rootViewModel(stack: stack, headerStack: headerStack),
                    onDismiss: {},
                    defaultPackage: nil
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: 393, height: 852)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .frame(width: 425, height: 936)
        .background(Color.white)
        .previewRequiredPaywallsV2Properties()
        .environment(\.safeAreaInsets, self.safeAreaInsets)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: 425, height: 936))
        .previewDisplayName(name)
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
