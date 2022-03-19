//
//  InterfaceController.swift
//  watchPurchasesCocoapods2 WatchKit Extension
//
//  Created by RevenueCat on 2/11/20.
//  Copyright © 2020 RevenueCat. All rights reserved.
//

import WatchKit
import Foundation
import RevenueCat

class InterfaceController: WKInterfaceController {
    private var offering : Offering?
    
    @IBOutlet weak var expiryDateLabel: WKInterfaceLabel!
    @IBOutlet weak var purchaseDateLabel: WKInterfaceLabel!
    @IBOutlet weak var proStatusLabel: WKInterfaceLabel!
    @IBOutlet weak var buyButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        configure()
        loadOfferings()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    @IBAction func didPressBuy() {
        purchase()
    }
}

private extension InterfaceController {
    
    func purchase() {
        guard let offering = offering else {
            print("No available offerings")
            return
        }
        let package = offering.availablePackages[0]
        
        proStatusLabel.setText("purchasing...")
        Purchases.shared.purchase(package: package) { [weak self] (trans, info, error, cancelled) in
            guard let self = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
                self.proStatusLabel.setText("error while purchasing!")
            } else if cancelled {
                self.proStatusLabel.setText("purchase cancelled!")
            } else {
                self.configure()
            }
        }
    }
    
    
    func loadOfferings() {
        
        proStatusLabel.setText("Loading...")
        buyButton.setHidden(true)
        
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            guard let self = self else { return }
            if let error = error {
                print(error.localizedDescription)
                self.proStatusLabel.setText("Error fetching offerings 😿")
                return
            }
            
            guard let offerings = offerings, let offering = offerings.current else { fatalError("didn't get an error but didn't get offerings") }
            
            self.offering = offering
            self.buyButton.setHidden(false)
            self.configure()
        }
    }
    
    func configure() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            guard let self = self else { return }
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let customerInfo = customerInfo else { fatalError("didn't get purchaser info but error was nil") }
            // Route the view depending if we have a pro cat user or not
            
            let hasPro = customerInfo.entitlements["pro_cat"]?.isActive == true
            self.proStatusLabel.setText(hasPro ? "pro 😻" : "free 🐱")
            self.buyButton.setHidden(hasPro)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            if let purchaseDate = customerInfo.purchaseDate(forEntitlement: "pro_cat") {
                self.purchaseDateLabel.setText("Purchased: \(dateFormatter.string(from: purchaseDate))")
            }
            if let expirationDate = customerInfo.expirationDate(forEntitlement: "pro_cat") {
                self.expiryDateLabel.setText("Expires: \(dateFormatter.string(from: expirationDate))")
            }
        }
    }
}
