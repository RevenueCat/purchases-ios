//
//  LoggerView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/28/22.
//

import Foundation
import SwiftUI

import Core
import RevenueCat

struct LoggerView: View {

    @ObservedObject
    var logger: Logger

    var body: some View {
        #if os(macOS)
        NavigationStack {
            self.list
        }
        #else
        NavigationView {
            self.list
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
        #endif
    }

    private var list: some View {
        List(self.logger.messages.reversed()) { entry in
            self.item(entry)
        }
        .navigationTitle("Logs")
        #if !os(watchOS)
        .listRowSeparator(.hidden)
        #endif
        .transition(.slide)
        .animation(.easeInOut(duration: 1), value: self.logger.messages)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    self.logger.clearMessages()
                } label: {
                    Text("Clear")
                }
            }
        }
    }

    private func item(_ entry: Logger.Entry) -> some View {
        Text(entry.message)
            .font(.footnote)
    }

}

