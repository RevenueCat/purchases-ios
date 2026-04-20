@_spi(Internal) import RevenueCat

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
        Purchases.configure(withAPIKey: "")

        assert(Purchases.installationMethod == "xcframework",
               "Expected 'xcframework' but got '\(Purchases.installationMethod)'")
    }
}
