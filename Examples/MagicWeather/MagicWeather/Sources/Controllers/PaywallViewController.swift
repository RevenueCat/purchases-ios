//
//  PaywallViewController.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/22/20.
//

import UIKit
import Purchases

/*
 An example paywall that uses the current offering.
 Configured in /Resources/UI/Paywall.storyboard
 */

class PaywallViewController: UITableViewController {

    /// - Store the offering being displayed
    var offering: Purchases.Offering?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// - Load offerings when the paywall is displayed
        Purchases.shared.offerings { (offerings, error) in
            
            /// - If we have an error fetching offerings here, we'll print it out. You'll want to handle this case by either retrying, or letting your users know offerings weren't able to be fetched.
            if let error = error {
                print(error.localizedDescription)
            }
            
            self.offering = offerings?.current
            self.tableView.reloadData()
        }
    }
    
    @IBAction func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }

    /* Some UITableView methods for customization */

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Magic Weather Premium"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        #warning("Modify this value to reflect your app's Privacy Policy and Terms & Conditions agreements. Required to make it through App Review.")
        return "\nDon't forget to add your subscription terms and conditions. Read more about this here: https://www.revenuecat.com/blog/schedule-2-section-3-8-b"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.offering?.availablePackages.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PackageCell", for: indexPath) as! PackageCell
        
        /// - Configure the PackageCell to display the appropriate name, pricing, and terms
        if let package = self.offering?.availablePackages[indexPath.row] {
            cell.packageTitleLabel.text = package.product.localizedTitle
            cell.packagePriceLabel.text = package.localizedPriceString
            
            if let intro = package.product.introductoryPrice {
                if intro.price == 0 {
                    cell.packageTermsLabel.text = "\(intro.subscriptionPeriod.periodTitle()) free trial"
                } else {
                    cell.packageTermsLabel.text = "\(package.localizedIntroductoryPriceString) for \(intro.subscriptionPeriod.periodTitle())"
                }
            } else {
                cell.packageTermsLabel.text = "Unlocks Premium"
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        /// - Find the package being selected, and purchase it
        if let package = self.offering?.availablePackages[indexPath.row] {
            Purchases.shared.purchasePackage(package) { (transaction, purchaserInfo, error, userCancelled) in
                if let error = error {
                    self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
                } else {
                    /// - If the entitlement is active after the purchase completed, dismiss the paywall
                    if purchaserInfo?.entitlements[Constants.entitlementID]?.isActive == true {
                        self.dismissModal()
                    }
                }
            }
        }
    }
}

/* Some methods to make displaying subscription terms easier */

extension SKProductSubscriptionPeriod {
    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        default: return "Unknown"
        }
    }
    
    func periodTitle() -> String {
        let periodString = "\(self.numberOfUnits) \(self.durationTitle)"
        let pluralized = self.numberOfUnits > 1 ?  periodString + "s" : periodString
        return pluralized
    }
}
