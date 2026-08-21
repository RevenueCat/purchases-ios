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

#endif
