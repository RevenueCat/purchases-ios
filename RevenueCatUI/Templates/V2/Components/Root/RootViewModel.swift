//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootComponentViewModel.swift
//
//  Created by Jay Shortway on 24/10/2024.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class RootViewModel {

    let headerViewModel: HeaderComponentViewModel?
    let stackViewModel: StackComponentViewModel
    let stickyFooterViewModel: StickyFooterComponentViewModel?
    let firstItemIsFullWidthMedia: Bool
    let localizationProvider: LocalizationProvider
    var heroMediaNode: HeroMediaNode?
    var headerHeroMediaNode: HeroMediaNode?

    init(
        headerViewModel: HeaderComponentViewModel?,
        stackViewModel: StackComponentViewModel,
        stickyFooterViewModel: StickyFooterComponentViewModel?,
        firstItemIsFullWidthMedia: Bool,
        localizationProvider: LocalizationProvider
    ) {
        self.headerViewModel = headerViewModel
        self.stackViewModel = stackViewModel
        self.stickyFooterViewModel = stickyFooterViewModel
        self.firstItemIsFullWidthMedia = firstItemIsFullWidthMedia
        self.localizationProvider = localizationProvider
    }

    func heroMediaPresentation(context: HeroMediaContext) -> HeroMediaPresentation {
        let root = heroMediaNode?.firstVisible(context: context)
        let header = headerHeroMediaNode?.firstVisible(context: context)
        return HeroMediaPresentation(
            rootIsMedia: root.map { $0.isMedia } ?? firstItemIsFullWidthMedia,
            headerIgnoresSafeArea: header.map { $0 == .media(.image) }
                ?? headerViewModel?.firstItemIgnoresSafeArea ?? false
        )
    }

    var frameAlignment: Alignment {
        switch stackViewModel.component.dimension {
        case .vertical(let horizontalAlignment, let distribution):
            return Alignment(
                horizontal: horizontalAlignment.frameAlignment.horizontal,
                vertical: distribution.verticalFrameAlignment.vertical
            )
        case .horizontal(let verticalAlignment, let distribution):
            return Alignment(
                horizontal: distribution.horizontalFrameAlignment.horizontal,
                vertical: verticalAlignment.frameAlignment.vertical
            )
        case .zlayer(let alignment):
            return alignment.stackAlignment
        }
    }

    var shouldOverlayHeader: Bool {
        guard let headerViewModel else {
            return false
        }

        return headerViewModel.firstItemIgnoresSafeArea || self.firstItemIsFullWidthMedia
    }

}

/// Uses the same rule resolution pipeline as component styles, evaluated for the current frame.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HeroMediaContext {
    var state: ComponentViewState = .default
    var condition: ScreenCondition = .compact
    var isEligibleForIntroOffer = false
    var isEligibleForPromoOffer = false
    var introEligibilityForPackage: ((Package?) -> Bool)?
    var promoEligibilityForPackage: ((Package?) -> Bool)?
    let conditionContext: ConditionContext
}

struct HeroMediaPresentation {
    let rootIsMedia: Bool
    let headerIgnoresSafeArea: Bool
}

private struct HeroMediaPresentationKey: EnvironmentKey {
    static let defaultValue: HeroMediaPresentation? = nil
}

extension EnvironmentValues {
    var heroMediaPresentation: HeroMediaPresentation? {
        get { self[HeroMediaPresentationKey.self] }
        set { self[HeroMediaPresentationKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct HeroMediaPartial: PresentedPartial {
    let visible: Bool?
    let size: PaywallComponent.Size?

    static func combine(_ base: Self?, with other: Self?) -> Self {
        Self(visible: other?.visible ?? base?.visible, size: other?.size ?? base?.size)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HeroMediaNode {
    enum Result: Equatable {
        case hidden
        case nonMedia
        case media(ViewModelFactory.FirstMediaType)

        var isMedia: Bool {
            if case .media = self { return true }
            return false
        }
    }

    private var visible: Bool? = true
    private var size: PaywallComponent.Size?
    private var media: ViewModelFactory.FirstMediaType?
    private var children: [HeroMediaNode]?
    private var overrides: PresentedOverrides<HeroMediaPartial>?
    private var package: Package?
    private var packageVisibilityResolver: PackageVisibilityResolver?
    private var includesStateValues = true
    private let uiConfigProvider: UIConfigProvider

    // swiftlint:disable:next cyclomatic_complexity
    init(
        component: PaywallComponent, discardRules: Bool, offering: Offering? = nil, uiConfigProvider: UIConfigProvider
    ) {
        self.uiConfigProvider = uiConfigProvider
        switch component {
        case .fallbackHeader:
            visible = false
        case .stack(let stack):
            visible = stack.visible
            children = stack.components.compactMap {
                if case .fallbackHeader = $0 { return nil }
                return Self(component: $0, discardRules: discardRules,
                            offering: offering, uiConfigProvider: uiConfigProvider)
            }
            overrides = stack.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .image(let component):
            visible = component.visible
            size = component.size
            media = .image
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .video(let component):
            includesStateValues = false
            visible = component.visible
            size = component.size
            media = .video
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .webView(let component):
            visible = component.visible
            size = component.size
            media = .webView
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: nil)
            }
        case .text(let component):
            visible = component.visible
            size = component.size
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .icon(let component):
            visible = component.visible
            size = component.size
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .timeline(let component):
            includesStateValues = false
            visible = component.visible
            size = component.size
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .tabs(let component):
            includesStateValues = false
            visible = component.visible
            size = component.size
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .carousel(let component):
            includesStateValues = false
            visible = component.visible
            size = component.size
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: $0.size)
            }
        case .button(let component):
            includesStateValues = false
            visible = component.visible
            overrides = component.overrides?.toPresentedOverrides(discardRules: discardRules) {
                HeroMediaPartial(visible: $0.visible, size: nil)
            }
        case .package(let component):
            package = offering?.package(identifier: component.packageID)
            packageVisibilityResolver = PackageVisibilityResolver(
                component: component, uiConfigProvider: uiConfigProvider, discardRules: discardRules
            )
        default:
            break
        }
    }

    /// ZLayers exempt only a direct media child, preserving the existing nested-stack behavior.
    func firstVisibleDirectMediaIndex(context: HeroMediaContext) -> Int? {
        guard let children else { return nil }
        for (index, child) in children.enumerated() {
            let result = child.firstVisible(context: context)
            if result == .hidden { continue }
            return child.media != nil && result.isMedia ? index : nil
        }
        return nil
    }

    func firstVisible(context inheritedContext: HeroMediaContext) -> Result {
        let context = inheritedContext
        if let packageVisibilityResolver {
            guard let package else { return .hidden }
            let packageState: ComponentViewState =
                context.conditionContext.selectedPackageId == package.identifier ? .selected : .default
            // Keep package visibility aligned with PackageComponentView, including its condition context.
            let visible = packageVisibilityResolver.visible(
                state: packageState,
                condition: context.condition,
                isEligibleForIntroOffer: context.introEligibilityForPackage?(package) ?? false,
                isEligibleForPromoOffer: context.promoEligibilityForPackage?(package) ?? false,
                selectedPackageId: context.conditionContext.selectedPackageId,
                customVariables: context.conditionContext.customVariables,
                windowSize: context.conditionContext.windowSize
            )
            return visible ? .nonMedia : .hidden
        }
        // These renderers currently omit state-store values from their condition context.
        let conditionContext = includesStateValues ? context.conditionContext : uiConfigProvider.conditionContext(
            selectedPackageId: context.conditionContext.selectedPackageId,
            customVariables: context.conditionContext.customVariables,
            windowSize: context.conditionContext.windowSize
        )
        let partial = HeroMediaPartial.buildPartial(
            state: context.state,
            condition: context.condition,
            isEligibleForIntroOffer: context.isEligibleForIntroOffer,
            isEligibleForPromoOffer: context.isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: overrides
        )
        guard partial?.visible ?? visible ?? true else { return .hidden }
        if let children {
            return children.lazy.map { $0.firstVisible(context: context) }
                .first { $0 != .hidden } ?? .nonMedia
        }
        if let media, (partial?.size ?? size)?.width.isFill == true { return .media(media) }
        return .nonMedia
    }
}

#endif
