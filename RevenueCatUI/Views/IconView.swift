//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IconView.swift
//
//  Created by Nacho Soto on 7/25/23.

import RevenueCat
import SwiftUI

/// A view that renders an icon by name, tinted with a color.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IconView<S: ShapeStyle>: View {

    let icon: PaywallIcon
    let tint: S

    var body: some View {
        Image(self.icon.localAssetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(self.tint)
            .accessibilityHidden(true)
    }

}

/// An icon to be displayed by `IconView`.
enum PaywallIcon: String, CaseIterable {

    case plus = "add"
    case android
    case apple
    case attachMoney = "attach_money"
    case attachment
    case barChart = "bar_chart"
    case bookmark
    case bookmarkNoFill = "bookmark_no_fill"
    case calendarToday = "calendar_today"
    case chatBubble = "chat_bubble"
    case checkCircle = "check_circle"
    case close
    case collapse
    case compare
    case download
    case edit
    case email
    case error
    case experiments
    case `extension`
    case fileCopy = "file_copy"
    case filterList = "filter_list"
    case folder
    case globe
    case help
    case insertDriveFile = "insert_drive_file"
    case launch
    case layers
    case lineChart = "line_chart"
    case lock
    case notification
    case person
    case phone
    case playCircle = "play_circle"
    case removeRedEye = "remove_red_eye"
    case search
    case share
    case smartphone
    case stackedBar = "stacked_bar"
    case stars
    case subtract
    case tick
    case transfer
    case twoWayArrows = "two_way_arrows"
    case key
    case warning

    // in some cases, the local asset name can't match the backend's names
    // because it causes issues with UIKit's names when generating intermediate files.
    // this allows us to decouple the local asset name from the backend's name for the icon.
    var localAssetName: String {
        switch self {
        case .plus:
            return "plus"
        default:
            return self.rawValue
        }
    }
}

extension PaywallData.LocalizedConfiguration.Feature {

    var icon: PaywallIcon? {
        return self.iconID.flatMap(PaywallIcon.init(rawValue:))
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IconView_Previews: PreviewProvider {

    static var previews: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
            ForEach(Array(PaywallIcon.allCases.enumerated()), id: \.element.rawValue) { index, icon in
                Self.icon(icon, Self.colors[index % Self.colors.count])
            }
        }
    }

    private static func icon<S: ShapeStyle>(_ icon: PaywallIcon, _ color: S) -> some View {
        IconView(icon: icon, tint: color)
    }

    private static let colors: [Color] = [
        .red,
        .green,
        .blue,
        .indigo,
        .brown,
        .cyan,
        .orange,
        .mint,
        .pink,
        .purple,
        .teal
    ]

}

#endif
