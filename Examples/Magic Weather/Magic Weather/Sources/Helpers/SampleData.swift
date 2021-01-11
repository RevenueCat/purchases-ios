//
//  SampleData.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/16/20.
//

import UIKit

/*
 Sample data for Magic Weather.
 */

struct SampleWeatherData {
    enum TemperatureUnit: String {
        case f
        case c
    }
    
    enum Environment: String {
        case mercury
        case venus
        case earth
        case mars
        case jupiter
        case saturn
        case uranus
        case neptune
        
        /*
         Pluto is still a planet in my ❤️
         */
        case pluto
    }
    
    var emoji: String
    var temperature: String
    var unit: TemperatureUnit = .f
    var environment: Environment = .earth
    
    static let testCold = SampleWeatherData.init(emoji: "❄️", temperature: "14")
    static let testHot = SampleWeatherData.init(emoji: "☀️", temperature: "85")
    
    static func generateSampleData(for environment: SampleWeatherData.Environment, temperature: Int? = nil) -> SampleWeatherData {
        
        let temperature = temperature ?? Int.random(in: -20...120)
        
        var emoji: String
        switch temperature {
        case 0...32:
            emoji = "❄️"
        case 33...60:
            emoji = "☁️"
        case 61...90:
            emoji = "🌤"
        case 91...120:
            emoji = "🥵"
        default:
            if temperature < 0 {
                emoji = "🥶"
            } else {
                emoji = "☄️"
            }
        }
        
        return .init(emoji: emoji, temperature: "\(temperature)", unit: .f, environment: environment)
    }
}

extension SampleWeatherData {
    var weatherColor: UIColor? {
        switch self.emoji {
        case "🥶":
            return #colorLiteral(red: 0.012122632, green: 0.2950853705, blue: 0.5183202624, alpha: 1)
        case "❄️":
            return #colorLiteral(red: 0, green: 0.1543088555, blue: 0.3799687922, alpha: 1)
        case "☁️":
            return #colorLiteral(red: 0.2000069618, green: 1.306866852e-05, blue: 0.2313408554, alpha: 1)
        case "🌤":
            return #colorLiteral(red: 0.8323764622, green: 0.277771439, blue: 0.2446353115, alpha: 1)
        case "🥵":
            return #colorLiteral(red: 0.7131021281, green: 1.25857805e-05, blue: 0.2313565314, alpha: 1)
        case "☄️":
            return #colorLiteral(red: 0.8000227213, green: 1.210316441e-05, blue: 0.2313722372, alpha: 1)
        default:
            return #colorLiteral(red: 0.8000227213, green: 1.210316441e-05, blue: 0.2313722372, alpha: 1)
        }
    }
}
