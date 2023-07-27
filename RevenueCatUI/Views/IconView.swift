//
//  IconView.swift
//  
//
//  Created by Nacho Soto on 7/25/23.
//

import SwiftUI

/// A view that renders an icon by name, tinted with a color.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct IconView<S: ShapeStyle>: View {

    let icon: PaywallIcon
    let tint: S

    var body: some View {
        Image(self.icon.rawValue, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(self.tint)
    }

}

/// An icon to be displayed by `IconView`.
enum PaywallIcon: String, CaseIterable {

    case add
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
    case notifications
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
    case vpnKey = "vpn_key"
    case warning

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct IconView_Previews: PreviewProvider {

    static var previews: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
            ForEach(PaywallIcon.allCases, id: \.rawValue) { icon in
                Self.icon(icon, Self.colors.randomElement()!)
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
