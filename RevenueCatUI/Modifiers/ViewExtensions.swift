//
//  ViewExtensions.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

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
    func scrollableIfNecessary(_ axis: Axis = .vertical) -> some View {
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

    /// Invokes the given closure with the dimension specified by `axis` changes whenever it changes.
    func onSizeChange(
        _ axis: Axis,
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewDimensionPreferenceKey.self,
                            value: axis == .horizontal
                                ? geometry.size.width
                                : geometry.size.height
                        )
                }
            )
            .onPreferenceChange(ViewDimensionPreferenceKey.self, perform: closure)
    }

}

// MARK: - Rounded corners

#if canImport(UIKit)

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    func roundedCorner(
        _ radius: CGFloat,
        corners: UIRectCorner,
        edgesIgnoringSafeArea edges: Edge.Set = []
    ) -> some View {
        self.mask(
            RoundedCorner(radius: radius, corners: corners)
                .edgesIgnoringSafeArea(edges)
        )
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

/// `PreferenceKey` for keeping track of a view dimension.
private struct ViewDimensionPreferenceKey: PreferenceKey {

    typealias Value = CGFloat

    static var defaultValue: Value = 10

    static func reduce(value: inout Value, nextValue: () -> Value) {
        let newValue = max(value, nextValue())
        if newValue != value {
            value = newValue
        }
    }

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
