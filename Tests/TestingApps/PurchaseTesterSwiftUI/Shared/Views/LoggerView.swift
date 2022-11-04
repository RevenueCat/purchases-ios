//
//  LoggerView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/28/22.
//

import Foundation
import SwiftUI

import RevenueCat

struct LoggerView: View {

    @ObservedObject
    var logger: Logger

    var body: some View {
        List(self.logger.messages.reversed()) { entry in
            self.item(entry)
        }
        .navigationTitle("Logs")
        .listRowSeparator(.hidden)
        .transition(.slide)
        .animation(.easeInOut(duration: 1), value: self.logger.messages)
    }

    private func item(_ entry: Logger.Entry) -> some View {
        Text(entry.message)
            .font(.footnote)
    }

}

