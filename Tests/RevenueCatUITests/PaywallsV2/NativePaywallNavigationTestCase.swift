//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
class NativePaywallNavigationTestCase: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
    }

    func toolbarButtons(in view: UIView) -> [UIButton] {
        NativePaywallTestSupport.controls(of: UIButton.self, in: view)
    }

    func waitForPresentation() async {
        let settled = expectation(description: "Presentation settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
    }

    func navigationController(in controller: UIViewController) -> UINavigationController? {
        if let navigation = controller as? UINavigationController { return navigation }
        return controller.children.lazy.compactMap { self.navigationController(in: $0) }.first
    }

    func navigationCount(in controller: UIViewController?) -> Int {
        guard let controller else { return 0 }
        return (controller is UINavigationController ? 1 : 0)
            + controller.children.reduce(0) { $0 + self.navigationCount(in: $1) }
    }

    func host(_ controller: UIViewController) -> UIWindow {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

    func close(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
        window.windowScene?.windows.first(where: { !$0.isHidden })?.makeKeyAndVisible()
    }

}

// Inspect controls across the hosted navigation view: floating toolbars can render
// outside UINavigationBar, and SwiftUI does not store them in controller.navigationItem.
@available(iOS 15.0, *)
@MainActor
enum NativePaywallTestSupport {
    static func controls<T: UIControl>(of type: T.Type, in view: UIView) -> [T] {
        if let control = view as? T { return [control] }
        return view.subviews.flatMap { self.controls(of: type, in: $0) }
    }
}

#endif
