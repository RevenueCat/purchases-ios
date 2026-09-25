//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowSkeleton.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

struct WorkflowSkeleton {

    private let tone: PaywallComponent.ColorScheme
    private let colors: [String: PaywallComponent.ColorScheme]

    static func transform(
        _ data: PaywallComponentsData,
        colors: [String: PaywallComponent.ColorScheme]
    ) -> PaywallComponentsData {
        let background = Self.backgroundColor(data.componentsConfig.base.background)
        let light = Self.brightness(background.light, colors: colors, dark: false)
        let dark = Self.brightness(background.dark ?? background.light, colors: colors, dark: true)
        let transform = Self(
            tone: .init(light: .hex(light < 0.5 ? "#383838" : "#D8D8D8"),
                        dark: .hex(dark < 0.5 ? "#383838" : "#D8D8D8")),
            colors: colors
        )
        let base = data.componentsConfig.base
        var copy = data
        copy.exitOffers = nil
        copy.componentsConfig = .init(base: .init(
            stack: transform.stack(base.stack),
            header: base.header.map { .init(stack: transform.stack($0.stack)) },
            stickyFooter: base.stickyFooter.map { .init(stack: transform.stack($0.stack)) },
            background: .color(background)
        ))
        return copy
    }

    private func stack(
        _ stack: PaywallComponent.StackComponent,
        contentHidden: Bool = false,
        forceBlock: Bool = false
    ) -> PaywallComponent.StackComponent {
        let isBlock = forceBlock || self.hasFill(stack.background, color: stack.backgroundColor, border: stack.border)
        return .init(
            visible: stack.visible,
            components: stack.components.compactMap { self.component($0, contentHidden: contentHidden || isBlock) },
            dimension: stack.dimension,
            size: stack.size,
            spacing: stack.spacing,
            backgroundColor: isBlock && !contentHidden ? self.tone : nil,
            padding: stack.padding,
            margin: stack.margin,
            shape: stack.shape,
            border: stack.border.map { .init(color: contentHidden ? Self.clear : self.tone, width: $0.width) },
            overflow: stack.overflow
        )
    }

    // Invisible content still measures fit-sized blocks, without showing their labels.
    // swiftlint:disable:next cyclomatic_complexity
    private func component(_ component: PaywallComponent, contentHidden: Bool = false) -> PaywallComponent? {
        switch component {
        case let .text(text):
            guard text.fontSize >= 14 || contentHidden else { return nil }
            return .text(.init(
                visible: text.visible, text: text.text, fontName: text.fontName, fontWeight: text.fontWeight,
                color: contentHidden ? Self.clear : self.tone,
                size: text.size, padding: text.padding, margin: text.margin,
                fontSize: text.fontSize, horizontalAlignment: text.horizontalAlignment,
                fontWeightInt: text.fontWeightInt
            ))
        case let .stack(stack):
            return .stack(self.stack(stack, contentHidden: contentHidden))
        case let .button(button):
            guard button.visible != false else { return nil }
            return .stack(self.stack(button.stack, contentHidden: contentHidden))
        case let .package(package):
            guard package.visible != false else { return nil }
            return .stack(self.stack(package.stack, contentHidden: contentHidden, forceBlock: true))
        case let .purchaseButton(button):
            return .stack(self.stack(button.stack, contentHidden: contentHidden, forceBlock: true))
        case let .stickyFooter(footer):
            return .stack(self.stack(footer.stack, contentHidden: contentHidden))
        case let .image(image):
            return .image(self.image(image, contentHidden: contentHidden))
        case let .video(video):
            return .image(self.image(.init(
                visible: video.visible,
                source: .init(light: Self.imageSource(video.source.light),
                              dark: video.source.dark.map(Self.imageSource)),
                size: video.size, fitMode: video.fitMode, maskShape: video.maskShape,
                padding: video.padding, margin: video.margin, border: video.border
            ), contentHidden: contentHidden))
        case let .tabs(tabs):
            return .stack(self.stack(.init(
                visible: tabs.visible,
                components: tabs.tabs.first.map { [.stack($0.stack)] } ?? [],
                size: tabs.size, background: tabs.background, padding: tabs.padding, margin: tabs.margin,
                shape: tabs.shape, border: tabs.border
            ), contentHidden: contentHidden))
        case let .carousel(carousel):
            return .stack(self.stack(.init(
                visible: carousel.visible,
                components: carousel.pages.first.map { [.stack($0)] } ?? [],
                size: carousel.size ?? .init(width: .fill, height: .fit(nil)), background: carousel.background,
                padding: carousel.padding ?? .zero, margin: carousel.margin ?? .zero,
                shape: carousel.shape, border: carousel.border
            ), contentHidden: contentHidden))
        case let .countdown(countdown):
            return .stack(self.stack(countdown.countdownStack, contentHidden: contentHidden))
        case let .timeline(timeline):
            return .stack(self.stack(.init(
                visible: timeline.visible,
                components: timeline.items.map { item in
                    .stack(.init(
                        components: [.text(item.title)] + (item.description.map { [.text($0)] } ?? []),
                        spacing: timeline.textSpacing
                    ))
                },
                size: timeline.size, spacing: timeline.itemSpacing,
                padding: timeline.padding, margin: timeline.margin
            ), contentHidden: contentHidden))
        case .icon, .tabControl, .tabControlButton, .tabControlToggle, .fallbackHeader, .webView:
            return nil
        }
    }

    private func image(
        _ image: PaywallComponent.ImageComponent,
        contentHidden: Bool
    ) -> PaywallComponent.ImageComponent {
        return .init(
            visible: image.visible, source: image.source, size: image.size,
            fitMode: image.fitMode, maskShape: image.maskShape,
            colorOverlay: contentHidden ? Self.clear : self.tone, padding: image.padding, margin: image.margin,
            border: image.border.map { .init(color: contentHidden ? Self.clear : self.tone, width: $0.width) }
        )
    }

    private static func imageSource(_ video: PaywallComponent.VideoUrls) -> PaywallComponent.ImageUrls {
        return .init(width: video.width, height: video.height,
                     original: video.url, heic: video.url, heicLowRes: video.url)
    }

    private func hasFill(
        _ background: PaywallComponent.Background?,
        color: PaywallComponent.ColorScheme?,
        border: PaywallComponent.Border?
    ) -> Bool {
        if let border, border.width > 0, self.isVisible(border.color) { return true }
        if let color, self.isVisible(color) { return true }
        guard let background else { return false }
        if case let .color(color) = background { return self.isVisible(color) }
        return true
    }

    private func isVisible(_ color: PaywallComponent.ColorScheme) -> Bool {
        return Self.alpha(color.light, colors: self.colors, dark: false) > 0 ||
            Self.alpha(color.dark ?? color.light, colors: self.colors, dark: true) > 0
    }

    private static let clear = PaywallComponent.ColorScheme(light: .hex("#00000000"))

    private static func backgroundColor(_ background: PaywallComponent.Background) -> PaywallComponent.ColorScheme {
        switch background {
        case let .color(color): return color
        case let .image(_, _, overlay), let .video(_, _, _, _, _, overlay):
            return overlay ?? .init(light: .hex("#FFFFFF"), dark: .hex("#151515"))
        }
    }

    private static func hexes(
        _ color: PaywallComponent.ColorInfo,
        colors: [String: PaywallComponent.ColorScheme],
        dark: Bool
    ) -> [String] {
        switch color {
        case let .hex(hex): return [hex]
        case let .linear(_, points), let .radial(points): return points.map(\.color)
        case let .alias(alias):
            guard let value = colors[alias] else { return [] }
            return self.hexes(dark ? value.dark ?? value.light : value.light, colors: [:], dark: dark)
        }
    }

    private static func brightness(
        _ color: PaywallComponent.ColorInfo,
        colors: [String: PaywallComponent.ColorScheme],
        dark: Bool
    ) -> Double {
        let values = self.hexes(color, colors: colors, dark: dark).compactMap { hex -> Double? in
            guard let rgb = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).prefix(6), radix: 16)
            else { return nil }
            return (0.299 * Double((rgb >> 16) & 255) +
                    0.587 * Double((rgb >> 8) & 255) + 0.114 * Double(rgb & 255)) / 255
        }
        return values.isEmpty ? (dark ? 0.08 : 1) : values.reduce(0, +) / Double(values.count)
    }

    private static func alpha(
        _ color: PaywallComponent.ColorInfo,
        colors: [String: PaywallComponent.ColorScheme],
        dark: Bool
    ) -> Double {
        return self.hexes(color, colors: colors, dark: dark).map { hex in
            let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            return value.count == 8 ? Double(UInt8(value.suffix(2), radix: 16) ?? 255) / 255 : 1
        }.max() ?? 0
    }

}

#endif
