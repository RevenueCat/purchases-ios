### New Features
#### ✨ Introducing RevenueCatUI 📱 (beta):

RevenueCat's Paywalls allow you to to remotely configure your entire paywall view without any code changes or app updates.
Our paywall templates use native code to deliver smooth, intuitive experiences to your customers when you’re ready to deliver them an Offering; and you can use our Dashboard to pick the right template and configuration to meet your needs.

To use RevenueCat Paywalls on iOS, simply:

1. Create a Paywall on the Dashboard for the `Offering` you intend to serve to your customers
2. Add the `RevenueCatUI` SPM dependency to your project
3. `import RevenueCatUI` at the point in the user experience when you want to display a paywall:

```swift
import RevenueCatUI
import SwiftUI

struct YourApp: View {

    var body: some View {
        YourContent()
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "pro") { customerInfo in
                print("Purchase completed: \(customerInfo)")
            }
    }

}
```
