## RevenueCat SDK
### 🐞 Bugfixes
* Fix Crashes: Move large object cacheing off of user defaults to file storage (#5652) via Jacob Rakidzich (@JZDesign)
* Prevent duplicate post receipt requests (#5795) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### Customer Center
#### ✨ New Features
* CC-582 |  Allow for support ticket creation (#5779) via Rosie Watson (@RosieWatson)
#### 🐞 Bugfixes
* Fix SK1 products always showing Lifetime badge (#5811) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Fixed passing major version as integer to send Slack alert action which accepts a string instead (#5829) via Rick (@rickvdl)
* Uses some git+GitHub lanes from Fastlane plugin (#5823) via JayShortway (@JayShortway)
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#5824) via RevenueCat Git Bot (@RCGitBot)
* Fix strong retain cycle on `Purchases` instance (#5818) via Antonio Pallares (@ajpallares)
* Removed Slack actions from CircleCI config for release jobs that don't add much value and were not working before (#5808) via Rick (@rickvdl)
* Migrate to slack-secrets context again after fixing conflict between orb and Fastlane Slack action (#5806) via Rick (@rickvdl)
