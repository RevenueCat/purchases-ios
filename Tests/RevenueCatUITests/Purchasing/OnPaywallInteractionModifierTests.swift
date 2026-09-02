//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OnPaywallInteractionModifierTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class OnPaywallInteractionModifierTests: TestCase {

    func testIfSetNilKeepsAncestorHandler() {
        let received: Atomic<[String]> = .init([])

        let view = ProbeView()
            .onPaywallInteraction(ifSet: nil)
            .onPaywallInteraction { event in
                received.modify { $0.append(event.rawProperties["origin"] as? String ?? "") }
            }

        let window = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(received.value) == ["probe"]
    }

    func testIfSetHandlerReplacesAncestorHandler() {
        let ancestor: Atomic<[String]> = .init([])
        let helper: Atomic<[String]> = .init([])

        let view = ProbeView()
            .onPaywallInteraction(ifSet: { event in
                helper.modify { $0.append(event.rawProperties["origin"] as? String ?? "") }
            })
            .onPaywallInteraction { event in
                ancestor.modify { $0.append(event.rawProperties["origin"] as? String ?? "") }
            }

        let window = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(helper.value) == ["probe"]
        expect(ancestor.value).to(beEmpty())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ProbeView: View {

    @Environment(\.onPaywallInteraction) private var onPaywallInteraction

    var body: some View {
        Color.clear
            .onAppear {
                self.onPaywallInteraction?(PaywallInteractionEvent(rawProperties: ["origin": "probe"]))
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OnPaywallInteractionModifierTests {

    static func host<Content: View>(_ view: Content) -> UIWindow {
        let controller = UIHostingController(rootView: view.frame(width: 100, height: 100))
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

}

#endif
