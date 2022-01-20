//
//  UserViewController.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import UIKit
import RevenueCat

/*
 View controller to display user's details like subscription status and ID's.
 Configured in /Resources/UI/Main.storyboard
 */

class UserViewController: UIViewController {

    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// - Refresh details when the User tab is viewed
        refreshUserDetails()
    }

    func refreshUserDetails() {
        self.userIdLabel.text = Purchases.shared.appUserID
        
        if Purchases.shared.isAnonymous {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log In", style: .done, target: self, action: #selector(presentLoginDialog))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log Out", style: .done, target: self, action: #selector(logout))
        }
        
        Purchases.shared.getCustomerInfo { (purchaserInfo, error) in
            if purchaserInfo?.entitlements[Constants.entitlementID]?.isActive == true {
                self.statusLabel.text = "Active"
                self.statusLabel.textColor = .green
            } else {
                self.statusLabel.text = "Not Active"
                self.statusLabel.textColor = .red
            }
        }
    }
}

/*
 How to login and identify your users with the Purchases SDK.
 
 These functions mimic displaying a login dialog, identifying the user, then logging out later.
 
 Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
 */
extension UserViewController {
    
    /// - Login method. Replace this with your own login sequence.
    @objc
    func presentLoginDialog() {
        let alert = UIAlertController(title: "Log In", message: "Enter your username.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: { (action) in
            /// - Ensure a username was entered
            if let username = alert.textFields?.first?.text, username.isEmpty == false {
                
                #warning("Public-facing usernames aren't optimal for user ID's - you should use something non-guessable, like a non-public database ID. For more information, visit https://docs.revenuecat.com/docs/user-ids.")
                /// - Call `identify` with the Purchases SDK with the unique user ID
                Purchases.shared.logIn(username) { (purchaserInfo, created, error) in
                    if let error = error {
                        self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
                    }
                    
                    self.refreshUserDetails()
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// - Log out method
    @objc
    func logout() {
        
        /*
         The current user ID is no longer valid for your instance of *Purchases* since the user is logging out, and is no longer authorized to access purchaserInfo for that user ID.
        
         `reset` clears the cache and regenerates a new anonymous user ID.
         
         Note: Each time you call `reset`, a new installation will be logged in the RevenueCat dashboard as that metric tracks unique user ID's that are in-use. Since this method generates a new anonymous ID, it counts as a new user ID in-use.
         */
        Purchases.shared.logOut { (purchaserInfo, error) in
            if let error = error {
                self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
            } else {
                self.refreshUserDetails()
            }
            
        }
    }
}


/*
 How to restore purchases using the Purchases SDK. Read more about restoring purchases here: https://docs.revenuecat.com/docs/making-purchases#restoring-purchases
 */
extension UserViewController {
    
    /// - Restore purchases method
    @IBAction
    func restorePurchases() {
        Purchases.shared.restorePurchases { (purchaserInfo, error) in
            if let error = error {
                self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
            }
            
            self.refreshUserDetails()
        }
    }
}
