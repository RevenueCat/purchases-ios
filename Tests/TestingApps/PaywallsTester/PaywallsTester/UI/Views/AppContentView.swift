//
//  AppContentView.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    @ObservedObject
    private var configuration = Configuration.shared
    
    @AppStorage("deadlock_trigger_counter") private var counter = 0
    @AppStorage("deadlock_trigger_flag") private var flag = false
    
    @State private var defaultsObserver: NSObjectProtocol?

    var body: some View {
        TabView {

            #if !os(macOS)
            SamplePaywallsList()
                .tabItem {
                    Image("logo")
                        .renderingMode(.template)
                    Text("Examples")
                }
            #endif
            AppList()
                .tabItem {
                    Label("My Apps", systemImage: "network")
                }

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    .tabItem {
                        Label("Sandbox Paywalls", systemImage: "testtube.2")
                    }
            }

            #if !DEBUG
            if !Purchases.isConfigured {
                Text("Purchases is not configured")
            }
            #endif
            
            deadlockTestView
                .tabItem {
                    Label("Deadlock Test", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                }
        }
    }
    
    private var deadlockTestView: some View {
        VStack(spacing: 16) {
            Text("Deadlock Reproducer")
                .font(.title.bold())
            
            Text("Counter: \(counter)")
                .font(.system(.body, design: .monospaced))
            
            Button(role: .destructive, action: runDeterministicDeadlock) {
                VStack(spacing: 6) {
                    Text("RUN DETERMINISTIC DEADLOCK")
                        .font(.headline)
                    Text("Single-shot repro via SDK restore + cached read")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("If the app freezes, the deadlock occurred!")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !Purchases.isConfigured {
                Text("⚠️ Add API key to Local.xcconfig first")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            addObserverIfNeeded()
        }
        .onDisappear {
            removeObserver()
        }
    }
    
    private func runDeterministicDeadlock() {
        guard Purchases.isConfigured else {
            print("❌ Purchases not configured - add API key to Local.xcconfig")
            return
        }

        Task.detached {
            _ = try? await Purchases.shared.restorePurchases()
            _ = try? await Purchases.shared.restorePurchases()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            counter &+= 1
            flag.toggle()
            _ = Purchases.shared.cachedCustomerInfo
            _ = Purchases.shared.cachedCustomerInfo
        }
    }
    
    private func addObserverIfNeeded() {
        if defaultsObserver == nil {
            defaultsObserver = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                counter &+= 1
                flag.toggle()
                _ = Purchases.shared.cachedCustomerInfo
            }
        }
    }
    
    private func removeObserver() {
        if let observer = defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
            defaultsObserver = nil
        }
    }
    




}


#if !os(macOS) && !os(watchOS)

private extension UIApplication {

    @available(iOS 13.0, macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @MainActor
    var currentWindowScene: UIWindowScene? {
        return self
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first as? UIWindowScene
    }

}

#endif

#if DEBUG

// TODO: Mock developer to instantiate AppContentView
@testable import RevenueCatUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AppContentView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            AppContentView()
              .environmentObject(ApplicationData())
        }
    }

}

#endif

