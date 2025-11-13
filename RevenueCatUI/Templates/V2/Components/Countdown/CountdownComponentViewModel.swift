//
//  CountdownComponentViewModel.swift
//  RevenueCat
//
//  Created by Josh Holtz on 11/12/25.
//


//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CountdownComponentViewModel.swift
//
//  Created by Josh Holtz on 1/14/25.
//

import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CountdownComponentViewModel {

    let component: PaywallComponent.CountdownComponent
    let countdownStackViewModel: StackComponentViewModel
    let endStackViewModel: StackComponentViewModel?
    let fallbackStackViewModel: StackComponentViewModel?

    init(
        component: PaywallComponent.CountdownComponent,
        countdownStackViewModel: StackComponentViewModel,
        endStackViewModel: StackComponentViewModel?,
        fallbackStackViewModel: StackComponentViewModel?
    ) {
        self.component = component
        self.countdownStackViewModel = countdownStackViewModel
        self.endStackViewModel = endStackViewModel
        self.fallbackStackViewModel = fallbackStackViewModel
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownTime {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    static let zero = CountdownTime(days: 0, hours: 0, minutes: 0, seconds: 0)

    init(days: Int, hours: Int, minutes: Int, seconds: Int) {
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    init(interval: TimeInterval) {
        let totalSeconds = max(0, Int(interval))

        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        self.init(days: days, hours: hours, minutes: minutes, seconds: seconds)
    }
}

// MARK: - CountdownState

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CountdownState: ObservableObject {

    @Published private(set) var hasEnded = false
    @Published private(set) var countdownTime: CountdownTime = .zero

    let targetDate: Date?
    private var timer: Timer?

    // MARK: - Init

    /// Provide a Date directly.
    init(targetDate: Date?) {
        self.targetDate = targetDate
        updateCountdown()
    }

    // MARK: - Public API

    func start() {
        guard self.timer == nil, self.targetDate != nil, !self.hasEnded else { return }

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Internal logic

    private func updateCountdown(now: Date = Date()) {
        guard let targetDate else {
            finish()
            return
        }

        let delta = targetDate.timeIntervalSince(now)

        guard delta > 0 else {
            finish()
            return
        }

        countdownTime = CountdownTime(interval: delta)
        hasEnded = false
    }

    private func finish() {
        hasEnded = true
        countdownTime = .zero
        stop()
    }

}

#endif
