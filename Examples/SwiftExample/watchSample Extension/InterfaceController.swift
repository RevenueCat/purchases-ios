//
//  InterfaceController.swift
//  watchPurchasesCocoapods2 WatchKit Extension
//
//  Created by RevenueCat on 2/11/20.
//  Copyright © 2020 RevenueCat. All rights reserved.
//

import WatchKit
import Foundation
import Purchases

class InterfaceController: WKInterfaceController {
    private var offering : Purchases.Offering?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        configure()
        loadOfferings()
        // Configure interface objects here.
    }
    
    @IBOutlet weak var proStatusLabel: WKInterfaceLabel!
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBOutlet weak var buyButton: WKInterfaceButton!
    
    @IBAction func didPressBuy() {
        purchase()
    }
    
    private func purchase() {
        guard let offering = offering else {
            print("No available offerings")
            return
        }
        let package = offering.availablePackages[0]
        
        proStatusLabel.setText("purchasing...")
        Purchases.shared.purchasePackage(package) { [weak self] (trans, info, error, cancelled) in
            guard let self = self else { return }
            
            if let error = error {
                print(error)
                self.proStatusLabel.setText("Purchase cancelled!")
            }
            else {
                self.configure()
            }
        }
    }
    
    
    private func loadOfferings() {
        
        proStatusLabel.setText("Loading...")
        buyButton.setHidden(true)
        
        Purchases.shared.offerings { [weak self] (offerings, error) in
            guard let self = self else { return }
            if error != nil {
                self.proStatusLabel.setText("Error fetching offerings 😿")
                return
            }
            guard let offerings = offerings, let offering = offerings.current else { fatalError("didn't get an error but didn't get offerings") }
            
            self.offering = offering
            self.buyButton.setHidden(false)
            self.configure()
        }
    }
    
    private func configure() {
        Purchases.shared.purchaserInfo { [weak self] (purchaserInfo, error) in
            guard let self = self else { return }
            if let e = error {
                print(e.localizedDescription)
                return
            }
            
            guard let purchaserInfo = purchaserInfo else { fatalError("didn't get purchaser info but error was nil") }
            // Route the view depending if we have a premium cat user or not
            let hasPro = !purchaserInfo.entitlements.active.isEmpty
            self.proStatusLabel.setText(hasPro ? "pro 😻" : "free 🐱")
            self.buyButton.setHidden(hasPro)
        }
    }
}
