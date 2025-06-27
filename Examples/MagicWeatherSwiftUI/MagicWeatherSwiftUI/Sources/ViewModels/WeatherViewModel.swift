//
//  WeatherViewModel.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import Foundation

/* Static shared model for WeatherView */
class WeatherViewModel: NSObject, ObservableObject {
    static let shared = WeatherViewModel()
    
    @Published var currentData: SampleWeatherData = .testCold
    @Published var currentEnvironment: SampleWeatherData.Environment = .earth
}
