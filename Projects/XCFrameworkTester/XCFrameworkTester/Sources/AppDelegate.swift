import RevenueCat
import RevenueCatUI

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = Tester()
        
        return true
    }
}

#elseif os(macOS)
import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = Tester()
    }
}

#elseif os(watchOS)
import WatchKit

@main
class AppDelegate: NSObject, WKApplicationDelegate {

    func applicationDidFinishLaunching() {
        _ = Tester()
    }
}
#endif

class Tester {
    init() {
        // Test that RevenueCat can be imported and configured
        // This verifies that the xcframework is linked correctly
        Purchases.configure(withAPIKey: "")
        
        // Tests that RevenueCatUI can be imported and the types are available
        // This verifies that the xcframework is linked correctly
        if #available(iOS 15.0, macOS 12.0, *) {
            _ = PaywallViewController()
        }
    }
}
