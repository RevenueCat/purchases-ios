//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RevenueCatDeeplinkHandler.swift
//
//  Created by Andrés Boedo on 9/17/24.

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
struct RevenueCatDeeplinkHandlerView<Content: View>: View {
    @State private var isShowingPaywall: Bool = false
    @State private var offeringID: String?

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .onOpenURL { url in
                if let extractedOfferingID = extractOfferingID(from: url) {
                    offeringID = extractedOfferingID
                    isShowingPaywall = true
                }
            }
            .sheet(
                isPresented: $isShowingPaywall,
                onDismiss: {
                    offeringID = nil
                },
                content: {
                    if let offeringID = offeringID {
                        OfferingLoaderView(offeringID: offeringID)
                    } else {
                        Text("Invalid offering ID.")
                    }
                })
    }

    private func extractOfferingID(from url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "offeringID" })?.value
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {
    func handleRevenueCatDeeplinks() -> some View {
        RevenueCatDeeplinkHandlerView {
            self
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
struct OfferingLoaderView: View {
    let offeringID: String
    @State private var offering: Offering?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let offering = offering {
                PaywallView(offering: offering)
            } else if isLoading {
                ProgressView()
            } else {
                Text("Could not load offering.")
            }
        }
        .task {
            await fetchOffering()
        }
    }

    private func fetchOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let offering = offerings.offering(identifier: offeringID) {
                self.offering = offering
            } else {
                isLoading = false
                print("Offering with ID \(offeringID) not found.")
            }
        } catch {
            isLoading = false
            print("Error fetching offering: \(error.localizedDescription)")
        }
    }
}
