## 🫂 Customer Center Beta 🫂

This release adds public beta support for the new Customer Center on iOS 15.0+.

This central hub is a self-service section that can be added to your app to help your users manage their subscriptions on their own, reducing the support burden on developers 
like you so you can spend more time building apps and less time dealing with support issues. We are hoping adding this new section to your app can help you reduce customer support 
interactions, obtain feedback from your users and ultimately reduce churn by retaining them as subscribers, helping you make more money.

See our [Customer Center documentation](https://www.revenuecat.com/docs/tools/customer-center) for more information.

### Features currently available
* Users can cancel current subscriptions
* Users can ask for refunds
* Users can change their subscription plans
* Users can restore previous purchases and contact your support email if they have trouble restoring
* Users will be asked to update their app if they are on an older version before being able to contact your support email
* Developers can ask for reasons for cancellations or refunds, and automatically offer promo offers to retain users
* Configuration is done in the RevenueCat dashboard, and advanced configuration is available via JSON

### Limitations
* Only available on iOS 15+
* Limited visual configuration options in the dashboard. It is possible to configure the Customer Center via JSON.
* We are exposing a SwiftUI view and a modifier at the moment. We haven't built a UIKit wrapper to help integrating on UIKit apps, but it's in the roadmap.

### How to enable
You can use the CustomerCenterView view directly:

```swift
var body: some View {
    Group {
        NavigationStack {
            HomeView()
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            self.isCustomerCenterPresented = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
        }
    }
    .foregroundColor(.white)
    .sheet(isPresented: $isCustomerCenterPresented) {
        CustomerCenterView()
    }
}
```

Or you can use the modifier:

```swift
VStack {
    Button {
        self.presentingCustomerCenter = true
    } label: {
        TemplateLabel(name: "Customer Center", icon: "person.fill")
    }
}
.presentCustomerCenter(isPresented: self.$presentingCustomerCenter) {
    self.presentingCustomerCenter = false
}
```

### Listening to events

You can listen to events in the Customer Center using the `customerCenterActionHandler` closure:

```swift
CustomerCenterView { customerCenterAction in
    switch customerCenterAction {
    case .restoreStarted:
    case .restoreFailed(_):
    case .restoreCompleted(_):
    case .showingManageSubscriptions:
    case .refundRequestStarted(_):
    case .refundRequestCompleted(_):
    }
}
```

or if using the modifier:

```swift
.presentCustomerCenter(
    isPresented: self.$presentingCustomerCenter,
    customerCenterActionHandler: { action in
        switch action {
        case .restoreCompleted(let customerInfo):
        case .restoreStarted:
        case .restoreFailed(let error):
        case .showingManageSubscriptions:
        case .refundRequestStarted(let productId):
        case .refundRequestCompleted(let status):
        case .feedbackSurveyCompleted(let surveyOptionID):
        }
    }
) {
    self.presentingCustomerCenter = false
}
```

## Release Notes

### RevenueCatUI SDK
#### Paywall Components
##### 🐞 Bugfixes
* Match text, image, and stack properties and behaviors from dashboard (#4261) via Josh Holtz (@joshdholtz)
#### Customer Center
##### 🐞 Bugfixes
* More customer center docs and fix init (#4304) via Cesar de la Vega (@vegaro)
* Remove background from FeedbackSurveyView (#4300) via Cesar de la Vega (@vegaro)

#### 🔄 Other Changes
* Fix iOS 15 tests (#4320) via Cesar de la Vega (@vegaro)
* Generating new test snapshots for `main` - watchos (#4323) via RevenueCat Git Bot (@RCGitBot)
* Generating new test snapshots for `main` - macos (#4322) via RevenueCat Git Bot (@RCGitBot)
* Adds an `onDismiss` callback to `ErrorDisplay` (#4312) via JayShortway (@JayShortway)
* Added previews for text component, image component, and paywall for template 1 (#4306) via Josh Holtz (@joshdholtz)
* Remove `CUSTOMER_CENTER_ENABLED` (#4305) via Cesar de la Vega (@vegaro)
* [Diagnostics] Refactor diagnostics track methods to handle background work automatically (#4270) via Toni Rico (@tonidero)
* [Diagnostics] Add `apple_products_request` event (#4247) via Toni Rico (@tonidero)
* Bump webrick from 1.7.0 to 1.8.2 in /Tests/InstallationTests/CocoapodsInstallation (#4313) via dependabot[bot] (@dependabot[bot])
* Bump fastlane from 2.222.0 to 2.223.1 (#4309) via dependabot[bot] (@dependabot[bot])
* Bump fastlane-plugin-revenuecat_internal from `55a0455` to `5b2e35c` (#4310) via dependabot[bot] (@dependabot[bot])
