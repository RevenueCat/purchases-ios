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

typealias PresentedCountdownPartial = PaywallComponent.PartialCountdownComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// Note: The component-level `overrides` are evaluated here only to gate the visibility of the whole
// countdown. Styling overrides are handled by the child stack view models (countdownStack, endStack,
// fallbackStack), which each support conditional configurability independently.
class CountdownComponentViewModel {

    let component: PaywallComponent.CountdownComponent
    let countdownStackViewModel: StackComponentViewModel
    let endStackViewModel: StackComponentViewModel?
    let fallbackStackViewModel: StackComponentViewModel?

    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedCountdownPartial>?

    init(
        component: PaywallComponent.CountdownComponent,
        uiConfigProvider: UIConfigProvider,
        countdownStackViewModel: StackComponentViewModel,
        endStackViewModel: StackComponentViewModel?,
        fallbackStackViewModel: StackComponentViewModel?,
        discardRules: Bool = false
    ) {
        self.component = component
        self.uiConfigProvider = uiConfigProvider
        self.countdownStackViewModel = countdownStackViewModel
        self.endStackViewModel = endStackViewModel
        self.fallbackStackViewModel = fallbackStackViewModel
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

    /// Resolves whether the countdown should be rendered for the current presentation context,
    /// applying any matching overrides on top of the base component value.
    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        stateValues: [String: PaywallComponent.ConditionValue] = [:],
        stateDefaults: [String: PaywallComponent.ConditionValue] = [:],
        windowSize: CGSize? = nil
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables,
            stateValues: stateValues,
            stateDefaults: stateDefaults,
            windowSize: windowSize
        )

        let partial = PresentedCountdownPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        return partial?.visible ?? self.component.visible ?? true
    }

}

extension PresentedCountdownPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialCountdownComponent?,
        with other: PaywallComponent.PartialCountdownComponent?
    ) -> Self {
        return .init(
            visible: other?.visible ?? base?.visible,
            style: other?.style ?? base?.style
        )
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
        updateCountdown()

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
