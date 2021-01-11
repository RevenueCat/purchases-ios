//
//  Errors.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import UIKit

/*
 Convenience methods to display error messages.
 */

extension UIAlertController {
    class func errorAlert(message: String) -> UIAlertController {
        let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return errorAlert
    }
}
