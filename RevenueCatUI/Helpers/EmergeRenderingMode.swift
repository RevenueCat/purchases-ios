import Foundation
import SwiftUI

#if DEBUG
// Extracted from Emerge SnapshotPreferences since importing that library
// requires iOS 15 as deployment target

// swiftlint:disable missing_docs
public enum EmergeRenderingMode: Int {
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
    expansionPreference = nil
    renderingMode = nil
    precision = nil
    accessibilityEnabled = nil
  }

  var expansionPreference: Bool?
  var renderingMode: EmergeRenderingMode.RawValue?
  var precision: Float?
  var accessibilityEnabled: Bool?
  var appStoreSnapshot: Bool?
}

@objc(EmergeModifierFinder)
class EmergeModifierFinder: NSObject {
  let finder: (any View) -> (any View) = { view in
    EmergeModifierState.shared.reset()
    return view
      .onPreferenceChange(ExpansionPreferenceKey.self, perform: { value in
        EmergeModifierState.shared.expansionPreference = value
      })
      .onPreferenceChange(RenderingModePreferenceKey.self, perform: { value in
        EmergeModifierState.shared.renderingMode = value
      })
      .onPreferenceChange(PrecisionPreferenceKey.self, perform: { value in
        EmergeModifierState.shared.precision = value
      })
      .onPreferenceChange(AccessibilityPreferenceKey.self, perform: { value in
        EmergeModifierState.shared.accessibilityEnabled = value
      })
      .onPreferenceChange(AppStoreSnapshotPreferenceKey.self, perform: { value in
        EmergeModifierState.shared.appStoreSnapshot = value
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

struct ExpansionPreferenceKey: PreferenceKey {
  static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
    if value == nil {
      value = nextValue()
    }
  }

  static var defaultValue: Bool?
}

extension View {
    /// Applies an expansion effect to the view's snapshot.
    ///
    /// Use this method to control the emerge expansion effect on a view. When enabled,
    /// the view's first scrollview will be expanded to show all content in the snapshot.
    ///
    /// - Parameter enabled: A Boolean value that determines whether the emerge expansion
    ///   effect is applied. If `nil`, the effect will default to `true`.
    ///
    /// - Returns: A view with the expansion preference applied.
    ///
    /// # Example
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello, World!")
    ///             .emergeExpansion(false)
    ///     }
    /// }
    /// ```
    public func emergeExpansion(_ enabled: Bool?) -> some View {
        preference(key: ExpansionPreferenceKey.self, value: enabled)
    }
}

struct PrecisionPreferenceKey: PreferenceKey {
  static func reduce(value: inout Float?, nextValue: () -> Float?) {
    value = nextValue()
  }

  static var defaultValue: Float?
}

extension View {
    /// Sets the precision level for the snapshot on the view.
    ///
    /// Use this method to control the precision of the snapshot, which will be used for
    /// the comparison logic. With precision level 1.0, the images fully match. With precision
    /// level 0, the snapshot will never be flagged for having differences.
    ///
    /// - Parameter precision: A Float value representing the desired precision level for
    ///   emerge snapshot operations. If `nil`, the value will default to 1.0.
    ///
    /// - Returns: A view with the snapshot precision preference applied.
    ///
    /// # Example
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Image("sample")
    ///             .emergeSnapshotPrecision(0.8)
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The actual impact of the precision value may vary depending on the
    ///   specific implementation of the emerge snapshot feature.
    public func emergeSnapshotPrecision(_ precision: Float?) -> some View {
        preference(key: PrecisionPreferenceKey.self, value: precision)
    }
}

struct AccessibilityPreferenceKey: PreferenceKey {
  static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
    if value == nil {
      value = nextValue()
    }
  }

  static var defaultValue: Bool?
}

extension View {
    /// Applies accessibility support to the view's snapshot.
    ///
    /// Use this method to control whether the snapshot should render with accessibility elements
    /// highlighted as well as a corresponding legend for them.
    ///
    /// - Note: This method is only available on iOS. It is unavailable on macOS, watchOS, visionOS, and tvOS.
    ///
    /// - Parameter enabled: A Boolean value that determines whether the emerge accessibility
    ///   features are applied. If `nil`, the effect will default to `false`.
    ///
    /// - Returns: A view with the accessibility preference applied.
    ///
    /// # Example
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Accessible Content")
    ///             .emergeAccessibility(true)
    ///     }
    /// }
    /// ```
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    @available(tvOS, unavailable)
    public func emergeAccessibility(_ enabled: Bool?) -> some View {
        preference(key: AccessibilityPreferenceKey.self, value: enabled)
    }
}

struct AppStoreSnapshotPreferenceKey: PreferenceKey {
  static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
    if value == nil {
      value = nextValue()
    }
  }

  static var defaultValue: Bool?
}

extension View {
    /// Marks a snapshot for use with our App Store screenshot editing tool. This should ideally be used with a
    /// full-size preview matching one of our supported devices.
    ///
    /// - Note: This method is only available on iOS. It is unavailable on macOS, watchOS, visionOS, and tvOS.
    ///
    /// - Parameter enabled: A Boolean value that determines whether the snapshot is for an App Store screenshot.
    ///   If `nil`, the effect will default to `false`.
    ///
    /// - Returns: A view with the app store snapshot preference applied.
    ///
    /// # Example
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("My App Store listing!")
    ///             .emergeAppStoreSnapshot(true)
    ///     }
    /// }
    /// ```
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    @available(tvOS, unavailable)
    public func emergeAppStoreSnapshot(_ enabled: Bool?) -> some View {
        preference(key: AppStoreSnapshotPreferenceKey.self, value: enabled)
    }
}

#endif
