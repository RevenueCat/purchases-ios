//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// SwiftUI can retain the player after its view leaves the window.
final class VideoPlaybackWindowObserver: UIView {

    private weak var autoplayHandler: VideoAutoplayHandler?

    var isPaywallPageActive: Bool {
        didSet { self.updatePlayback() }
    }

    init(autoplayHandler: VideoAutoplayHandler, isPaywallPageActive: Bool) {
        self.autoplayHandler = autoplayHandler
        self.isPaywallPageActive = isPaywallPageActive
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.updatePlayback()
    }

    func invalidate() {
        self.autoplayHandler = nil
    }

    private func updatePlayback() {
        self.autoplayHandler?.setPlaybackEnabled(self.window != nil && self.isPaywallPageActive)
    }

}
#endif
