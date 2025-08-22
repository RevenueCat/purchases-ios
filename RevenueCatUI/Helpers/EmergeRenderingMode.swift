import Foundation
import SwiftUI

#if DEBUG
// Extracted from Emerge SnapshotPreferences since importing that library
// requires iOS 15 as deployment target
enum EmergeRenderingMode: Int {
    /// Renders using `CALayer.render(in:)`.
    case coreAnimation

    /// Renders using `UIView.drawHierarchy(in:afterScreenUpdates:true)`.
    @available(macOS, unavailable)
    case uiView

    /// Renders using `NSView.bitmapImageRepForCachingDisplay`.
    @available(iOS, unavailable)
    case nsView

    /// Renders the entire window instead of the previewed view.
    /// This uses `UIWindow.drawHierarchy(in: window.bounds, afterScreenUpdates: true)` on iOS
    /// This uses `CGWindowListCreateImage` on macOS.
    case window
}

// Classes in this file get compiled to an app that use any of the custom preview preferences.
// The inserted test runner code finds these classes through ObjC runtime functions (NSClassFromString)
// and Swift reflection (Mirror).
@objc(EmergeModifierState)
class EmergeModifierState: NSObject {

    @objc
    static let shared = EmergeModifierState()

    func reset() {
        renderingMode = nil
    }

    var renderingMode: EmergeRenderingMode.RawValue?
}

@objc(EmergeModifierFinder)
class EmergeModifierFinder: NSObject {
    let finder: (any View) -> (any View) = { view in
        EmergeModifierState.shared.reset()
        return view
            .onPreferenceChange(RenderingModePreferenceKey.self, perform: { value in
                EmergeModifierState.shared.renderingMode = value
            })
    }
}

struct RenderingModePreferenceKey: PreferenceKey {
    static func reduce(value: inout Int?, nextValue: () -> Int?) {
        value = nextValue()
    }

    static var defaultValue: EmergeRenderingMode.RawValue?
}

extension View {
    /// Sets the emerge rendering mode for the view.
    ///
    /// Use this method to control how the view is rendered for snapshots. You can indicate whether
    /// to use `.coreAnimation` which will use the CALayer from Quartz or `.uiView` which will use
    /// UIKit's `drawViewHierarchyInRect` under the hood.
    ///
    /// - Note: This method is only available on iOS and macOS. It is unavailable on watchOS, visionOS, and tvOS.
    ///
    /// - Parameter renderingMode: An `EmergeRenderingMode` value that specifies the
    ///  desired rendering mode for snapshots. If `nil`, the default rendering
    ///  mode will be selected based off of the view's height.
    ///
    /// - Returns: A view with the specified rendering mode preference applied.
    ///
    /// # Example
    /// ```swift
    /// struct ContentView: View {
    ///   var body: some View {
    ///     Text("Emerge Effect")
    ///       .emergeRenderingMode(.coreAnimation)
    ///   }
    /// }
    /// ```
    ///
    /// - SeeAlso: `EmergeRenderingMode`
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    @available(tvOS, unavailable)
    func emergeRenderingMode(_ renderingMode: EmergeRenderingMode?) -> some View {
        preference(key: RenderingModePreferenceKey.self, value: renderingMode?.rawValue)
    }
}
#endif
