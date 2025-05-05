//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BottomSheetView.swift
//
//  Created by Will Taylor on 5/5/25.

import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

/// A view that presents content in a sheet-like interface with customizable height and background.
///
/// This view is designed to be used as a bottom sheet that slides up from the bottom of the screen.
/// It provides a scrollable container for its content with a fixed height and customizable background color.
///
/// - Note: This view is typically used in conjunction with ``BottomSheetOverlayModifier`` to present
///   content in a sheet-like interface.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetView<Content: View>: View {

    /// The background color of the sheet.
    let backgroundColor: Color

    /// The height of the sheet.
    let height: CGFloat

    /// The content to be displayed within the sheet.
    let content: Content

    /// Creates a new sheet view with the specified parameters.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background color of the sheet.
    ///   - height: The height of the sheet.
    ///   - content: A view builder closure that creates the content of the sheet.
    init(
        backgroundColor: Color,
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.height = height
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: height)
        .background(backgroundColor)
    }
}

/// Configuration options for presenting a sheet view.
///
/// Use this type to customize the appearance and behavior of a sheet view.
/// You can specify the background color, height percentage relative to the screen,
/// and whether tapping outside the sheet should dismiss it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetConfig: Sendable {

    /// The background color of the sheet.
    let backgroundColor: Color

    /// The height of the sheet as a percentage of the screen height.
    ///
    /// This value should be between 0 and 1, where 1 represents 100% of the screen height.
    let screenHeightPercentage: CGFloat

    /// A Boolean value that determines whether tapping outside the sheet dismisses it.
    let tapOutsideToDismiss: Bool

    /// Creates a new sheet configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background color of the sheet. Defaults to the system background color.
    ///   - screenHeightPercentage: The height of the sheet as a percentage of the screen height.
    ///     Defaults to 0.33333 (one-third of the screen height).
    ///   - tapOutsideToDismiss: A Boolean value that determines whether tapping outside the sheet
    ///     dismisses it. Defaults to `true`.
    init(
        backgroundColor: Color = Color(UIColor.systemBackground),
        screenHeightPercentage: CGFloat = 0.33333,
        tapOutsideToDismiss: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.screenHeightPercentage = screenHeightPercentage
        self.tapOutsideToDismiss = tapOutsideToDismiss
    }
}

/// A view modifier that presents content in a sheet-like interface.
///
/// This modifier handles the presentation and dismissal of a sheet view, including
/// the animation and tap-to-dismiss behavior.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetOverlayModifier<SheetContent: View>: ViewModifier {
    /// A binding to a Boolean value that determines whether the sheet is presented.
    let isPresented: Binding<Bool>

    /// The configuration for the sheet.
    let config: BottomSheetConfig

    /// A closure that creates the content of the sheet.
    let sheetContent: () -> SheetContent

    @State private var sheetHeight: CGFloat = 0

    func body(content: Content) -> some View {
        modifierBody(content: content)
            .ignoresSafeArea()    }

    @ViewBuilder
    private func modifierBody(
        content: Content
    ) -> some View {
        ZStack {
            content
            // Invisible tap area that covers the screen
            if isPresented.wrappedValue && config.tapOutsideToDismiss {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented.wrappedValue = false
                    }
            }

            // Sheet content
            VStack {
                Spacer()
                if isPresented.wrappedValue {
                    BottomSheetView(
                        backgroundColor: config.backgroundColor,
                        height: self.sheetHeight
                    ) {
                        sheetContent()
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            self.sheetHeight = proxy.size.height * config.screenHeightPercentage
                        }
                }
            )
            .animation(.spring(duration: 0.25), value: isPresented.wrappedValue)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    /// Presents a sheet view when a binding to a Boolean value is true.
    ///
    /// Use this modifier to present a sheet view that slides up from the bottom of the screen.
    /// The sheet can be dismissed by setting the binding to `false` or by tapping outside
    /// the sheet (if `tapOutsideToDismiss` is enabled in the configuration).
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the sheet.
    ///   - config: The configuration for the sheet. Defaults to a configuration with
    ///     system background color and one-third screen height.
    ///   - content: A closure that returns the content of the sheet.
    ///
    /// - Returns: A view that presents the sheet when `isPresented` is true.
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        config: BottomSheetConfig = BottomSheetConfig(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(BottomSheetOverlayModifier(
            isPresented: isPresented,
            config: config,
            sheetContent: content
        ))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview {
    struct Preview: View {
        @State private var isPresented = false

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)

                VStack {
                    Button("Show Sheet") {
                        isPresented.toggle()
                    }
                    .bottomSheet(
                        isPresented: $isPresented,
                        config: BottomSheetConfig(
                            backgroundColor: Color.blue,
                            screenHeightPercentage: 0.5,
                            tapOutsideToDismiss: false
                        )
                    ) {
                        VStack(spacing: 20) {
                            Text("Sheet Content")
                                .font(.title)
                            Text("This is a simple sheet preview")
                        }
                        .padding()
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    return Preview()
}
#endif
