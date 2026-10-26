//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@_spi(Internal) public extension PaywallComponent {

    // swiftlint:disable cyclomatic_complexity
    /// Direct child stacks, in traversal order. Callers decide whether to recurse into each stack.
    /// Sheet destinations are separate presentations; asset collection includes them, native navigation does not.
    /// Stack badges and their conditional overrides are handled by the caller when visiting the stack.
    func childStacks(includeSheetDestinations: Bool) -> [StackComponent] {
        switch self {
        case .stack(let stack): return [stack]
        case .button(let button):
            if includeSheetDestinations,
               case let .navigateTo(.sheet(sheet)) = button.action, let sheet {
                return [button.stack, sheet.stack]
            }
            return [button.stack]
        case .package(let package): return [package.stack]
        case .purchaseButton(let button): return [button.stack]
        case .stickyFooter(let footer): return [footer.stack]
        case .tabs(let tabs): return [tabs.control.stack] + tabs.tabs.map { $0.stack }
        case .tabControlButton(let button): return [button.stack]
        case .carousel(let carousel): return carousel.pages
        case .countdown(let countdown):
            return [countdown.countdownStack, countdown.endStack, countdown.fallback].compactMap { $0 }
        case .text, .image, .icon, .timeline, .tabControl, .tabControlToggle, .video, .webView, .fallbackHeader:
            return []
        }
    }
    // swiftlint:enable cyclomatic_complexity

}
