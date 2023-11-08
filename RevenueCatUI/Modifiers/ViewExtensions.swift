////
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewExtensions.swift
//
//  Created by Nacho Soto on 7/13/23.

import Foundation
import SwiftUI

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    @ViewBuilder
    func hidden(if condition: Bool) -> some View {
        if condition {
            self.hidden()
        } else {
            self
        }
    }

}

// MARK: - Scrolling

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    @ViewBuilder
    func scrollable(
        _ axes: Axis.Set = .vertical,
        if condition: Bool
    ) -> some View {
        if condition {
            ScrollView(axes) {
                self
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollBounceBehaviorBasedOnSize() -> some View {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder
    func scrollableIfNecessary(_ axis: Axis = .vertical, enabled: Bool = true) -> some View {
        if enabled {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                ViewThatFits(in: axis.scrollViewAxis) {
                    self

                    ScrollView(axis.scrollViewAxis) {
                        self
                    }
                }
            } else {
                self.modifier(ScrollableIfNecessaryModifier(axis: axis))
            }
        } else {
            self
        }
    }
}

// MARK: - Padding

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func defaultHorizontalPadding() -> some View {
        return self.modifier(DefaultHorizontalPaddingModifier())
    }

    func defaultVerticalPadding() -> some View {
        return self.modifier(DefaultVerticalPaddingModifier())
    }

    func defaultPadding() -> some View {
        return self
            .defaultHorizontalPadding()
            .defaultVerticalPadding()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultHorizontalPaddingModifier: ViewModifier {

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Constants.defaultHorizontalPaddingLength(self.interfaceIdiom))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultVerticalPaddingModifier: ViewModifier {

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    func body(content: Content) -> some View {
        content
            .padding(.vertical, Constants.defaultVerticalPaddingLength(self.interfaceIdiom))
    }

}

// MARK: - scrollableIfNecessary

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ScrollableIfNecessaryModifier: ViewModifier {

    var axis: Axis

    @State
    private var overflowing: Bool = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            self.centeredContent(content)
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear
                            .onAppear {
                                switch self.axis {
                                case .horizontal:
                                    self.overflowing = contentGeometry.size.width > geometry.size.width
                                case .vertical:
                                    self.overflowing = contentGeometry.size.height > geometry.size.height
                                }
                            }
                    }
                )
        }
        .scrollable(self.axis.scrollViewAxis, if: self.overflowing)
    }

    @ViewBuilder
    private func centeredContent(_ content: Content) -> some View {
        switch self.axis {
        case .horizontal:
            HStack {
                Spacer()
                content
                Spacer()
            }
        case .vertical:
            VStack {
                Spacer()
                content
                Spacer()
            }
        }
    }

}

// MARK: - Size changes

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    /// Invokes the given closure whethever the view size changes.
    func onSizeChange(_ closure: @escaping (CGSize) -> Void) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ViewSizePreferenceKey.self,
                                    value: geometry.size)
                }
            )
            .onPreferenceChange(ViewSizePreferenceKey.self, perform: closure)
    }

    /// Invokes the given closure with the view width whenever it changes.
    @ViewBuilder
    func onWidthChange(
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewWidthPreferenceKey.self,
                            value: geometry.size.width
                        )
                }
            )
            .onPreferenceChange(ViewWidthPreferenceKey.self, perform: closure)
    }

    /// Invokes the given closure with the view height whenever it changes.
    @ViewBuilder
    func onHeightChange(
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                }
            )
            .onPreferenceChange(ViewHeightPreferenceKey.self, perform: closure)
    }

}

// MARK: - Rounded corners

#if canImport(UIKit)

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    @ViewBuilder
    func roundedCorner(
        _ radius: CGFloat,
        corners: UIRectCorner,
        edgesIgnoringSafeArea edges: Edge.Set = []
    ) -> some View {
        #if swift(>=5.9)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            self.mask(
                UnevenRoundedRectangle(radius: radius, corners: corners),
                edgesIgnoringSafeArea: edges
            )
        } else {
            self.mask(
                RoundedCorner(radius: radius, corners: corners),
                edgesIgnoringSafeArea: edges
            )
        }
        #else
        self.mask(
            RoundedCorner(radius: radius, corners: corners),
            edgesIgnoringSafeArea: edges
        )
        #endif
    }

    private func mask(_ shape: some Shape, edgesIgnoringSafeArea edges: Edge.Set) -> some View {
        self.mask(shape.edgesIgnoringSafeArea(edges))
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private struct RoundedCorner: Shape {

    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: self.corners,
                                cornerRadii: CGSize(width: self.radius, height: self.radius))
        return Path(path.cgPath)
    }

}

#endif

// MARK: - Preference Keys

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private protocol ViewDimensionPreferenceKey: PreferenceKey where Value == CGFloat {}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension ViewDimensionPreferenceKey {

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let newValue = max(value, nextValue())
        if newValue != value {
            value = newValue
        }
    }

}

/// `PreferenceKey` for keeping track of a view width.
private struct ViewWidthPreferenceKey: ViewDimensionPreferenceKey {

    static var defaultValue: Value = 10

}

/// `PreferenceKey` for keeping track of a view height.
private struct ViewHeightPreferenceKey: ViewDimensionPreferenceKey {

    static var defaultValue: Value = 10

}

/// `PreferenceKey` for keeping track of view size.
private struct ViewSizePreferenceKey: PreferenceKey {

    typealias Value = CGSize

    static var defaultValue: Value = .init(width: 10, height: 10)

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }

}

// MARK: -

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private extension Axis {

    var scrollViewAxis: Axis.Set {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }

}

// MARK: -

#if swift(>=5.9) && canImport(UIKit)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension UnevenRoundedRectangle {

    /// Creates a `UnevenRoundedRectangle` rounding `corners` with  `radius`.
    /// - Note: this does not take RTL into account.
    init(radius: CGFloat, corners: UIRectCorner) {
        self.init(
            topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
            bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
            bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
            topTrailingRadius: corners.contains(.topRight) ? radius : 0,
            style: .continuous
        )
    }
}
#endif
