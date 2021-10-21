//
//  WeatherViewController.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import UIKit
import RevenueCat

/*
 The app's main view controller that displays our pretend weather data.
 Configured in /Resources/UI/Main.storyboard
 */

class WeatherViewController: UIViewController {

    @IBOutlet var temperatureLabel: UILabel!
    @IBOutlet var environmentButton: UIButton!
    @IBOutlet var magicButton: UIButton!

    var currentEnvironment: SampleWeatherData.Environment = .earth
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// - Set the default weather data on load
        setWeatherData(.testCold)
    }

    @IBAction
    func performMagic() {
        /*
         We should check if we can magically change the weather (subscription active) and if not, display the paywall.
         */
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if customerInfo?.entitlements[Constants.entitlementID]?.isActive == true {
                self.setWeatherData(SampleWeatherData.generateSampleData(for: self.currentEnvironment))
            } else {
                let main = UIStoryboard(name: "Paywall", bundle: nil).instantiateInitialViewController()!
                self.present(main, animated: true, completion: nil)
            }
        }
    }
    
    func setWeatherData(_ data: SampleWeatherData) {
        self.temperatureLabel.text = "\(data.emoji)\n\(data.temperature)°\(data.unit.rawValue.capitalized)"
        self.environmentButton.setTitle("  " + data.environment.rawValue.capitalized, for: .normal)
        self.view.backgroundColor = data.weatherColor
    }
}
