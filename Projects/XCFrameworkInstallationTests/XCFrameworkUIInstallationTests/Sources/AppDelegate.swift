@_spi(Internal) import RevenueCat
import RevenueCatUI

#if os(iOS)
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

        #if os(iOS) || targetEnvironment(macCatalyst)
        if #available(iOS 15.0, macOS 12.0, *) {
            _ = PaywallViewController()
        }
        #endif

        assert(Purchases.installationMethod == "xcframework",
               "Expected 'xcframework' but got '\(Purchases.installationMethod)'")
    }
}
