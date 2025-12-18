//
//  CountdownComponentViewModel.swift
//  RevenueCat
//
//  Created by Josh Holtz on 11/12/25.
//

import Combine
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

// MARK: - CountdownState

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CountdownState: ObservableObject {

    @Published private(set) var hasEnded = false
    @Published private(set) var countdownTime: CountdownTime = .zero

    let targetDate: Date?
    let countFrom: PaywallComponent.CountdownComponent.CountFrom
    private var timer: Timer.TimerPublisher?
    private var cancellable: AnyCancellable?

    // MARK: - Init

    /// Provide a Date directly.
    init(targetDate: Date?, countFrom: PaywallComponent.CountdownComponent.CountFrom) {
        self.targetDate = targetDate
        self.countFrom = countFrom
        updateCountdown()
    }

    deinit {
        // Not calling stop because of async needed
        timer?.connect().cancel()
        timer = nil
        cancellable = nil
    }

    // MARK: - Public API

    func start() {
        guard self.timer == nil, self.targetDate != nil, !self.hasEnded else { return }

        let timer = Timer.publish(every: 1.0, on: RunLoop.main, in: .default)
        self.timer = timer
        self.cancellable = timer.autoconnect()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateCountdown()
        }
    }

    func stop() {
        timer?.connect().cancel()
        timer = nil
        cancellable = nil
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

        countdownTime = CountdownTime(interval: delta, countFrom: self.countFrom)
    }

    private func finish() {
        hasEnded = true
        countdownTime = .zero
        stop()
    }

}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownTime {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    let countFrom: PaywallComponent.CountdownComponent.CountFrom

    static let zero = CountdownTime(days: 0, hours: 0, minutes: 0, seconds: 0, countFrom: .days)

    init(days: Int, hours: Int, minutes: Int, seconds: Int, countFrom: PaywallComponent.CountdownComponent.CountFrom) {
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.countFrom = countFrom
    }

    init(interval: TimeInterval, countFrom: PaywallComponent.CountdownComponent.CountFrom) {
        let totalSeconds = max(0, Int(interval))

        switch countFrom {
        case .days:
            let days = totalSeconds / 86_400
            let hours = (totalSeconds % 86_400) / 3_600
            let minutes = (totalSeconds % 3_600) / 60
            let seconds = totalSeconds % 60

            self.init(days: days, hours: hours, minutes: minutes, seconds: seconds, countFrom: countFrom)

        case .hours:
            let hours = totalSeconds / 3_600
            let minutes = (totalSeconds % 3_600) / 60
            let seconds = totalSeconds % 60

            self.init(days: 0, hours: hours, minutes: minutes, seconds: seconds, countFrom: countFrom)

        case .minutes:
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60

            self.init(days: 0, hours: 0, minutes: minutes, seconds: seconds, countFrom: countFrom)
        }
    }

}
