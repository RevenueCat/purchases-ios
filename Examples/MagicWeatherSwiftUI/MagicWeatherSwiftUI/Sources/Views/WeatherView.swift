//
//  WeatherView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import SwiftUI
import RevenueCat

/*
 The app's weather tab that displays our pretend weather data.
 */

struct WeatherView: View {

    @Binding var paywallPresented: Bool
    @ObservedObject var model = WeatherViewModel.shared
    @ObservedObject var userModel = UserViewModel.shared

    var body: some View {
        VStack {
            /// - Sample weather details
            
            Text("\(model.currentData.emoji)")
                .padding(.top, 32.0)
                .font(.system(size: 76))
            Text("\(model.currentData.temperature)°\(model.currentData.unit.rawValue.capitalized)")
                .multilineTextAlignment(.center)
                .font(.custom("ArialRoundedMTBold", size: 96.0))
                .padding(.top, 8.0)
            
            /// - Environment button
            Button(action: {
                
            }) {
                Label("Earth", systemImage: "location.fill")
                    .foregroundColor(.white)
                    .font(.headline)
            }.padding(.top, 16.0)
            /// - we'll change the environment in a future update, disable for now
            .allowsHitTesting(false)

            Spacer()
            
            /// - The magic button that is disabled behind our paywall
            Button("✨ Change the Weather") {
                self.performMagic()
            }
            .foregroundColor(.white)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 64.0)
        }
        .padding(.all, 16.0)
        .background(Color(model.currentData.weatherColor ?? .systemBackground))

    }
    
    private func performMagic() {
        /*
         We should check if we can magically change the weather (subscription active) and if not, display the paywall.
         */
        if self.userModel.subscriptionActive {
            self.model.currentData = SampleWeatherData.generateSampleData(for: self.model.currentEnvironment)
        } else {
            self.paywallPresented.toggle()
        }
    }

}
