//
//  ProgressView.swift
//
//
//  Created by Nacho Soto on 12/20/23.
//

import Foundation
import SwiftUI

/// `SwiftUI.ProgressView` overload that becomes non-animated during snapshots.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ProgressView: View {

    #if DEBUG
    @Environment(\.isRunningSnapshots)
    private var isRunningSnapshots
    #endif

    var body: some View {
        #if DEBUG
        if self.isRunningSnapshots {
            SwiftUI.ProgressView(value: 0.5)
        } else {
            SwiftUI.ProgressView()
        }
        #else
        SwiftUI.ProgressView()
        #endif
    }

}
