## RevenueCat SDK
### 🐞 Bugfixes
* reload customer center after re-syncing customer info (#5166) via Facundo Menzella (@facumenzella)
### Customer Center
#### ✨ New Features
* Add price to NonSubscriptionTransaction (#5131) via Facundo Menzella (@facumenzella)
* Show other purchases in Purchases List (#5126) via Facundo Menzella (@facumenzella)
* Include PurchaseInformationCardView in SubscriptionDetail (#5121) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* fix: Do not reload actions when selecting purchase (#5164) via Facundo Menzella (@facumenzella)
* Show feedback for as a sheet instead of a push (#5156) via Facundo Menzella (@facumenzella)
* Introduce CustomerCenterButtonStyle to highlight CustomerCenter buttons (#5158) via Facundo Menzella (@facumenzella)
* Minor UI tweaks for CustomerCenter 2.0 (#5159) via Facundo Menzella (@facumenzella)
* Pass CustomerCenterViewModel as observed object to RestoreAlert (#5146) via Facundo Menzella (@facumenzella)
* Pass CustomerCenterViewModel as a ObservedObject to the detail screen (#5154) via Facundo Menzella (@facumenzella)
* Add isActive to PurchaseInformation for CustomerCenter (#5152) via Facundo Menzella (@facumenzella)
* Minor UI tweaks for Customer Center subscription list (#5150) via Facundo Menzella (@facumenzella)
* Dont show `see all purchases` button if there's nothing else to show (#5134) via Facundo Menzella (@facumenzella)
* Filter changePlans path for lifetime purchases in CustomerCenter (#5133) via Facundo Menzella (@facumenzella)
* Add restore overlay to RelevantPurchasesListView (#5130) via Facundo Menzella (@facumenzella)

## RevenueCatUI SDK
### Customer Center
#### ✨ New Features
* Introduce purchase card badges (#5118) via Facundo Menzella (@facumenzella)
* Show account details in active subscription list (#5115) via Facundo Menzella (@facumenzella)
* Deprecate ManageSubscriptionView in favor of ActiveSubscriptionList (#5101) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* Fix contact support button UI to match ButtonsView (#5129) via Facundo Menzella (@facumenzella)
* Show list if all purchases together are more than one (#5128) via Facundo Menzella (@facumenzella)
* Update margins and copies for SubscriptionList (#5127) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Make latestPurchaseDate non-optional in PurchaseInformation (#5144) via Facundo Menzella (@facumenzella)
* CircleCI: save Ruby 3.2.0 installation in cache (#5163) via Antonio Pallares (@ajpallares)
* Add README to Maestro app (#5165) via Facundo Menzella (@facumenzella)
* Fix some flaky tests (Part 3) (#5155) via Antonio Pallares (@ajpallares)
* Send slack message for load shedder v3 tests report (#5145) via Antonio Pallares (@ajpallares)
* Add ownership type to PurchaseInformation (#5143) via Facundo Menzella (@facumenzella)
* Change to use new endpoint to fetch web product info (#5135) via Toni Rico (@tonidero)
* Fixed locale in RevenueCatUI test data (#5125) via Antonio Pallares (@ajpallares)
* Introduce ActiveSubscriptionButtonsView to use it inside a scrollview (#5123) via Facundo Menzella (@facumenzella)
* Add DEBUG check to SDK Health API tests (#5122) via Antonio Pallares (@ajpallares)
* [DX-404] Adds API Tests for SDK Health Report (#5117) via Pol Piella Abadia (@polpielladev)
* Fix some flaky tests (Part 2) (#5104) via Antonio Pallares (@ajpallares)
* add missing files to Xcode workspace (#5116) via Antonio Pallares (@ajpallares)
* Remove ObservableObject from FeedbackSurveyData (#5106) via Facundo Menzella (@facumenzella)
* Update Nimble dependency to v13.7.1 (#5096) via Antonio Pallares (@ajpallares)
