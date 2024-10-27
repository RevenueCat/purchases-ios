//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OrientationObserver.swift
//
//  Created by Josh Holtz on 10/27/24.

import Combine
import SwiftUI

#if PAYWALL_COMPONENTS

class ComponentConditionObserver: ObservableObject {

    enum ComponentConditionsType {
        case `default`, mobileLandscape, tablet, tabletLandscape, desktop
    }

    private enum Device {
        case phone, tablet, desktop
    }

    @Published var conditionType: ComponentConditionsType = .default

    private let deviceType: Device
    private var cancellable: AnyCancellable?

    init() {
        #if os(iOS)
        // Set device type based on user interface idiom for iOS
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            deviceType = .phone
        case .pad:
            deviceType = .tablet
        default:
            deviceType = .phone
        }
        #else
        // Set device type for macOS
        deviceType = .desktop
        #endif

        // Set up the publisher to respond to orientation changes
        cancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Update the orientation when the notification is triggered
                let isLandscape = UIDevice.current.orientation.isLandscape

                switch self.deviceType {
                case .phone:
                    self.conditionType = isLandscape ? .mobileLandscape : .default
                case .tablet:
                    self.conditionType = isLandscape ? .tabletLandscape : .tablet
                case .desktop:
                    self.conditionType = .default
                }
            }
    }

    deinit {
        cancellable?.cancel()
    }

}

struct ComponentConditionObserverKey: EnvironmentKey {
    static let defaultValue = ComponentConditionObserver.ComponentConditionsType.default
}

extension EnvironmentValues {

    var componentConditionType: ComponentConditionObserver.ComponentConditionsType {
        get { self[ComponentConditionObserverKey.self] }
        set { self[ComponentConditionObserverKey.self] = newValue }
    }

}

#endif
