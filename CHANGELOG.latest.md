## RevenueCat SDK
### 🐞 Bugfixes
* Fix rendering of buttons in Mac Catalyst mode when optimized for Mac. (#5372) via Chris Lindsay (@clindsay3)
* Update default height of paywalls when using .presentIfNeeded on Mac Catalyst to something that is more reasonable. (#5378) via Chris Lindsay (@clindsay3)
### Customer Center
#### ✨ New Features
* Add custom change plans support for customer center (#5379) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Fix VirtualCurrencyBalancesScreen Preview on Catalyst (Optimized For Mac) (#5387) via Will Taylor (@fire-at-will)
* Add `@_spi` to initializers of virtual currencies APIs (#5384) via Antonio Pallares (@ajpallares)
* Use SwiftUI instead of UIKit to present an alert in Paywall Tester app (#5381) via Chris Lindsay (@clindsay3)
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#5380) via RevenueCat Git Bot (@RCGitBot)
* Add build configurations for tuist workspace (#5364) via Facundo Menzella (@facumenzella)
* Adding deep link for testing in Paywalls Tester (#5238) via Josh Holtz (@joshdholtz)
* Wait a max of 20 minutes for TestFlight processing (#5153) via Josh Holtz (@joshdholtz)
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#5373) via RevenueCat Git Bot (@RCGitBot)
* Generate Mac Catalyst screenshots of Paywall components to be sent to EmergeTools (#5303) via Chris Lindsay (@clindsay3)
* Use a more accurate method for generating a screenshot of a UIView (#5352) via Chris Lindsay (@clindsay3)
* Upload screenshots to Emerge in addition to pushing them to the paywall validation repo. (#5351) via Chris Lindsay (@clindsay3)
* Add a few additional VC integration tests (#5367) via Will Taylor (@fire-at-will)
* [CI] Use m1 instead of m2 executor (#5369) via Mark Villacampa (@MarkVillacampa)
