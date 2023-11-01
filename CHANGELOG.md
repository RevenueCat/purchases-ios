## 4.30.0
### New Features
* Add `StoreProduct.pricePerWeek` (#3354) via NachoSoto (@NachoSoto)
### RevenueCatUI
* `Paywalls`: `.presentPaywallIfNeeded` allows overriding `Offering` (#3370) via NachoSoto (@NachoSoto)
* `Paywalls`: new optional `displayCloseButton` parameter (#3359) via NachoSoto (@NachoSoto)
* `Paywalls`: improve period abbreviations in Japanese (#3367) via NachoSoto (@NachoSoto)
* `Paywalls`: new `{{ sub_price_per_week }}` variable (#3355) via NachoSoto (@NachoSoto)
* `Paywalls`: log warning when attempting to purchase already-subscribed product (#3366) via NachoSoto (@NachoSoto)
* `Paywalls`: improve Japanese localization (#3364) via NachoSoto (@NachoSoto)
* `Paywalls`: fix template 2 top padding inside navigation view  (#3363) via NachoSoto (@NachoSoto)
* `Paywalls`: avoid animating `PurchaseButton` labels when text does not change (#3361) via NachoSoto (@NachoSoto)
* `Paywalls`: improve `FooterView` accessibility (#3349) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump cocoapods from 1.14.0 to 1.14.2 (#3356) via dependabot[bot] (@dependabot[bot])
* Bump cocoapods from 1.13.0 to 1.14.0 (#3351) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `Paywalls`: simplify `PurchaseButton` (#3362) via NachoSoto (@NachoSoto)
* `Paywalls`: refactored `IntroEligibilityStateView` (#3360) via NachoSoto (@NachoSoto)
* `Paywall Tester`: improve template 5 dark colors (#3358) via NachoSoto (@NachoSoto)
* `Paywalls`: improve conversion from `Color`/`UIColor` to `PaywallColor` (#3357) via NachoSoto (@NachoSoto)
* `Paywalls Tester`: improve `.paywallFooter` presentation (#3348) via NachoSoto (@NachoSoto)
* `Paywalls`: move size configuration to `TemplateViewType` (#3352) via NachoSoto (@NachoSoto)

## 4.29.0
### New Features
* `PaywallColor`: change visibility of `Color.init(light:dark:)` to `private` (#3345) via NachoSoto (@NachoSoto)
### RevenueCatUI
* `Paywalls`: new `.onPurchaseCompleted` overload with `StoreTransaction` (#3323) via NachoSoto (@NachoSoto)
* `Paywalls`: finished template 5 (#3340) via NachoSoto (@NachoSoto)
* `Paywalls`: new `onDismiss` parameter for `presentPaywallIfNeeded` (#3342) via NachoSoto (@NachoSoto)
* `Paywalls`: disable shimmering on footer loading view (#3324) via NachoSoto (@NachoSoto)
### Bugfixes
* `ErrorUtils.purchasesError(withSKError:)`: handle `URLError`s (#3346) via NachoSoto (@NachoSoto)
### Other Changes
* `Paywalls`: add identifier to events (#3332) via Josh Holtz (@joshdholtz)
* `Paywalls`: create new event session when paywall appears (#3330) via Josh Holtz (@joshdholtz)
* `HTTPClient`: verbose logs for request IDs (#3320) via NachoSoto (@NachoSoto)
* `Paywalls Tester`: fix `macOS` build (#3341) via NachoSoto (@NachoSoto)
* `ProductFetcherSK1`: enable `TimingUtil` log (#3327) via NachoSoto (@NachoSoto)
* `Paywall Tester`: fixed paywall presentation (#3339) via NachoSoto (@NachoSoto)
* `CI`: replace Carthage build jobs with `xcodebuild` (#3338) via NachoSoto (@NachoSoto)
* `Integration Tests`: use repetition count from test plan (#3329) via NachoSoto (@NachoSoto)
* `Integration Tests`: new logs for troubleshooting flaky tests (#3328) via NachoSoto (@NachoSoto)
* `CircleCI`: change iOS 17 job to use M1 Large resource (#3322) via NachoSoto (@NachoSoto)
* `Paywalls Tester`: fix release build (#3321) via NachoSoto (@NachoSoto)
* `Paywalls`: enable all iOS 17 tests (#3331) via NachoSoto (@NachoSoto)
* `CI`: added workaround for Snapshots in `Xcode Cloud` (#2857) via NachoSoto (@NachoSoto)
* `StoreKit 1`: disabled `finishTransactions` log on observer mode (#3314) via NachoSoto (@NachoSoto)

## 4.28.1
### Bugfixes
* `PaywallEventStore`: also remove legacy `revenuecat` documents directory (#3317) via NachoSoto (@NachoSoto)
### Other Changes
* `CI`: run all iOS 17 tests (#3312) via NachoSoto (@NachoSoto)
* `StoreKit 2`: Optionally send JWS tokens instead of receipts to the backend (#3227) via Mark Villacampa (@MarkVillacampa)
* `CircleCI`: update simulators for Xcode 15.0.1 (#3311) via NachoSoto (@NachoSoto)
* `StoreKit 1`: improved debug log for `finishTransactions` invoked outside the SDK (#3300) via NachoSoto (@NachoSoto)
* `Debug View`: display receipt status (#3303) via NachoSoto (@NachoSoto)

## 4.28.0
### New Features
* `Purchases`: new `cachedCustomerInfo` and `cachedOfferings` (#3274) via NachoSoto (@NachoSoto)
* Expose `productPlanIdentifier` in `EntitlementInfo` (#3290) via Toni Rico (@tonidero)
### RevenueCatUI
* `Paywalls`: localize default template (#3295) via NachoSoto (@NachoSoto)
* `Paywalls`: created `ConsistentPackageContentView` to improve package change transitions (#3246) via NachoSoto (@NachoSoto)
* `Paywalls`: `visionOS` support (#3293) via NachoSoto (@NachoSoto)
* `Paywalls`: avoid flickering when displaying paywalls with available cache (#3283) via NachoSoto (@NachoSoto)
### Bugfixes
* `PaywallEventStore`: changed container to use `URL.applicationSupportDirectory` (#3289) via NachoSoto (@NachoSoto)
### Other Changes
* `CI`: change `visionOS` build to environment with `xrOS` SDK (#3294) via NachoSoto (@NachoSoto)
* `Paywalls`: extracted common `TemplateViewType` method for previews (#3292) via NachoSoto (@NachoSoto)
* `Tests`: improved flaky test (#3282) via NachoSoto (@NachoSoto)

## 4.27.2
### RevenueCatUI
* `Paywalls`: improved purchase-in-progress UI (#3279) via NachoSoto (@NachoSoto)
### Bugfixes
* `SK2StoreProduct.priceFormatter`: use locale from `StoreKit.Product` (#3278) via NachoSoto (@NachoSoto)
### Performance Improvements
* `AAAttribution.attributionToken`: avoid using on main thread (#3281) via NachoSoto (@NachoSoto)
### Other Changes
* `Paywalls Tester`: group live paywalls by template (#3276) via NachoSoto (@NachoSoto)

## 4.27.1
### RevenueCatUI
* `Paywalls`: added shimmer effect to `LoadingPaywallView` (#3267) via NachoSoto (@NachoSoto)
### Bugfixes
* `Paywalls`: fixed `macOS` compilation (#3272) via NachoSoto (@NachoSoto)
### Other Changes
* Update `SwiftLint` (#3273) via NachoSoto (@NachoSoto)
* PaywallsTester: allow for configuration for demos (#3260) via Andy Boedo (@aboedo)
* `Paywalls`: simplified `LoadingPaywallView` (#3265) via NachoSoto (@NachoSoto)

## 4.27.0
### New Features
* Add `Attribution.setOnesignalUserID` (#3268) via Raquel Diez (@Raquel10-RevenueCat)
* StoreKit In App messages support (#3252) via Toni Rico (@tonidero)
### Other Changes
* Remove ObjC showStoreMessages API (#3269) via Toni Rico (@tonidero)
* PaywallsTester: add a new tab that calls presentPaywallIfNeeded (#3259) via Andy Boedo (@aboedo)
* `Paywalls`: small PaywallsTester refactor (#3261) via NachoSoto (@NachoSoto)

## 4.26.2
### RevenueCatUI
* `Paywalls`: polished template 4 layout math (#3249) via NachoSoto (@NachoSoto)
* `Paywalls`: improved template 1 iPad layout and iOS 15 fix (#3241) via NachoSoto (@NachoSoto)
* `Paywalls`: polished `PurchaseButton` on iPad (#3240) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump cocoapods from 1.12.1 to 1.13.0 (#3251) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `Paywalls`: added previews for `IntroEligibilityStateView` (#3248) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: added list of active entitlements (#3247) via NachoSoto (@NachoSoto)
* PaywallsTester: allow easy testing of paywall modes for All Offerings tab (#3254) via Andy Boedo (@aboedo)
* PaywallsTester: allow resizing on macOS (#3258) via Andy Boedo (@aboedo)
* PaywallsTester: replace opening default paywall automatically with button (#3256) via Andy Boedo (@aboedo)
* PaywallsTester: fix StoreKit Configuration scheme (#3257) via Andy Boedo (@aboedo)
* PaywallsTester: improve navigation on macOS and iPadOS (#3255) via Andy Boedo (@aboedo)
* `PrivacyInfo.xcprivacy`: changed `NSPrivacyCollectedDataTypePurchaseHistory` to `false` (#3242) via NachoSoto (@NachoSoto)
* `Paywalls`: changed `PaywallsTester` to allow not configuring API key (#3244) via NachoSoto (@NachoSoto)
* `Paywalls`: renamed `SimpleApp` to `PaywallsTester` (#3243) via NachoSoto (@NachoSoto)
* Make revisionID private in PaywallData+Default (#3239) via Cesar de la Vega (@vegaro)

## 4.26.1
### RevenueCatUI
* `Paywalls`: don't display progress view in `LoadingPaywallView` (#3235) via NachoSoto (@NachoSoto)
* `Paywalls`: don't display "Purchases restored successfully" if nothings was restored (#3233) via NachoSoto (@NachoSoto)
* `Paywalls`: avoid displaying offer details twice on `.condensedFooter`s (#3230) via NachoSoto (@NachoSoto)
* `Paywalls`: improved `footerView` to use `.continuous` rounded corners (#3222) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump danger from 9.3.1 to 9.3.2 (#3229) via dependabot[bot] (@dependabot[bot])
* Bump fastlane from 2.215.1 to 2.216.0 (#3228) via dependabot[bot] (@dependabot[bot])
* Bump fastlane from 2.214.0 to 2.215.1 (#3221) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `Paywalls`: removed unused property (#3226) via NachoSoto (@NachoSoto)
* `Configuration`: log warning if attempting to use observer mode with StoreKit 2 (#3066) via NachoSoto (@NachoSoto)
* `PurchasedProductsFetcher`: refactored `fetchTransactions` (#3225) via NachoSoto (@NachoSoto)
* `CI`: updated iOS 17 simulator (#3223) via NachoSoto (@NachoSoto)
* `Integration Tests`: prevent false positives when purchasing returns 5xx (#3209) via NachoSoto (@NachoSoto)
* `Integration Tests`: add coverage for `Purchases.customerInfoStream` (#3213) via NachoSoto (@NachoSoto)

## 4.26.0
### New Features
#### ✨ Introducing RevenueCatUI 📱

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
            .presentPaywallIfNeeded(
                requiredEntitlementIdentifier: "pro",
                purchaseCompleted: { customerInfo in
                    print("Purchase completed: \(customerInfo)")
                },
                restoreCompleted: { customerInfo in
                    print("Purchases restored: \(customerInfo)")
                }
            )
    }

}
```

You can find more information in [our documentation](https://rev.cat/paywalls).

<details>

<summary>List of changes</summary>
*  NachoSoto: `Paywalls`: renamed `PaywallEvent.view` to `.impression` (#3212)
*  NachoSoto: `Paywalls`: loading indicator for in-progress purchases (#3217)
*  NachoSoto: `Paywalls`: fixed template 4 bottom padding (#3211)
*  NachoSoto: `Paywalls`: only pre-warm images/intro-eligibility for `Offerings.current` (#3210)
*  NachoSoto: `Paywalls`: fixed mock intro eligibility on snapshot tests (#3205)
*  NachoSoto: `Paywalls`: fixed SimpleApp release build (#3203)
*  NachoSoto: `Paywalls`: improved `DebugErrorView` layout (#3204)
*  NachoSoto: `Paywalls`: refactored `PurchaseHandler` extracting protocol (#3196)
*  NachoSoto: `Paywalls`: automatically flush events (#3177)
*  NachoSoto: `Paywalls`: fixed `TemplateBackgroundImageView` aspect ratio (#3201)
*  NachoSoto: `Paywalls`: fixed broken layout on template 4 (#3202)
*  NachoSoto: `Paywalls`: events unit and integration tests (#3169)
*  NachoSoto: `Paywalls`: send events to `Purchases` (#3164)
*  NachoSoto: `Paywalls`: convert empty images into `nil` (#3195)
*  NachoSoto: `Paywalls`: new `onRestoreCompleted` handler (#3190)
*  NachoSoto: `Paywalls`: fixed `IntroEligibilityViewModel` data lifetime (#3194)
*  NachoSoto: `Paywalls`: test plan for running non-snapshot tests (#3188)
*  NachoSoto: `Paywalls`: polish template 4 (#3183)
*  NachoSoto: `Paywalls`: fixed data flow resulting in multiple `PurchaseHandler` instances (#3187)
*  Cesar de la Vega: `Paywalls`: update `blurred_background_image` key in `PaywallData` test fixture (#3186)
*  NachoSoto: `Paywalls`: added `Purchases.track(paywallEvent:)` (#3160)
*  NachoSoto: `Paywalls`: don't apply dark appearance with no dark mode colors (#3184)
*  NachoSoto: `Paywalls`: fixed template 2 + `.condensedFooter` + iPad (#3185)
*  NachoSoto: `Paywalls`: new `{{ sub_duration_in_months }}` variable (#3173)
*  NachoSoto: `Paywalls`: created `PaywallEventsManager` (#3159)
*  NachoSoto: `Paywalls`: implemented `PostPaywallEventsOperation` (#3158)
*  NachoSoto: `Paywalls`: new `{{ sub_relative_discount }}` variable (#3131)
*  Charlie Chapman: `Paywalls`: improved `FooterView` (#3171)
*  NachoSoto: `Paywalls`: fixed `FooterView` horizontal centering (#3172)
*  NachoSoto: `Paywalls`: created `PaywallEventStore` (#3157)
*  NachoSoto: `Paywalls`: add `PaywallEvent` model (#3156)
*  NachoSoto: `Paywalls`: add `PaywallData.revision` (#3155)
*  NachoSoto: `Paywalls`: support fuzzy-Locale search in `iOS 15` (#3162)
*  NachoSoto: `PaywallData`: added `@NonEmptyString` to `subtitle` and `offerName` (#3150)
*  NachoSoto: `Paywalls`: add paywall for Load Shedder integration tests (#3151)
*  NachoSoto: `Paywalls`: fixed error view being displayed on release builds (#3141)
*  NachoSoto: `Paywalls`: improved `{{ total_price_and_per_month }}` to include period (#3136)
*  NachoSoto: `Paywalls`: `{{ price_per_period }}` now takes `SubscriptionPeriod.value` into account (#3133)
*  NachoSoto: `Paywalls`: add Arabic to SimpleApp for testing (#3132)
*  NachoSoto: `Paywalls`: update snapshot generation with new separate git repo (#3116)
*  NachoSoto: `Paywalls`: add support for CTA button gradients (#3121)
*  NachoSoto: `Paywalls`: template 5 (#3095)
*  NachoSoto: `Paywalls`: replaced submodule with `gitignore`d reference (#3125)
*  NachoSoto: `Catalyst`: fixed a couple of Catalyst build warnings (#3120)
*  NachoSoto: `Paywalls`: reference test snapshots from submodule (#3115)
*  NachoSoto: `Paywalls`: removed `presentedPaywallViewMode` (#3109)
*  NachoSoto: `Paywalls`: remove duplicate `RevenueCat` scheme to fix Carthage (#3105)
*  NachoSoto: `Paywalls`: fixed iOS 12 build (#3104)
*  NachoSoto: `Paywalls`: fixed template 2 inconsistent spacing (#3091)
*  NachoSoto: `Paywalls`: improved test custom paywall (#3089)
*  NachoSoto: `Paywalls`: avoid warming up cache multiple times (#3068)
*  NachoSoto: `Paywalls`: added all localization (#3080)
*  NachoSoto: `Paywalls`: temporarily disable `PaywallTemplate.template4` (#3088)
*  NachoSoto: `Paywalls`: enabled `Catalyst` support (#3087)
*  NachoSoto: `Paywalls`: iPad polish (#3061)
*  NachoSoto: `Paywalls`: added MIT license to all headers (#3084)
*  NachoSoto: `Paywalls`: improved unselected package background color (#3079)
*  NachoSoto: `Paywalls`: handle already purchased state (#3046)
*  NachoSoto: `Paywalls`: only dismiss `PaywallView` when explicitly presenting it with `.presentPaywallIfNeeded` (#3075)
*  NachoSoto: `Paywalls`: add support for generating snapshots on CI (#3055)
*  NachoSoto: `Paywalls`: removed unnecessary `PaywallFooterView` (#3064)
*  Josh Holtz: `Paywalls`: new `PaywallFooterView` to replace `modes` (#3051)
*  Josh Holtz: `Paywalls`: rename card to footer (#3049)
*  NachoSoto: `Paywalls`: changed `total_price_and_per_month` to include period (#3044)
*  NachoSoto: `Paywalls`: internal documentation for implementing templates (#3053)
*  NachoSoto: `Paywalls`: finished `iOS 15` support (#3043)
*  NachoSoto: `Paywalls`: validate `PaywallData` to ensure displayed data is always correct (#3019)
*  NachoSoto: `Paywalls`: fixed `total_price_and_per_month` for custom monthly packages (#3027)
*  NachoSoto: `Paywalls`: tweaking colors on template 2&3 (#3011)
*  NachoSoto: `Paywalls`: changed snapshots to scale 1 (#3016)
*  NachoSoto: `Paywalls`: replaced `defaultLocale` with `preferredLocales` (#3003)
*  NachoSoto: `Paywalls`: improved `PaywallDisplayMode.condensedCard` layout (#3001)
*  NachoSoto: `Paywalls`: `.card` and `.condensedCard` modes (#2995)
*  NachoSoto: `Paywalls`: prevent multiple concurrent purchases (#2991)
*  NachoSoto: `Paywalls`: improved variable warning (#2984)
*  NachoSoto: `Paywalls`: fixed horizontal padding on template 1 (#2987)
*  NachoSoto: `Paywalls`: changed `FooterView` to always use `text1` color (#2992)
*  NachoSoto: `Paywalls`: retry test failures (#2985)
*  NachoSoto: `Paywalls`: send presented `PaywallViewMode` with purchases (#2859)
*  NachoSoto: `Paywalls`: added support for custom fonts (#2988)
*  NachoSoto: `Paywalls`: improved template 2 unselected packages (#2982)
*  Josh Holtz: `Paywalls`: fix template 2 selected text offer details color (#2975)
*  NachoSoto: `Paywalls`: warm-up image cache (#2978)
*  NachoSoto: `Paywalls`: extracted `PaywallCacheWarming` (#2977)
*  NachoSoto: `Paywalls`: fixed color in template 3 (#2980)
*  NachoSoto: `Paywalls`: improved default template (#2973)
*  NachoSoto: `Paywalls`: added links to documentation (#2974)
*  NachoSoto: `Paywalls`: updated template names (#2971)
*  NachoSoto: `Paywalls`: updated variable names (#2970)
*  NachoSoto: `Paywalls`: added JSON debug screen to `debugRevenueCatOverlay` (#2972)
*  NachoSoto: `Paywalls`: multi-package horizontal template  (#2949)
*  NachoSoto: `Paywalls`: fixed template 3 icon aspect ratio (#2969)
*  NachoSoto: `Paywalls`: iOS 17 tests on CI (#2955)
*  NachoSoto: `Paywalls`: deploy `debug` sample app (#2966)
*  NachoSoto: `Paywalls`: sort offerings list in sample app (#2965)
*  NachoSoto: `Paywalls`: initial iOS 15 support (#2933)
*  NachoSoto: `Paywalls`: changed default `PaywallData` to display available packages (#2964)
*  NachoSoto: `Paywalls`: changed `offerDetails` to be optional (#2963)
*  NachoSoto: `Paywalls`: markdown support (#2961)
*  NachoSoto: `Paywalls`: updated icon set to match frontend (#2962)
*  NachoSoto: `Paywalls`: added support for `PackageType.custom` (#2959)
*  NachoSoto: `Paywalls`: fixed `tvOS` compilation by making it explicitly unavailable (#2956)
*  NachoSoto: `Paywalls`: fix crash when computing localization with duplicate packages (#2958)
*  NachoSoto: `Paywalls`: UIKit `PaywallViewController` (#2934)
*  NachoSoto: `Paywalls`: `presentPaywallIfNecessary` -> `presentPaywallIfNeeded` (#2953)
*  NachoSoto: `Paywalls`: added support for custom and lifetime products (#2941)
*  NachoSoto: `Paywalls`: changed `SamplePaywallsList` to work offline (#2937)
*  NachoSoto: `Paywalls`: fixed header image mask on first template (#2936)
*  NachoSoto: `Paywalls`: new `subscription_duration` variable (#2942)
*  NachoSoto: `Paywalls`: removed `mode` parameter from `presentPaywallIfNecessary` (#2940)
*  NachoSoto: `Paywalls`: improved `RemoteImage` error layout (#2939)
*  NachoSoto: `Paywalls`: added default close button when using `presentPaywallIfNecessary` (#2935)
*  NachoSoto: `Paywalls`: added ability to preview templates in a `.sheet` (#2938)
*  NachoSoto: `Paywalls`: avoid recomputing variable `Regex` (#2944)
*  NachoSoto: `Paywalls`: improved `FooterView` scaling (#2948)
*  NachoSoto: `Paywalls`: added ability to calculate and localize subscription discounts (#2943)
*  NachoSoto: `Offering`: improved description (#2912)
*  NachoSoto: `Paywalls`: fixed `FooterView` color in template 1 (#2951)
*  NachoSoto: `Paywalls`: fixed `View.scrollableIfNecessary` (#2947)
*  NachoSoto: `Paywalls`: improved `IntroEligibilityStateView` to avoid layout changes (#2946)
*  NachoSoto: `Paywalls`: updated offerings snapshot with new asset base URL (#2950)
*  NachoSoto: `Paywalls`: extracted `TemplateBackgroundImageView` (#2945)
*  NachoSoto: `Paywalls`: more polish from design feedback (#2932)
*  NachoSoto: `Paywalls`: more unit tests for purchasing state (#2931)
*  NachoSoto: `Paywalls`: new `.onPurchaseCompleted` modifier (#2930)
*  NachoSoto: `Paywalls`: fixed `LoadingPaywallView` displaying a progress view (#2929)
*  NachoSoto: `Paywalls`: added default template to `SamplePaywallsList` (#2928)
*  NachoSoto: `Paywalls`: added a few more logs (#2927)
*  NachoSoto: `Paywalls` added individual previews for templates (#2924)
*  NachoSoto: `Paywalls`: improved default paywall configuration (#2926)
*  NachoSoto: `Paywalls`: moved purchasing state to `PurchaseHandler` (#2923)
*  NachoSoto: `Paywalls`: updated Integration Test snapshot (#2921)
*  NachoSoto: `Paywalls`: pre-warm intro eligibility in background thread (#2925)
*  NachoSoto: `Paywalls`: removed "couldn't find package" log (#2922)
*  NachoSoto: `Paywalls`: SimpleApp reads API key from Xcode Cloud environment (#2919)
*  NachoSoto: `Paywalls`: improved template accessibility support (#2920)
*  NachoSoto: `Paywalls`: work around SwiftUI bug to allow embedding `PaywallView` inside `NavigationStack` (#2918)
*  NachoSoto: `Paywalls`: some basic polish from design feedback (#2917)
*  NachoSoto: `Paywalls`: added `OfferingsList` to preview all paywalls (#2916)
*  NachoSoto: `Paywalls`: fixed tappable area for a couple of buttons (#2915)
*  NachoSoto: `Paywalls`: new `text1` and `text2` colors (#2903)
*  NachoSoto: `Paywalls`: updated multi-package bold template design (#2908)
*  NachoSoto: `Paywalls`: added sample paywalls to `SimpleApp` (#2907)
*  NachoSoto: `Paywalls`: one package with features template (#2902)
*  NachoSoto: `Paywalls`: initial support for icons (#2882)
*  NachoSoto: `Paywalls`: extracted intro eligibility out of templates (#2901)
*  NachoSoto: `Paywalls`: changed `subtitle` to be optional (#2900)
*  NachoSoto: `Paywalls`: added "features" to `LocalizedConfiguration` (#2899)
*  NachoSoto: `Paywalls`: fixed `{{ total_price_and_per_month }}` (#2881)
*  NachoSoto: `Paywalls`: updated template names (#2878)
*  NachoSoto: `Paywalls`: added accent colors (#2883)
*  NachoSoto: `Paywalls`: changed images representation to an object (#2875)
*  NachoSoto: `Paywalls`: added `offerName` parameter (#2877)
*  NachoSoto: `Paywalls`: new `{{ period }}` variable (#2876)
*  NachoSoto: `Paywalls`: disabled `PaywallViewMode`s for now (#2874)
*  NachoSoto: `Paywalls`: added new `defaultPackage` configuration (#2871)
*  NachoSoto: `Paywalls`: fixed tests on CI (#2872)
*  NachoSoto: `Paywalls`: pre-fetch intro eligibility for paywalls (#2860)
*  Andy Boedo: `Paywalls`: clean up the error view (#2873)
*  NachoSoto: `Paywalls`: new API for easily displaying `PaywallView` with just one line (#2869)
*  NachoSoto: `Paywalls`: handle missing paywalls gracefully (#2855)
*  NachoSoto: `Paywalls`: temporarily disable non-fullscreen `PaywallView`s (#2868)
*  NachoSoto: `Paywalls`: added test to ensure package selection maintains order (#2853)
*  NachoSoto: `Paywalls`: added new `blurredBackgroundImage` configuration (#2852)
*  NachoSoto: `Paywalls`: fuzzy `Locale` lookups (#2847)
*  NachoSoto: `Paywalls`: basic localization support (#2851)
*  NachoSoto: `Paywalls`: added `FooterView` (#2850)
*  NachoSoto: `Paywalls`: multi-package template (#2840)
*  NachoSoto: `Paywalls`: disable animations during unit tests (#2848)
*  NachoSoto: `Paywalls`: `TrialOrIntroEligibilityChecker.eligibility(for packages:)` (#2846)
*  NachoSoto: `Paywalls`: added new `total_price_and_per_month` variable (#2845)
*  NachoSoto: `Paywalls`: extracted `PurchaseButton` (#2839)
*  NachoSoto: `Paywalls`: extracted `IntroEligibilityStateView` (#2837)
*  NachoSoto: `Paywalls`: support for multiple `PaywallViewMode`s (#2834)
*  NachoSoto: `Paywalls`: add support for multiple images in template configuration (#2832)
*  NachoSoto: `Paywalls`: extracted configuration processing into a new `TemplateViewConfiguration` (#2830)
*  NachoSoto: `Paywalls`: improved support for dynamic type with snapshots (#2827)
*  NachoSoto: `Paywalls`: disable `macOS`/`macCatalyst`/`watchOS` for now (#2821)
*  NachoSoto: `Paywalls`: using new color information in template (#2823)
*  NachoSoto: `Paywalls`: set up CI tests and API Tester (#2816)
*  NachoSoto: `Paywalls`: added support for decoding colors (#2822)
*  NachoSoto: `Paywalls`: ignore empty strings in `LocalizedConfiguration` (#2818)
*  NachoSoto: `Paywalls`: updated `PaywallData` field names (#2817)
*  NachoSoto: `Paywalls`: added support for purchasing (#2812)
*  NachoSoto: `Paywalls`: added tests for `PackageType` filtering (#2810)
*  Andy Boedo: `Paywalls`: changed variable handling to use Swift `Regex` (#2811)
*  NachoSoto: `Paywalls`: added `price` variable (#2809)
*  NachoSoto: `Paywalls`: determine intro eligibility (#2808)
*  NachoSoto: `Paywalls`: added header image to configuration (#2800)
*  NachoSoto: `Paywalls`: added `packages` to configuration (#2798)
*  NachoSoto: `Paywalls`: add support for displaying `StoreProductDiscount`s (#2796)
*  NachoSoto: `Paywalls`: added support for variables (#2793)
*  NachoSoto: `Paywalls`: using `PaywallData` and setting up basic template loading (#2781)
*  NachoSoto: `Paywalls`: initial configuration types (#2780)
*  NachoSoto: `Paywalls`: initial `RevenueCatUI` target setup (#2776)

</details>

### Other Changes

* `Debug`: add `Offering` metadata to debug screen (#3137) via NachoSoto (@NachoSoto)
* `TestStoreProduct`: new `locale` parameter (#3134) via NachoSoto (@NachoSoto)
* `Integration Tests`: fixed more flaky failures (#3218) via NachoSoto (@NachoSoto)

## 4.25.10
### Bugfixes
* Fix runtime crash in SK2TransactionListener in iOS < 15 (#3206) via Toni Rico (@tonidero)
### Performance Improvements
* `OperationDispatcher`: add support for "long" delays (#3168) via NachoSoto (@NachoSoto)
### Other Changes
* `Integration Tests`: add tests for ghost transfer behavior (#3135) via NachoSoto (@NachoSoto)
* `Xcode`: removed `purchases-ios` SPM reference (#3166) via NachoSoto (@NachoSoto)
* `Integration Tests`: another flaky failure (#3165) via NachoSoto (@NachoSoto)
* `Integration Tests`: fix flaky test failure due to leftover transaction (#3167) via NachoSoto (@NachoSoto)
* `Xcode 13`: removed last `Swift 5.7`  checks (#3161) via NachoSoto (@NachoSoto)
* `Integration Tests`: improve flaky tests (#3163) via NachoSoto (@NachoSoto)
* `Codable`: improved decoding errors (#3153) via NachoSoto (@NachoSoto)
* Refactor: extract `HealthOperation` (#3154) via NachoSoto (@NachoSoto)
* `Xcode 13`: remove conditional code (#3147) via NachoSoto (@NachoSoto)
* `CircleCI`: change all jobs to use `Xcode 14.x` and replace `xcode-install` with `xcodes` (#2421) via NachoSoto (@NachoSoto)

## 4.25.9
### Bugfixes
* `DebugViewModel`: fixed runtime crash on iOS < 16 (#3139) via NachoSoto (@NachoSoto)
### Performance Improvements
* `PurchasesOrchestrator`: return early if receipt has no transactions when checking for promo offers (#3123) via Mark Villacampa (@MarkVillacampa)
* `Purchases`: don't clear intro eligibility / purchased products cache on first launch (#3067) via NachoSoto (@NachoSoto)
### Dependency Updates
* `SPM`: update `Package.resolved` (#3130) via NachoSoto (@NachoSoto)
### Other Changes
* `ReceiptParser`: fixed SPM build (#3144) via NachoSoto (@NachoSoto)
* `carthage_installation_tests`: optimize SPM package loading (#3129) via NachoSoto (@NachoSoto)
* `CI`: add workaround for `Carthage` timing out (#3119) via NachoSoto (@NachoSoto)
* `Integration Tests`: workaround to not lose debug logs (#3108) via NachoSoto (@NachoSoto)

## 4.25.8
### Dependency Updates
* Bump fastlane-plugin-revenuecat_internal from `b2108fb` to `a297205` (#3106) via dependabot[bot] (@dependabot[bot])
* Bump activesupport from 7.0.4.3 to 7.0.7.2 in /Tests/InstallationTests/CocoapodsInstallation (#3071) via dependabot[bot] (@dependabot[bot])
* Bump activesupport from 7.0.4.3 to 7.0.7.2 (#3070) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `Integration Tests`: fixed another flaky test (#3111) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: enable `restorePurchases` in public API (#3090) via NachoSoto (@NachoSoto)
* `CustomerInfo`: add `VerificationResult` to `description` (#3081) via NachoSoto (@NachoSoto)
* `Integration Tests`: fixed race condition in flaky test (#3086) via NachoSoto (@NachoSoto)

## 4.25.7
### Other Changes
* `Integration Tests`: test that `checkTrialOrIntroDiscountEligibility` makes no API requests (#3054) via NachoSoto (@NachoSoto)
* `visionOS`: changed CI job to Release (#3042) via NachoSoto (@NachoSoto)
* `StoreKit 2`: added warning to paywall constructors (#3045) via NachoSoto (@NachoSoto)
* `README`: added `visionOS` to list of supported platforms (#3052) via NachoSoto (@NachoSoto)
* `Tests`: added tests for `ClockType` (#3029) via NachoSoto (@NachoSoto)
* `HTTPClient`: also parse errors with `application/json;charset=utf8` (#3041) via NachoSoto (@NachoSoto)

## 4.25.6
### Bugfixes
* `Xcode 15`: fixed release build (#3034) via NachoSoto (@NachoSoto)

## 4.25.5
### Bugfixes
* `PurchasesOrchestrator`: fixed callback not invoked regression during downgrades (#3028) via NachoSoto (@NachoSoto)
* `TransactionPoster`: don't finish transactions for non-subscriptions if they're not processed (#2841) via NachoSoto (@NachoSoto)
### Performance Improvements
* `StoreKit 2`: only listen to `StoreKit.Transaction.updates` when SK2 is enabled (#3032) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`: post transactions in parallel to POST receipts only once (#2954) via NachoSoto (@NachoSoto)
### Other Changes
* `PostedTransactionCache`: remove implementation (#3030) via NachoSoto (@NachoSoto)
* `Integration Tests`: improved `testCanPurchaseMultipleSubscriptions` (#3025) via NachoSoto (@NachoSoto)
* `GitHub`: improved `ISSUE_TEMPLATE` (#3022) via NachoSoto (@NachoSoto)
* `TransactionPoster`: added transaction ID and Date to log (#3026) via NachoSoto (@NachoSoto)
* `TransactionPoster`: fix iOS 12 test (#3018) via NachoSoto (@NachoSoto)
* `SystemInfo`: added `ClockType` (#3014) via NachoSoto (@NachoSoto)
* `Integration Tests`: begin tests with `UIApplication.willEnterForegroundNotification` to simulate a real app (#3015) via NachoSoto (@NachoSoto)
* `Integration Tests`: add tests to verify `CustomerInfo`+`Offerings` request de-dupping (#3013) via NachoSoto (@NachoSoto)
* `SwiftLint`: disable `unneeded_synthesized_initializer` (#3010) via NachoSoto (@NachoSoto)
* Added `internal` `NonSubscriptionTransaction.storeTransactionIdentifier` (#3009) via NachoSoto (@NachoSoto)
* `Integration Tests`: added tests for non-renewing and non-consumable packages (#3008) via NachoSoto (@NachoSoto)
* Expanded `EnsureNonEmptyArrayDecodable` to `EnsureNonEmptyCollectionDecodable` (#3002) via NachoSoto (@NachoSoto)

## 4.25.4
_This release is compatible with Xcode 15 beta 6 and visionOS beta 3_

### Bugfixes
* `Xcode 15`: fix non-`visionOS` build by replacing `.custom` platform (#3005) via NachoSoto (@NachoSoto)
### Other Changes
* `Integration Tests`: test for `SignatureVerificationMode.informational` and receipt posting when fetching `CustomerInfo` (#3000) via NachoSoto (@NachoSoto)
* `Custom Entitlement Computation`: fixed `visionOS` build (#2999) via NachoSoto (@NachoSoto)
* `HTTPClient`: extracted `HTTPRequestPath` protocol (#2986) via NachoSoto (@NachoSoto)
* `CI`: add `visionOS` build (#2990) via NachoSoto (@NachoSoto)

## 4.25.3
_This release is compatible with Xcode 15 beta 6 and visionOS beta 3_

### Bugfixes
* `visionOS`: support for `Xcode 15 beta 6` (#2989) via NachoSoto (@NachoSoto)
* `CachingProductsManager`: avoid crash when caching different products with same identifier (#2979) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: disambiguate transactions from the queue (#2890) via NachoSoto (@NachoSoto)
### Performance Improvements
* `StoreKit2TransactionListener`: handle transactions asynchronously (#2910) via NachoSoto (@NachoSoto)
### Other Changes
* `Atomic`: avoid race conditions modifying dictionaries (#2981) via NachoSoto (@NachoSoto)
* `Logging`: avoid logging "updating offerings" when request is cached (#2904) via NachoSoto (@NachoSoto)
* `StoreKit2TransactionListener`: converted into an `actor` (#2909) via NachoSoto (@NachoSoto)
* `Integration Tests`: added more observer mode tests (#2905) via NachoSoto (@NachoSoto)
* Created `PostedTransactionCache` (#2911) via NachoSoto (@NachoSoto)
* `IntroEligibility`: changed products to `Set<String>` (#2976) via NachoSoto (@NachoSoto)
* `AdServices`: Rename `postAdServicesTokenIfNeeded()` to `postAdServicesTokenOncePerInstallIfNeeded()` (#2968) via Josh Holtz (@joshdholtz)
* `SK1StoreProduct`: changed `productType` warning to debug (#2957) via NachoSoto (@NachoSoto)
* `PrivacyInfo.xcprivacy`: added `UserDefaults` to access API types (#2913) via NachoSoto (@NachoSoto)
* `Integration Tests`: new test to verify that SK1 purchases don't leave SK2 unfinished transactions (#2906) via NachoSoto (@NachoSoto)
* `Logging`: log entire cache key with verbose logs (#2888) via NachoSoto (@NachoSoto)
* `StoreProduct`: added test covering warning log (#2897) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: use custom API key (#2879) via Toni Rico (@tonidero)
* `CachingProductsManager`: removed duplicate log and added tests (#2898) via NachoSoto (@NachoSoto)
* `Xcode 15 beta 5`: fixed test compilation (#2885) via NachoSoto (@NachoSoto)

## 4.25.2
_This release is compatible with Xcode 15 beta 5 and visionOS beta 2_

### Bugfixes
* `xrOS`: fixed `SubscriptionStoreView` for visionOS beta 2 (#2884) via Josh Holtz (@joshdholtz)
### Performance Improvements
* `Perf`: update `CustomerInfo` cache before anything else (#2865) via NachoSoto (@NachoSoto)
### Other Changes
* `SimpleApp`: added support for localization (#2880) via NachoSoto (@NachoSoto)
* `TestStoreProduct`: made available on release builds (#2861) via NachoSoto (@NachoSoto)
* `Tests`: increased default logger capacity (#2870) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: removed `invalidateCustomerInfoCache` (#2866) via NachoSoto (@NachoSoto)
* `SimpleApp`: updates for TestFlight compatibility (#2862) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: consolidate to only initialize one `DeviceCache` (#2863) via NachoSoto (@NachoSoto)
* `Codable`: debug log entire JSON when decoding fails (#2864) via NachoSoto (@NachoSoto)
* `IntegrationTests`: replaced `Purchases.shared` with a `throw`ing property (#2867) via NachoSoto (@NachoSoto)
* `NetworkError`: 2 new tests to ensure underlying error is included in description (#2843) via NachoSoto (@NachoSoto)
* Add SPM `Package.resolved` for Xcode Cloud (#2844) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: added integration test for cancellations (#2849) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: removed `syncPurchases`/`restorePurchases` (#2854) via NachoSoto (@NachoSoto)

## 4.25.1
### Dependency Updates
* Bump fastlane from 2.213.0 to 2.214.0 (#2824) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `MainThreadMonitor`: don't crash if there is no test in progress (#2838) via NachoSoto (@NachoSoto)
* `CI`: fixed Fastlane APITester lanes (#2836) via NachoSoto (@NachoSoto)
* `Integration Tests`: workaround Swift runtime crash (#2826) via NachoSoto (@NachoSoto)
* `@EnsureNonEmptyArrayDecodable` (#2831) via NachoSoto (@NachoSoto)
* `iOS 17`: added tests for simulating cancellations (#2597) via NachoSoto (@NachoSoto)
* `CI`: make all `Codecov` jobs `informational` (#2828) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: check deadlocks only ever N seconds (#2820) via NachoSoto (@NachoSoto)
* New `@NonEmptyStringDecodable` (#2819) via NachoSoto (@NachoSoto)
* `MockDeviceCache`: avoid using real `UserDefaults` (#2814) via NachoSoto (@NachoSoto)
* `throwAssertion`: fixed Xcode 15 compilation (#2813) via NachoSoto (@NachoSoto)
* `CustomEntitlementsComputation`: fixed API testers (#2815) via NachoSoto (@NachoSoto)
* `PackageTypeTests`: fixed iOS 12 (#2807) via NachoSoto (@NachoSoto)
* `Tests`: avoid race-condition in leak detection (#2806) via NachoSoto (@NachoSoto)
* Revert "`Unit Tests`: removed leak detection" (#2805) via NachoSoto (@NachoSoto)
* `PackageType: Codable` implementation (#2797) via NachoSoto (@NachoSoto)
* `SystemInfo.init` no longer `throws` (#2803) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: add support for signing `POST` body (#2753) via NachoSoto (@NachoSoto)
* `Tests`: unified default timeouts (#2801) via NachoSoto (@NachoSoto)
* `Tests`: removed forced-unwrap (#2799) via NachoSoto (@NachoSoto)
* `Tests`: added missing `super.setUp()` (#2804) via NachoSoto (@NachoSoto)
* Replaced `FatalErrorUtil` with `Nimble` (#2802) via NachoSoto (@NachoSoto)
* `Tests`: fixed another flaky test (#2795) via NachoSoto (@NachoSoto)
* `TimingUtil`: improved tests by using `Clock` (#2794) via NachoSoto (@NachoSoto)
* `IgnoreDecodeErrors`: log decoding error (#2778) via NachoSoto (@NachoSoto)
* `TestLogHandler`: changed all tests to explicitly deinitialize it (#2784) via NachoSoto (@NachoSoto)
* `LocalReceiptParserStoreKitTests`: fixed flaky test failure (#2785) via NachoSoto (@NachoSoto)
* `Unit Tests`: removed leak detection (#2792) via NachoSoto (@NachoSoto)
* `Tests`: fixed another flaky failure with asynchronous check (#2786) via NachoSoto (@NachoSoto)

## 4.25.0
### New Features
* `Trusted Entitlements`: (#2621) via NachoSoto (@NachoSoto)

This new feature prevents MitM attacks between the SDK and the RevenueCat server.
With verification enabled, the SDK ensures that the response created by the server was not modified by a third-party, and the entitlements received are exactly what was sent.
This is 100% opt-in. `EntitlementInfos` have a new `VerificationResult` property, which will indicate the validity of the responses when this feature is enabled.

```swift
let purchases = Purchases.configure(
  with: Configuration
    .builder(withAPIKey: "")
    .with(entitlementVerificationMode: .informational)
)
let customerInfo = try await purchases.customerInfo()
if !customerInfo.entitlements.verification.isVerified {
  print("Entitlements could not be verified")
}
```

You can learn more from [the documentation](https://www.revenuecat.com/docs/trusted-entitlements).

### Other Changes
* `TrustedEntitlements`: new `VerificationResult.isVerified` (#2788) via NachoSoto (@NachoSoto)
* `Refactor`: extracted `Collection.subscript(safe:)` (#2779) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: added link to docs in `ErrorCode.signatureVerificationFailed` (#2783) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: improved documentation (#2782) via NachoSoto (@NachoSoto)
* `Tests`: fixed flaky failure with asynchronous check (#2777) via NachoSoto (@NachoSoto)
* `Integration Tests`: re-enable signature verification tests (#2744) via NachoSoto (@NachoSoto)
* `CI`: remove `Jazzy` (#2775) via NachoSoto (@NachoSoto)
* `Signing`: inject `ClockType` to ensure hardcoded signatures don't fail when intermediate key expires (#2771) via NachoSoto (@NachoSoto)

## 4.24.1
### Bugfixes
* `PurchasesDiagnostics`: don't test signature verification if it's disabled (#2757) via NachoSoto (@NachoSoto)
### Other Changes
* `AnyEncodable`: also implement `Decodable` (#2769) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: log signature errors on requests with `.informational` mode (#2751) via NachoSoto (@NachoSoto)
* `Tests`: optimized several tests (#2754) via NachoSoto (@NachoSoto)
* `SimpleApp`: allow HTTP traffic (#2763) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: added support for unauthenticated endpoints (#2761) via NachoSoto (@NachoSoto)
* `Integration Tests`: `TestLogHandler` no longer crashes tests (#2760) via NachoSoto (@NachoSoto)
* `SimpleApp`: changed bundle identifier (#2759) via NachoSoto (@NachoSoto)
* `Testing`: add new `SimpleApp` (#2756) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: update handling of escaped URLs (#2758) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: produce verification failures for static endpoints with no signature (#2752) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: added tests to verify offerings and product entitlement mapping (#2667) via NachoSoto (@NachoSoto)
* `Integration Tests`: refactored expiration detection (#2700) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: add API key and `HTTPRequest.Path` to signature (#2746) via NachoSoto (@NachoSoto)
* `HTTPRequest.Path`: escape `appUserID` (#2747) via NachoSoto (@NachoSoto)
* `Documentation`: add reference to `TestStoreProduct` (#2743) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: add new `testReceiptIdentifier` parameter (#2749) via NachoSoto (@NachoSoto)
* `Integration Tests`: updated load-shedder offerings snapshot (#2748) via NachoSoto (@NachoSoto)
* `Signing`: extract and verify intermediate key (#2715) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: update handling of 304 responses (#2698) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: new Signature format (#2679) via NachoSoto (@NachoSoto)
* `Integration Tests`: avoid crashes when stopping tests early (#2741) via NachoSoto (@NachoSoto)

## 4.24.0
### New Features
* New `TestStoreProduct` for creating mock `StoreProduct`s and `Offering`s (#2711) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump fastlane-plugin-revenuecat_internal from `13773d2` to `b2108fb` (#2706) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `VerificationResult: CustomDebugStringConvertible` (#2739) via NachoSoto (@NachoSoto)
* Refactor: simplified `PurchasesOrchestrator.syncPurchases` (#2731) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: add integration tests to verify `CustomerInfo` cache invalidation (#2730) via NachoSoto (@NachoSoto)
* `SystemInfo.identifierForVendor`: add tests (#2732) via NachoSoto (@NachoSoto)
* `Tests`: disabled `iOS 11.x` tests to fix `Xcode 15` tests (#2720) via NachoSoto (@NachoSoto)
* `DebugViewSwiftUITests`: create separate snapshots for each OS version (#2721) via NachoSoto (@NachoSoto)
* `Integration Tests`: fix clearing `UserDefaults` before each test (#2719) via NachoSoto (@NachoSoto)
* Remove unused `Signing.loadPublicKey(with:)` (#2714) via NachoSoto (@NachoSoto)
* Add `UInt32(littleEndian32Bits:)` and `UInt32.littleEndianData` (#2713) via NachoSoto (@NachoSoto)
* `TimingUtil`: added synchronous API (#2716) via NachoSoto (@NachoSoto)
* `XCFramework`: sign archive for `Xcode 15` (#2709) via NachoSoto (@NachoSoto)
* `CI`: removed `carthage_archive` from `release` lane (#2710) via NachoSoto (@NachoSoto)
* `PriceFormatterProvider.priceFormatterForSK2`: enable on all versions (#2712) via NachoSoto (@NachoSoto)
* `xrOS`: add support for `debugRevenueCatOverlay` (#2702) via NachoSoto (@NachoSoto)
* Refactor method to get product ID including plan ID in android purchases (#2708) via Toni Rico (@tonidero)
* `Purchases.restoreLogHandler` (#2699) via NachoSoto (@NachoSoto)
* Remove alpha from purchase tester icon to upload to testflight (#2705) via Toni Rico (@tonidero)

## 4.23.1
### Bugfixes
* Fix google play purchases missing purchase date (#2703) via Toni Rico (@tonidero)
### Other Changes
* `PurchaseTester`: fixed `watchOS` build and ASC deployment (#2701) via NachoSoto (@NachoSoto)
* Add `Data.sha1` (#2696) via NachoSoto (@NachoSoto)
* Refactor: extract `ErrorResponse` into its own file (#2697) via NachoSoto (@NachoSoto)
* Add `Sequence<AdditiveArithmetic>.sum()` (#2694) via NachoSoto (@NachoSoto)
* Refactored `Data.asString` implementation (#2695) via NachoSoto (@NachoSoto)
* `Diagnostics`: new `FileHandler` for abstracting file operations (#2673) via NachoSoto (@NachoSoto)

## 4.23.0
### New Features
* `xrOS`: added to list of supported platforms (#2682) via NachoSoto (@NachoSoto)
### Bugfixes
* `xrOS`: fixed compilation by disabling debug overlay (#2681) via NachoSoto (@NachoSoto)
* `xrOS`: added support for new `purchase(confirmIn:options:)` method (#2683) via NachoSoto (@NachoSoto)
* `Xcode 15`: handle `Locale.currencyCode` deprecation (#2680) via NachoSoto (@NachoSoto)
### Other Changes
* `PurchaseTester`: fixed release compilation (#2689) via NachoSoto (@NachoSoto)
* `xrOS`: fixed runtime warning (#2691) via NachoSoto (@NachoSoto)
* `xrOS`: added support to `PurchaseTester` (#2685) via NachoSoto (@NachoSoto)
* `Signature Verification`: new `Integration Tests` (#2642) via NachoSoto (@NachoSoto)
* `ErrorUtils`: handle `PurchasesError` to avoid creating unknown errors (#2686) via NachoSoto (@NachoSoto)

## 4.22.1
### Bugfixes
* `PurchasesOrchestrator`: update `CustomerInfoManager` cache after processing transactions (#2676) via NachoSoto (@NachoSoto)
* `ErrorResponse`: drastically improved error messages, no more "unknown error"s (#2660) via NachoSoto (@NachoSoto)
* `PaywallExtensions`: post purchases with `Offering` identifier (#2645) via NachoSoto (@NachoSoto)
* Support `product_plan_identifier` for purchased subscriptions from `Google Play` (#2654) via Josh Holtz (@joshdholtz)
### Performance Improvements
* `copy(with: VerificationResult)`: optimization to avoid copies (#2639) via NachoSoto (@NachoSoto)
### Other Changes
* `ETagManager`: refactored e-tag creation and tests (#2671) via NachoSoto (@NachoSoto)
* `getPromotionalOffer`: return `ErrorCode.ineligibleError` if receipt is not found (#2678) via NachoSoto (@NachoSoto)
* `TimingUtil`: removed slow purchase logs (#2677) via NachoSoto (@NachoSoto)
* `CI`: changed `Codecov` to `informational` (#2670) via NachoSoto (@NachoSoto)
* `LoadShedderIntegrationTests`: verify requests are actually handled by load shedder (#2663) via NachoSoto (@NachoSoto)
* `ETagManager.httpResultFromCacheOrBackend`: return response headers (#2666) via NachoSoto (@NachoSoto)
* `Integration Tests`: added tests to verify 304 behavior (#2659) via NachoSoto (@NachoSoto)
* `HTTPClient`: disable `URLSession` cache (#2668) via NachoSoto (@NachoSoto)
* Documented `HTTPStatusCode.isSuccessfullySynced` (#2661) via NachoSoto (@NachoSoto)
* `NetworkError.signatureVerificationFailed`: added status code to error `userInfo` (#2657) via NachoSoto (@NachoSoto)
* `HTTPClient`: improved log for failed requests (#2669) via NachoSoto (@NachoSoto)
* `ETagManager`: added new verbose logs (#2656) via NachoSoto (@NachoSoto)
* `Signature Verification`: added test-only log for debugging invalid signatures (#2658) via NachoSoto (@NachoSoto)
* Fixed `HTTPResponse.description` (#2664) via NachoSoto (@NachoSoto)
* Changed `Logger` to use `os_log` (#2608) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: increased threshold (#2662) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: display `receiptURL` (#2652) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added ability to display `debugRevenueCatOverlay` (#2653) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: ability to close on `macOS`/`Catalyst` (#2649) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: added support for `macOS` (#2648) via NachoSoto (@NachoSoto)
* `LoadShedderIntegrationTests`: enable signature verification (#2655) via NachoSoto (@NachoSoto)
* `ImageSnapshot`: fixed Xcode 15 compilation (#2651) via NachoSoto (@NachoSoto)
* `OfferingsManager`: don't clear offerings cache timestamp when request fails (#2359) via NachoSoto (@NachoSoto)
* `StoreKitObserverModeIntegrationTests`: added test for posting renewals (#2590) via NachoSoto (@NachoSoto)
* Always initialize `StoreKit2TransactionListener` even on SK1 mode (#2612) via NachoSoto (@NachoSoto)
* `ErrorUtils.missingReceiptFileError`: added receipt URL `userInfo` context (#2650) via NachoSoto (@NachoSoto)
* Added `.xcprivacy` for Xcode 15 (#2619) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: added debug log with `ResponseVerificationMode` (#2647) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: simplified title (#2641) via NachoSoto (@NachoSoto)
* Simplified `Purchases.updateAllCachesIfNeeded` (#2626) via NachoSoto (@NachoSoto)
* `HTTPResponseTests`: fixed disabled test (#2643) via NachoSoto (@NachoSoto)
* Add `InternalDangerousSettings.forceSignatureFailures` (#2635) via NachoSoto (@NachoSoto)
* `IntegrationTests`: explicit `StoreKit 1` mode (#2636) via NachoSoto (@NachoSoto)
* `Signing`: removed API for loading key from a file (#2638) via NachoSoto (@NachoSoto)

## 4.22.0
### New Features
* New `DebugViewController`: UIKit counterpart for SwiftUI's `debugRevenueCatOverlay` (#2631) via NachoSoto (@NachoSoto)
* Created `PaywallExtensions`: `StoreView` and `SubscriptionStoreView` overloads for `Offering` (#2593) via NachoSoto (@NachoSoto)
* Introduced `debugRevenueCatOverlay()`: new SwiftUI debug overlay (#2567) via NachoSoto (@NachoSoto)
### Bugfixes
* Removed `preventPurchasePopupCallFromTriggeringCacheRefresh`, update caches on `willEnterForeground` (#2623) via NachoSoto (@NachoSoto)
* Fixed `Catalyst` build with `Xcode 15 beta 1` (#2586) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump danger from 9.3.0 to 9.3.1 (#2592) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `StoreTransaction`: added new `Storefront` to API testers (#2634) via NachoSoto (@NachoSoto)
* `DebugView`: added snapshot tests (#2630) via NachoSoto (@NachoSoto)
* `verifyNoUnfinishedTransactions`/`verifyUnfinishedTransaction`: added missing `#file` parameter (#2625) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: clean up cache key (#2628) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: also get `Storefront` from SK1 (#2629) via NachoSoto (@NachoSoto)
* `CI`: disable iOS 17 for now (#2627) via NachoSoto (@NachoSoto)
* `Tests`: fixed crash on iOS 13 (#2624) via NachoSoto (@NachoSoto)
* `StoreTransaction`: read `Storefront` from `StoreKit.Transaction` (#2611) via NachoSoto (@NachoSoto)
* `StoreKitConfigTestCase`/`BaseStoreKitIntegrationTests`: also clear transactions after every test (#2616) via NachoSoto (@NachoSoto)
* `ErrorCode.networkError`: improved description (#2610) via NachoSoto (@NachoSoto)
* `PurchaseTester`: make CI job always point to current version (#2622) via NachoSoto (@NachoSoto)
* Improved `finishAllUnfinishedTransactions` (#2615) via NachoSoto (@NachoSoto)
* `StoreKitConfigTestCase`: improved `waitForStoreKitTestIfNeeded` (#2614) via NachoSoto (@NachoSoto)
* `StoreKitConfigTestCase`: set `continueAfterFailure` to `false` (#2617) via NachoSoto (@NachoSoto)
* `PaywallExtensions`: fixed compilation (#2613) via NachoSoto (@NachoSoto)
* `CI`: added `iOS 17` job (#2591) via NachoSoto (@NachoSoto)
* `Encodable.jsonEncodedData`: fixed tests on iOS 17 due to inconsistent key ordering (#2607) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay`: added ability to display new `SubscriptionStoreView` (#2595) via NachoSoto (@NachoSoto)
* Refactor: extracted all log strings (#2600) via NachoSoto (@NachoSoto)
* Changed tests to work around `URL` decoding differences in `iOS 17` (#2605) via NachoSoto (@NachoSoto)
* Removed unnecessary `Strings.trimmedOrError` (#2601) via NachoSoto (@NachoSoto)
* Fixed test compilation with `Xcode 15` (#2602) via NachoSoto (@NachoSoto)
* Tests: added `iOS 17` snapshots (#2603) via NachoSoto (@NachoSoto)
* `StoreProductDiscount`: added `description` (#2604) via NachoSoto (@NachoSoto)
* `debugRevenueCatOverlay` improvements (#2594) via NachoSoto (@NachoSoto)
* `Xcode 15`: fixed all documentation warnings (#2596) via NachoSoto (@NachoSoto)
* `StoreKitObserverModeIntegrationTests`: fixed and disabled SK2 `testPurchaseInDevicePostsReceipt` (#2589) via NachoSoto (@NachoSoto)
* `StoreKit2TransactionListener`: added log when receiving `Transactions.Updates` (#2588) via NachoSoto (@NachoSoto)
* `Dictionary.MergeStrategy`: simplify implementation (#2587) via NachoSoto (@NachoSoto)
* `Configuration.Builder`: fixed doc reference (#2583) via NachoSoto (@NachoSoto)
* `APITesters`: available since iOS 11 (#2581) via NachoSoto (@NachoSoto)

## 4.21.1
_This release is compatible with Xcode 15 beta 1_

### Bugfixes
* `Dictionary.MergeStrategy`: fixed Xcode 15 compilation (#2582) via NachoSoto (@NachoSoto)
### Other Changes
* `Custom Entitlements Computation`: added missing scheme to project (#2579) via NachoSoto (@NachoSoto)
* `Custom Entitlements Computation`: added Integration Tests (#2568) via NachoSoto (@NachoSoto)
* `ProductsManager`: improved display of underlying errors (#2575) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added debug log for duplicate `finishTransaction` calls (#2577) via NachoSoto (@NachoSoto)
* Fixed typo in file name (#2578) via NachoSoto (@NachoSoto)
* `Integration Tests`: avoid crashes when printing receipt (#2570) via NachoSoto (@NachoSoto)
* `Package.swift` fix warning for unrecognized `Info.plist` (#2573) via NachoSoto (@NachoSoto)

## 4.21.0
### New Features
* `Offline Entitlements`: use offline-computed `CustomerInfo` when server is down (#2368) via NachoSoto (@NachoSoto)

### Bugfixes
* `AppleReceipt.debugDescription`: don't pretty-print JSON (#2564) via NachoSoto (@NachoSoto)
* `SK2StoreProduct`: fix crash on iOS 12 (#2565) via NachoSoto (@NachoSoto)
* `GetCustomerInfo` posts receipts if there are pending transactions (#2533) via NachoSoto (@NachoSoto)
### Performance Improvements
* `PurchasedProductsFetcher`: cache current entitlements (#2507) via NachoSoto (@NachoSoto)
* Performance: new check to ensure serialization / deserialization is done from background thread (#2496) via NachoSoto (@NachoSoto)
### Dependency Updates
* Bump fastlane from 2.212.2 to 2.213.0 (#2544) via dependabot[bot] (@dependabot[bot])
### Other Changes
* `CustomerInfoManager`: post all unfinished transactions (#2563) via NachoSoto (@NachoSoto)
* `PostReceiptOperation`: added ability to also post `AdServices` token (#2566) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: improved computation log (#2562) via NachoSoto (@NachoSoto)
* Added `TransactionPoster` tests (#2557) via NachoSoto (@NachoSoto)
* Refactored `TransactionPoster`: removed 2 dependencies and abstracted parameters (#2542) via NachoSoto (@NachoSoto)
* `CustomerInfoManagerTests`: wait for `getAndCacheCustomerInfo` to finish (#2555) via NachoSoto (@NachoSoto)
* `StoreTransaction`: implemented `description` (#2556) via NachoSoto (@NachoSoto)
* `Backend.ResponseHandler` is now `@Sendable` (#2541) via NachoSoto (@NachoSoto)
* Extracted `TransactionPoster` from `PurchasesOrchestrator` (#2540) via NachoSoto (@NachoSoto)
* `enableAdServicesAttributionTokenCollection`: added integration test (#2551) via NachoSoto (@NachoSoto)
* `AttributionPoster`: replaced hardcoded strings with constants (#2548) via NachoSoto (@NachoSoto)
* `DefaultDecodable`: moved to `Misc/Codable/DefaultDecodable.swift` (#2528) via NachoSoto (@NachoSoto)
* `CircleCI`: specify device to run `backend_integration_tests` (#2547) via NachoSoto (@NachoSoto)
* Created `StoreKit2TransactionFetcher` (#2539) via NachoSoto (@NachoSoto)
* Fix load shedder integration tests (#2546) via Josh Holtz (@joshdholtz)
* Fix doc on `Offering.getMetadataValue` (#2545) via Josh Holtz (@joshdholtz)
* Extracted and tested `AsyncSequence.extractValues` (#2538) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: don't compute offline `CustomerInfo` when purchasing a consumable products (#2522) via NachoSoto (@NachoSoto)
* `OfflineEntitlementsManager`: disable offline `CustomerInfo` in observer mode (#2520) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: fixed leak detection (#2534) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added `ProxyView` to `iOS` (#2531) via NachoSoto (@NachoSoto)
* `PurchasedProductsFetcher`: removed `AppStore.sync` call (#2521) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added new window on Mac to manage proxy (#2518) via NachoSoto (@NachoSoto)
* `PurchasedProductsFetcher`: added log if fetching purchased products is slow (#2515) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: disable for custom entitlements mode (#2509) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: fixed iOS 12 tests (#2514) via NachoSoto (@NachoSoto)
* `PurchasedProductsFetcher`: don't throw errors if purchased products were found (#2506) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: allow creating offline `CustomerInfo` with empty `ProductEntitlementMapping` (#2504) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: integration tests (#2501) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`: don't cache offline `CustomerInfo` (#2378) via NachoSoto (@NachoSoto)
* `DangerousSettings`: debug-only `forceServerErrors` (#2486) via NachoSoto (@NachoSoto)
* `CocoapodsInstallation`: fixed `Xcode 14.3.0` issue (#2489) via NachoSoto (@NachoSoto)
* `CarthageInstallation`: removed workaround (#2488) via NachoSoto (@NachoSoto)

## 4.20.0
### New Features
* Add `StoreProduct.pricePerYear` (#2462) via NachoSoto (@NachoSoto)

### Bugfixes
* `HTTPClient`: don't assume error responses are JSON (#2529) via NachoSoto (@NachoSoto)
* `OfferingsManager`: return `Offerings` from new disk cache when server is down (#2495) via NachoSoto (@NachoSoto)
* `OfferingsManager`: don't consider timeouts as configuration errors (#2493) via NachoSoto (@NachoSoto)

### Performance Improvements
* Perf: `CustomerInfoManager.fetchAndCacheCustomerInfoIfStale` no longer fetches data if stale (#2508) via NachoSoto (@NachoSoto)

### Other Changes
* `Integration Tests`: workaround for `XCTest` crash after a test failure (#2532) via NachoSoto (@NachoSoto)
* `CircleCI`: save test archive on `loadshedder-integration-tests` (#2530) via NachoSoto (@NachoSoto)
* `SK2StoreProduct`: simplify `currencyCode` extraction (#2485) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added visual feedback for purchase success/failure (#2519) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed macOS UI (#2516) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: fixed flakiness in CI (#2517) via NachoSoto (@NachoSoto)
* Update `fastlane-plugin-revenuecat_internal` (#2511) via Cesar de la Vega (@vegaro)
* `Xcode`: fixed `.storekit` file references in schemes (#2505) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: don't monitor thread if debugger is attached (#2502) via NachoSoto (@NachoSoto)
* `Purchases`: avoid double-log when setting `delegate` to `nil` (#2503) via NachoSoto (@NachoSoto)
* `Integration Tests`: added snapshot test for `OfferingsResponse` (#2499) via NachoSoto (@NachoSoto)
* Tests: grouped all `Matcher`s into one file (#2497) via NachoSoto (@NachoSoto)
* `DeviceCache`: refactored cache keys (#2494) via NachoSoto (@NachoSoto)
* `HTTPClient`: log actual response status code (#2487) via NachoSoto (@NachoSoto)
* Generate snapshots on CI (#2472) via Josh Holtz (@joshdholtz)
* `Integration Tests`: add `MainThreadMonitor` to ensure main thread is not blocked (#2463) via NachoSoto (@NachoSoto)
* Add message indicating tag doesn't exist (#2458) via Cesar de la Vega (@vegaro)

## 4.19.1
### Other Changes
`PostReceiptOperation`: added ability to also post `AdServices` token (#2549) via NachoSoto (@NachoSoto)

## 4.19.0
### New Features
* New `ErrorCode.signatureVerificationFailed` which will be used for an upcoming feature

### Bugfixes
* `Purchases.deinit`: don't reset `Purchases.proxyURL` (#2346) via NachoSoto (@NachoSoto)

<details>
<summary><b>Other Changes</b></summary>

* Introduced `Configuration.EntitlementVerificationMode` and `VerificationResult` (#2277) via NachoSoto (@NachoSoto)
* `PurchasesDiagnostics`: added step to verify signature verification (#2267) via NachoSoto (@NachoSoto)
* `HTTPClient`: added signature validation and introduced `ErrorCode.signatureVerificationFailed` (#2272) via NachoSoto (@NachoSoto)
* `ETagManager`: don't use ETags if response verification failed (#2347) via NachoSoto (@NachoSoto)
* `Integration Tests`: removed `@preconcurrency import` (#2464) via NachoSoto (@NachoSoto)
* Clean up: moved `ReceiptParserTests-Info.plist` out of root (#2460) via NachoSoto (@NachoSoto)
* Update `CHANGELOG` (#2461) via NachoSoto (@NachoSoto)
* Update `SwiftSnapshotTesting` (#2453) via NachoSoto (@NachoSoto)
* Fixed docs (#2432) via Kaunteya Suryawanshi (@kaunteya)
* Remove unnecessary line break (#2435) via Andy Boedo (@aboedo)
* `ProductEntitlementMapping`: enabled entitlement mapping fetching (#2425) via NachoSoto (@NachoSoto)
* `BackendPostReceiptDataTests`: increased timeout to fix flaky test (#2426) via NachoSoto (@NachoSoto)
* Updated requirements to drop Xcode 13.x support (#2419) via NachoSoto (@NachoSoto)
* `Integration Tests`: fixed flaky errors when loading offerings (#2420) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fixed compilation for `internal` entitlement verification (#2417) via NachoSoto (@NachoSoto)
* `ETagManager`/`HTTPClient`: sending new `X-RC-Last-Refresh-Time` header (#2373) via NachoSoto (@NachoSoto)
* `ETagManager`: don't send validation time if not present (#2490) via NachoSoto (@NachoSoto)
* SwiftUI Sample Project: Refactor Package terms method to a computed property (#2405) via Joseph Kokenge (@JOyo246)
* Clean up v3 load shedder integration tests (#2402) via Andy Boedo (@aboedo)
* Fix iOS 12 compilation (#2394) via NachoSoto (@NachoSoto)
* Added new `VerificationResult.verifiedOnDevice` (#2379) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fix memory leaks (#2392) via Keita Watanabe (@kitwtnb)
* Integration tests: add scheduled job (#2389) via Andy Boedo (@aboedo)
* Add lane for running iOS v3 load shedder integration tests (#2388) via Andy Boedo (@aboedo)
* iOS v3 load shedder integration tests (#2387) via Andy Boedo (@aboedo)
* `Offline Entitlements`: created `LoadShedderIntegrationTests` (#2362) via NachoSoto (@NachoSoto)
* Purchases.configure: log warning if attempting to use a static appUserID (#2385) via Mark Villacampa (@MarkVillacampa)
* `SubscriberAttributesManagerIntegrationTests`: fixed flaky failures (#2381) via NachoSoto (@NachoSoto)
* `@DefaultDecodable.Now`: fixed flaky test (#2374) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed iOS compilation (#2376) via NachoSoto (@NachoSoto)
* `SubscriberAttributesManagerIntegrationTests`: fixed potential race condition (#2380) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: create `CustomerInfo` from offline entitlements (#2358) via NachoSoto (@NachoSoto)
* Added `@DefaultDecodable.Now` (#2372) via NachoSoto (@NachoSoto)
* `HTTPClient`: debug log when performing redirects (#2371) via NachoSoto (@NachoSoto)
* `HTTPClient`: new flag to force server errors (#2370) via NachoSoto (@NachoSoto)
* `OfferingsManager`: fixed Xcode 13.x build (#2369) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: store `ProductEntitlementMapping` in cache (#2355) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: added support for fetching `ProductEntitlementMappingResponse` in `OfflineEntitlementsAPI` (#2353) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: created `ProductEntitlementMapping` (#2365) via NachoSoto (@NachoSoto)
* Implemented `NetworkError.isServerDown` (#2367) via NachoSoto (@NachoSoto)
* `ETagManager`: added test for 304 responses with no etag (#2360) via NachoSoto (@NachoSoto)
* `TestLogHandler`: increased default capacity (#2357) via NachoSoto (@NachoSoto)
* `OfferingsManager`: moved log to common method to remove hardcoded string (#2363) via NachoSoto (@NachoSoto)
* `Offline Entitlements`: created `ProductEntitlementMappingResponse` (#2351) via NachoSoto (@NachoSoto)
* `HTTPClient`: added test for 2xx response for request with etag (#2361) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI` improvements (#2345) via NachoSoto (@NachoSoto)
* `ConfigureStrings`: fixed double-space typo (#2344) via NachoSoto (@NachoSoto)
* `ETagManagerTests`: fixed tests on iOS 12 (#2349) via NachoSoto (@NachoSoto)
* `DeviceCache`: simplified constructor (#2354) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: changed all APIs to `internal` (#2350) via NachoSoto (@NachoSoto)
* `VerificationResult.notRequested`: removed caching reference (#2337) via NachoSoto (@NachoSoto)
* Finished signature verification `HTTPClient` tests (#2333) via NachoSoto (@NachoSoto)
* `Configuration.Builder.with(entitlementVerificationMode:)`: improved documentation (#2334) via NachoSoto (@NachoSoto)
* `ETagManager`: don't ignore failed etags with `Signing.VerificationMode.informational` (#2331) via NachoSoto (@NachoSoto)
* `IdentityManager`: clear `ETagManager` and `DeviceCache` if verification is enabled but cached `CustomerInfo` is not (#2330) via NachoSoto (@NachoSoto)
* Made `Configuration.EntitlementVerificationMode.enforced` unavailable (#2329) via NachoSoto (@NachoSoto)
* Refactor: reorganized files in new Security and Misc folders (#2326) via NachoSoto (@NachoSoto)
* `CustomerInfo`: use same grace period logic for active subscriptions (#2327) via NachoSoto (@NachoSoto)
* `HTTPClient`: don't verify 4xx/5xx responses (#2322) via NachoSoto (@NachoSoto)
* `EntitlementInfo`: request date is not optional (#2325) via NachoSoto (@NachoSoto)
* `CustomerInfo`: removed `entitlementVerification` (#2320) via NachoSoto (@NachoSoto)
* Renamed `VerificationResult.notVerified` to `.notRequested` (#2321) via NachoSoto (@NachoSoto)
* `EntitlementInfo`: add a grace period limit to outdated entitlements (#2288) via NachoSoto (@NachoSoto)
* Update `CustomerInfo.requestDate` from 304 responses (#2310) via NachoSoto (@NachoSoto)
* `Signing`: added request time & eTag to signature verification (#2309) via NachoSoto (@NachoSoto)
* `HTTPClient`: changed header search to be case-insensitive (#2308) via NachoSoto (@NachoSoto)
* `HTTPClient`: automatically add `nonce` based on `HTTPRequest.Path` (#2286) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added ability to reload `CustomerInfo` with a custom `CacheFetchPolicy` (#2312) via NachoSoto (@NachoSoto)
* Fix issue where underlying error information for product fetch errors was not printed in log. (#2281) via Chris Vasselli (@chrisvasselli)
* `PurchaseTester`: added ability to set `Configuration.EntitlementVerificationMode` (#2290) via NachoSoto (@NachoSoto)
* SwiftUI: Paywall View should respond to changes on the UserView model (#2297) via ConfusedVorlon (@ConfusedVorlon)
* Deprecate `usesStoreKit2IfAvailable` (#2293) via Andy Boedo (@aboedo)
* `Signing`: updated to use production public key (#2274) via NachoSoto (@NachoSoto)
</details>

## 4.18.0
### New Features
* Introduced Custom Entitlements Computation mode (#2439) via Andy Boedo (@aboedo)
* Create separate `SPM` library to enable custom entitlement computation (#2440) via NachoSoto (@NachoSoto)

This new library allows apps to use a smaller version of the RevenueCat SDK, intended for apps that will do their own entitlement computation separate from RevenueCat.

Apps using this mode rely on webhooks to signal their backends to refresh entitlements with RevenueCat.

See the [demo app for an example and usage instructions](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/testCustomEntitlementsComputation).

### Bugfixes
* `PurchaseOrchestrator`: fix incorrect `InitiationSource` for SK1 queue transactions (#2430) via NachoSoto (@NachoSoto)

### Other Changes
* Update offerings cache when switchUser(to:) is called (#2455) via Andy Boedo (@aboedo)
* Updated example code for the sample app for Custom Entitlements (#2454) via Andy Boedo (@aboedo)
* Custom Entitlement Computation: API testers (#2452) via NachoSoto (@NachoSoto)
* Custom Entitlement Computation: avoid `getCustomerInfo` requests for cancelled purchases (#2449) via NachoSoto (@NachoSoto)
* Custom Entitlement Computation: disabled unnecessary APIs (#2442) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added log when adding payment to queue (#2423) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added debug log when transaction is removed but no callbacks to notify (#2418) via NachoSoto (@NachoSoto)
* `customEntitlementsComputation`: update the copy in the sample app to explain the new usage (#2443) via Andy Boedo (@aboedo)
* Clarify reasoning for `disfavoredOverload` in logIn (#2434) via Andy Boedo (@aboedo)
* Documentation: improved `async` API docs (#2432) via Kaunteya Suryawanshi (@kaunteya)

## 4.17.11
### Bug Fixes
* `CustomerInfoManager`: fixed deadlock caused by reading `CustomerInfo` inside of observer (#2412) via NachoSoto (@NachoSoto)

## 4.17.10
### Bugfixes
* Fix `NotificationCenter` deadlock in `customerInfoListener` (#2407) via Andy Boedo (@aboedo)
* `Xcode 14.3`: fixed compilation errors (#2399) via NachoSoto (@NachoSoto)
* `DispatchTimeInterval`: fixed Xcode 14.3 compilation (#2397) via NachoSoto (@NachoSoto)

### Other Changes
* `CircleCI`: use `Xcode 14.3.0` (#2398) via NachoSoto (@NachoSoto)

## 4.17.9
### Bugfixes
* `DeviceCache`: workaround for potential deadlock (#2375)

### Performance Improvements
* `PostReceiptDataOperation` / `GetCustomerInfoOperation`: only invoke response handlers once (#2377) via NachoSoto (@NachoSoto)

### Other Changes
* Redirect to latest version of migration guide (#2384)
* Fix migration guide link (#2383)
* `SwiftLint`: fixed lint with new 0.51.0 version (#2395)

## 4.17.8
### Bugfixes
* `DispatchTimeInterval` & `Date`: avoid 32-bit overflows, fix `watchOS` crashes (#2342) via NachoSoto (@NachoSoto)
* Fix issue with missing subscriber attributes if set after login but before login callback (#2313) via @tonidero

### Performance Improvements
* `AppleReceipt.mostRecentActiveSubscription`: performance optimization (#2332) via NachoSoto (@NachoSoto)

### Other Changes
* `CI`: also run tests on `watchOS` (#2340) via NachoSoto (@NachoSoto)
* `RELEASING.md`: added GitHub rate limiting parameter (#2336) via NachoSoto (@NachoSoto)
* Add additional logging on init (#2324) via Cody Kerns (@codykerns)
* Replace `iff` with `if and only if` (#2323) via @aboedo
* Fix typo in log (#2315) via @nickkohrn
* `Purchases.restorePurchases`: added docstring about successful results (#2316) via NachoSoto (@NachoSoto)
* `RELEASING.md`: fixed hotfix instructions (#2304) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fixed leak when reconfiguring `Purchases` (#2311) via NachoSoto (@NachoSoto)
* `ProductsFetcherSK2`: add underlying error to description (#2281) via Chris Vasselli (@chrisvasselli)

## 4.17.7
### Bugfixes
* Fixed `Bundle: Sendable` conformance (#2301)
* Fixed `PurchasesOrchestrator` compilation error on Xcode 14.3 beta 1 (#2292) via NachoSoto (@NachoSoto)
### Other Changes
* Clarifies error messages for StoreKit 1 bugs (#2294)

## 4.17.6
### Bugfixes
* `PurchaseOrchestrator`: always refresh receipt purchasing in sandbox (#2280) via NachoSoto (@NachoSoto)
* `BundleSandboxEnvironmentDetector`: always return `true` when running on simulator (#2276) via NachoSoto (@NachoSoto)
* `OfferingsManager`: ensure underlying `OfferingsManager.Error.configurationError` is logged (#2266) via NachoSoto (@NachoSoto)
### Other Changes
* `UserDefaultsDefaultTests`: fixed flaky failures (#2284) via NachoSoto (@NachoSoto)
* `BaseBackendTest`: improved test failure message (#2285) via NachoSoto (@NachoSoto)
* Updated targets and schemes for Xcode 14.2 (#2282) via NachoSoto (@NachoSoto)
* `HTTPRequest.Path.health`: don't cache using `ETagManager` (#2278) via NachoSoto (@NachoSoto)
* `EntitlementInfos.all`: fixed docstring (#2279) via NachoSoto (@NachoSoto)
* `StoreKit2StorefrontListener`: added tests to fix flaky code coverage (#2265) via NachoSoto (@NachoSoto)
* `NetworkError`: added underlying error to description (#2263) via NachoSoto (@NachoSoto)
* Created `Signing.verify(message:hasValidSignature:with:)` (#2216) via NachoSoto (@NachoSoto)

## 4.17.5
### Dependency Updates
* Bump fastlane-plugin-revenuecat_internal from `738f255` to `9255366` (#2264) via dependabot[bot] (@dependabot[bot])
* Update `Gemfile.lock` (#2254) via Cesar de la Vega (@vegaro)
### Other Changes
* `HTTPClient`: added support for sending `X-Nonce` (#2214) via NachoSoto (@NachoSoto)
* `Configuration`: added (`internal` for now) API to load public key (#2215) via NachoSoto (@NachoSoto)
* Replaced `Any` uses for workaround with `Box` (#2250) via NachoSoto (@NachoSoto)
* `HTTPClientTests`: fixed failing test with missing assertions (#2262) via NachoSoto (@NachoSoto)
* `HTTPClientTests`: refactored tests to use `waitUntil` (#2257) via NachoSoto (@NachoSoto)
* PurchaseTester: Add Receipt Inspector UI (#2249) via Andy Boedo (@aboedo)
* Adds dependabot (#2259) via Cesar de la Vega (@vegaro)
* `StoreKit1WrapperTests`: avoid using `Bool.random` to fix flaky code coverage (#2258) via NachoSoto (@NachoSoto)
* `IntroEligibilityCalculator`: changed logic to handle products with no subscription group (#2247) via NachoSoto (@NachoSoto)

## 4.17.4
### Bugfixes
* `CustomerInfoManager`: improved thread-safety (#2224) via NachoSoto (@NachoSoto)
### Other Changes
* `StoreKitIntegrationTests`: replaced `XCTSkipIf` with `XCTExpectFailure` (#2244) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: changed `ReceiptRefreshPolicy.always` to `.onlyIfEmpty` after a purchase (#2245) via NachoSoto (@NachoSoto)

## 4.17.3
### Bugfixes
* `IntroEligibilityCalculator`: fixed logic for subscriptions in same group (#2174) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: finish SK2 transactions from `StoreKit.Transaction.updates` after posting receipt (#2243) via NachoSoto (@NachoSoto)
### Other Changes
* `Purchases`: fixed documentation warnings (#2241) via NachoSoto (@NachoSoto)
* Code coverage (#2242) via NachoSoto (@NachoSoto)
* Improve logging for custom package durations (#2240) via Cody Kerns (@codykerns)
* `TrialOrIntroPriceEligibilityChecker`: use `TimingUtil` to log when it takes too long (#2238) via NachoSoto (@NachoSoto)
* Update `fastlane-plugin-revenuecat_internal` (#2239) via NachoSoto (@NachoSoto)
* Simplified `OperationDispatcher.dispatchOnMainActor` (#2236) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added contents of `CHANGELOG.latest.md` to `TestFlight` changelog (#2233) via NachoSoto (@NachoSoto)
* `SystemInfo.isApplicationBackgrounded`: added overload for `@MainActor` (#2230) via NachoSoto (@NachoSoto)

## 4.17.2
### Bugfixes
* `Purchases`: avoid potential crash when initializing in the background (#2231) via NachoSoto (@NachoSoto)
### Other Changes
* `PurchaseTester`: ignore errors when restoring purchases (#2228) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fixed `isPurchasing` state when purchasing fails (#2229) via NachoSoto (@NachoSoto)
* `PurchaseTester`: setting `changelog` when submitting to `TestFlight` (#2232) via NachoSoto (@NachoSoto)
* Revert "`SPM`: added `APPLICATION_EXTENSION_API_ONLY` flag to `RevenueCat` and `ReceiptParser` (#2217)" (#2225) via NachoSoto (@NachoSoto)

## 4.17.1
### Other Changes
* set flag to extract objc info for swift symbols (#2218) via Andy Boedo (@aboedo)
* Produce a compilation error when using an old `Xcode` version (#2222) via NachoSoto (@NachoSoto)
* `SPM`: added `APPLICATION_EXTENSION_API_ONLY` flag to `RevenueCat` and `ReceiptParser` (#2217) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added section to visualize `AppleReceipt` (#2211) via NachoSoto (@NachoSoto)

## 4.17.0
### New Features
* Added new `ReceiptParser.fetchAndParseLocalReceipt` (#2204) via NachoSoto (@NachoSoto)
* `PurchasesReceiptParser`: added API to parse receipts from `base64` string (#2200) via NachoSoto (@NachoSoto)
### Bugfixes
* `CustomerInfo`: support parsing schema version 2 to restore SDK `v3.x` compatibility (#2213) via NachoSoto (@NachoSoto)
### Other Changes
* `JSONDecoder`: added decoding type when logging `DecodingError.keyNotFound` (#2212) via NachoSoto (@NachoSoto)
* Added `ReceiptParserTests` (#2203) via NachoSoto (@NachoSoto)
* Deploy `PurchaseTester` for `macOS` (#2011) via NachoSoto (@NachoSoto)
* `ReceiptFetcher`: refactored implementation to log error when failing to fetch receipt (#2202) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: replaced receipt `base64` with `hash` for cache key (#2199) via NachoSoto (@NachoSoto)
* `PurchaseTester`: small refactor to simplify `Date` formatting (#2210) via NachoSoto (@NachoSoto)
* `PurchasesReceiptParser`: improved documentation to reference `default` (#2197) via NachoSoto (@NachoSoto)
* Created `CachingTrialOrIntroPriceEligibilityChecker` (#2007) via NachoSoto (@NachoSoto)
* Update Gemfile.lock (#2205) via Cesar de la Vega (@vegaro)
* remove stalebot in favor of SLAs in Zendesk (#2196) via Andy Boedo (@aboedo)
* Update fastlane-plugin-revenuecat_internal to latest version (#2194) via Cesar de la Vega (@vegaro)

## 4.16.0
### New Features
* Created `ReceiptParser` SPM (#2155) via NachoSoto (@NachoSoto)
* Exposed `PurchasesReceiptParser` and `AppleReceipt` (#2153) via NachoSoto (@NachoSoto)
### Bugfixes
* `Restore purchases`: post product data when posting receipts (#2178) via NachoSoto (@NachoSoto)
### Other Changes
* Added `Dictionary.merge` (#2190) via NachoSoto (@NachoSoto)
* `CircleCI`: use Xcode 14.2.0 (#2187) via NachoSoto (@NachoSoto)
* `ReceiptParser`: a few documentation improvements (#2189) via NachoSoto (@NachoSoto)
* `Purchase Tester`: fixed `TestFlight` deployment (#2188) via NachoSoto (@NachoSoto)
* `Purchase Tester`: display specific `IntroEligibilityStatus` (#2184) via NachoSoto (@NachoSoto)
* `Purchase Tester`: fixed `SubscriptionPeriod` (#2185) via NachoSoto (@NachoSoto)

## 4.15.5
### Bugfixes
* `ErrorUtils.purchasesError(withUntypedError:)`: handle `PublicError`s (#2165) via NachoSoto (@NachoSoto)
* Fixed race condition finishing `SK1` transactions (#2148) via NachoSoto (@NachoSoto)
* `IntroEligibilityStatus`: added `CustomStringConvertible` implementation (#2182) via NachoSoto (@NachoSoto)
* `BundleSandboxEnvironmentDetector`: fixed logic for `macOS` (#2176) via NachoSoto (@NachoSoto)
* Fixed `AttributionFetcher.adServicesToken` hanging when called in simulator (#2157) via NachoSoto (@NachoSoto)
### Other Changes
* `Purchase Tester`: added ability to purchase products directly with `StoreKit` (#2172) via NachoSoto (@NachoSoto)
* `DNSChecker`: simplified `NetworkError` initialization (#2166) via NachoSoto (@NachoSoto)
* `Purchases` initialization: refactor to avoid multiple concurrent instances in memory (#2180) via NachoSoto (@NachoSoto)
* `Purchase Tester`: added button to clear messages on logger view (#2179) via NachoSoto (@NachoSoto)
* `NetworkOperation`: added assertion to ensure that subclasses call completion (#2138) via NachoSoto (@NachoSoto)
* `CacheableNetworkOperation`: avoid unnecessarily creating operations for cache hits (#2135) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fixed `macOS` support (#2175) via NachoSoto (@NachoSoto)
* `IntroEligibilityCalculator`: added log including `AppleReceipt` (#2181) via NachoSoto (@NachoSoto)
* `Purchase Tester`: fixed scene manifest (#2170) via NachoSoto (@NachoSoto)
* `HTTPClientTests`: refactored to use `waitUntil` (#2168) via NachoSoto (@NachoSoto)
* `Integration Tests`: split up tests in smaller files (#2158) via NachoSoto (@NachoSoto)
* `StoreKitRequestFetcher`: removed unnecessary dispatch (#2152) via NachoSoto (@NachoSoto)
* `Purchase Tester`: added companion `watchOS` app (#2140) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added warning if receiving too many updated transactions (#2117) via NachoSoto (@NachoSoto)
* `StoreKitTestHelpers`: cleaned up unnecessary log (#2177) via NachoSoto (@NachoSoto)
* `TrialOrIntroPriceEligibilityCheckerSK1Tests`: use `waitUntilValue` (#2173) via NachoSoto (@NachoSoto)
* `DNSChecker`: added log with resolved host (#2167) via NachoSoto (@NachoSoto)
* `MagicWeatherSwiftUI`: updated `README` to point to workspace (#2142) via NachoSoto (@NachoSoto)
* `Purchase Tester`: fixed `.storekit` config file reference (#2171) via NachoSoto (@NachoSoto)
* `Purchase Tester`: fixed error alerts (#2169) via NachoSoto (@NachoSoto)
* `CI`: don't make releases until `release-checks` pass (#2162) via NachoSoto (@NachoSoto)
* `Fastfile`: changed `match` to `readonly` (#2161) via NachoSoto (@NachoSoto)

## 4.15.4
### Bugfixes
* Fix sending presentedOfferingIdentifier in StoreKit2 (#2156) via Toni Rico (@tonidero)
* `ReceiptFetcher`: throttle receipt refreshing to avoid `StoreKit` throttle errors (#2146) via NachoSoto (@NachoSoto)
### Other Changes
* Added integration and unit tests to verify observer mode behavior (#2069) via NachoSoto (@NachoSoto)
* Created `ClockType` and `TestClock` to be able to mock time (#2145) via NachoSoto (@NachoSoto)
* Extracted `asyncWait` to poll `async` conditions in tests (#2134) via NachoSoto (@NachoSoto)
* `StoreKitRequestFetcher`: added log when starting/ending requests (#2151) via NachoSoto (@NachoSoto)
* `CI`: fixed `PurchaseTester` deployment (#2147) via NachoSoto (@NachoSoto)

## 4.15.3
### Bugfixes
* Un-deprecate `Purchases.configure(withAPIKey:appUserID:)` and `Purchases.configure(withAPIKey:appUserID:observerMode:)` (#2129) via NachoSoto (@NachoSoto)
### Other Changes
* `ReceiptFetcherTests`: refactored tests using `waitUntilValue` (#2144) via NachoSoto (@NachoSoto)
* Added a few performance improvements for `ReceiptParser` (#2124) via NachoSoto (@NachoSoto)
* `CallbackCache`: fixed reference (#2143) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: clarified receipt debug log (#2128) via NachoSoto (@NachoSoto)
* `CallbackCache`: avoid exposing internal mutable cache (#2136) via NachoSoto (@NachoSoto)
* `CallbackCache`: added assertion for tests to ensure we don't leak callbacks (#2137) via NachoSoto (@NachoSoto)
* `NetworkOperation`: made `Atomic` references immutable (#2139) via NachoSoto (@NachoSoto)
* `ReceiptParser`: ensure parsing never happens in the main thread (#2123) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: also print receipt data with `verbose` logs (#2127) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: detecting and fixing many `DeviceCache` leaks (#2105) via NachoSoto (@NachoSoto)
* `StoreKitIntegrationTests`: added test to check applying a promotional offer during subscription (#1588) via NachoSoto (@NachoSoto)

## 4.15.2
### Bugfixes
* Fixed purchasing with `PromotionalOffer`s using `StoreKit 2` (#2020) via NachoSoto (@NachoSoto)
### Other Changes
* `CircleCI`: cache Homebrew installation (#2103) via NachoSoto (@NachoSoto)
* `Integration Tests`: fixed `Purchases` leak through `PurchasesDiagnostics` (#2126) via NachoSoto (@NachoSoto)
* `HTTPClient`: replaced `X-StoreKit2-Setting` with `X-StoreKit2-Enabled` (#2118) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: added assertion to ensure `Purchases` does not leak (#2104) via NachoSoto (@NachoSoto)
* `ReceiptParser.parse` always throws `ReceiptParser.Error` (#2099) via NachoSoto (@NachoSoto)
* `Tests`: ensure `Purchases` is not configured multiple times (#2100) via NachoSoto (@NachoSoto)
* Extracted `LoggerType` (#2098) via NachoSoto (@NachoSoto)
* `Integration Tests`: verify `Purchases` does not leak across tests (#2106) via NachoSoto (@NachoSoto)
* `StoreKit2` listeners: set `Task` `priority` to `.utility` (#2070) via NachoSoto (@NachoSoto)
* `Installation Tests`: remove unused code in `Fastfile` (#2097) via NachoSoto (@NachoSoto)
* `DeviceCache`: added verbose logs for `init`/`deinit` (#2101) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: process transactions in a background thread (#2115) via NachoSoto (@NachoSoto)
* update CONTRIBUTING.md link in bug report template (#2119) via Nate Lowry (@natelowry)

## 4.15.1
### Bugfixes
* `Configuration.with(appUserID:)`: allow passing `nil` and added new tests (#2110) via NachoSoto (@NachoSoto)
### Other Changes
* Fix documentation typo (#2113) via Bas Broek (@BasThomas)

## 4.15.0
### New Features
* Added `LogLevel.verbose` (#2080) via NachoSoto (@NachoSoto)
### Other Changes
* Fixed `LogLevel` ordering and added tests (#2102) via NachoSoto (@NachoSoto)
* `TimingUtil`: fixed Xcode 13.2 compilation (#2088) via NachoSoto (@NachoSoto)
* Generate documentation for `iOS` instead of `macOS` (#2089) via NachoSoto (@NachoSoto)
* Update `fastlane` (#2090) via NachoSoto (@NachoSoto)
* CI: speed up `docs-deploy` by only installing `bundle` dependencies (#2092) via NachoSoto (@NachoSoto)
* `Tests`: replaced `toEventually` with new `waitUntilValue` to simplify tests (#2071) via NachoSoto (@NachoSoto)
* `CircleCI`: fixed `docs-deploy` git credentials (#2087) via NachoSoto (@NachoSoto)
* Added `verbose` logs for `Purchases` and `StoreKit1Wrapper` lifetime (#2082) via NachoSoto (@NachoSoto)
* `StoreKit`: added logs when purchasing and product requests are too slow (#2061) via NachoSoto (@NachoSoto)
* Created `TimingUtil` to measure and log methods that are too slow (#2059) via NachoSoto (@NachoSoto)
* `SKTestSession`: finish all unfinished transactions before starting each test (#2066) via NachoSoto (@NachoSoto)
* `CircleCI`: lowered `no_output_timeout` to 5 minutes (#2084) via NachoSoto (@NachoSoto)
* Removed unused `APITesters.xcworkspace` and created `RevenueCat.xcworkspace` (#2075) via NachoSoto (@NachoSoto)
* `Atomic`: added new test to verify each instance gets its own `Lock` (#2077) via NachoSoto (@NachoSoto)
* `Logger`: exposed generic `log` method (#2058) via NachoSoto (@NachoSoto)

## 4.14.3
### Bugfixes
* Changed default `UserDefaults` from `.standard` to our own Suite (#2046) via NachoSoto (@NachoSoto)
### Other Changes
* `Logging`: added log when configuring SDK in observer mode (#2065) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added observer mode setting (#2052) via NachoSoto (@NachoSoto)
* Exposed `SystemInfo.observerMode` to simplify code (#2064) via NachoSoto (@NachoSoto)
* `Result.init(catching:)` with `async` method (#2060) via NachoSoto (@NachoSoto)
* Updated schemes and project for Xcode 14.1 (#2081) via NachoSoto (@NachoSoto)
* `PurchasesSubscriberAttributesTests`: simplified tests (#2056) via NachoSoto (@NachoSoto)
* `DeviceCache`: removed `fatalError` for users not overriding `UserDefaults` (#2079) via NachoSoto (@NachoSoto)
* `DeviceCache`: changed `NotificationCenter` observation to be received on posting thread (#2078) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added instance address when detecting transactions (#2055) via NachoSoto (@NachoSoto)
* Fixed lint issues with `SwiftLint 0.5.0` (#2076) via NachoSoto (@NachoSoto)
* `NSData+RCExtensionsTests`: improved errors (#2043) via NachoSoto (@NachoSoto)
* `APITester`: fixed warning in `SubscriptionPeriodAPI` (#2054) via NachoSoto (@NachoSoto)
* `Integration Tests`: always run them in random order locally (#2068) via NachoSoto (@NachoSoto)

## 4.14.2
### Bugfixes
* `StoreKit 2`: don't finish transactions in observer mode (#2053) via NachoSoto (@NachoSoto)
### Other Changes
* `CircleCI`: added ability to create a release manually (#2067) via NachoSoto (@NachoSoto)
* Changelog: Fix links to V4 API Migration guide (#2051) via Kevin Quisquater (@KevinQuisquater)
* `HTTPClient`: added log for failed requests (#2048) via NachoSoto (@NachoSoto)
* `ErrorResponse.asBackendError`: serialize attribute errors as `NSDictionary` (#2034) via NachoSoto (@NachoSoto)
* `ErrorCode.unknownBackendError`: include original error code (#2032) via NachoSoto (@NachoSoto)
* `CI`: fixed `push-pods` job (#2045) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: log Apple error when purchase equals expiration date (#2038) via NachoSoto (@NachoSoto)
* Update Fastlane plugin (#2041) via Cesar de la Vega (@vegaro)

## 4.14.1
### Bugfixes
* `ISO8601DateFormatter.withMilliseconds`: fixed iOS 11 crash (#2037) via NachoSoto (@NachoSoto)
* Changed `StoreKit2Setting.default` back to `.enabledOnlyForOptimizations` (#2022) via NachoSoto (@NachoSoto)
### Other Changes
* `Integration Tests`: changed weekly to monthly subscriptions to work around 0-second subscriptions (#2042) via NachoSoto (@NachoSoto)
* `Integration Tests`: fixed `testPurchaseWithAskToBuyPostsReceipt` (#2040) via NachoSoto (@NachoSoto)
* `ReceiptRefreshPolicy.retryUntilProductIsFound`: default to returning "invalid" receipt (#2024) via NachoSoto (@NachoSoto)
* `CachingProductsManager`: use partial cached products (#2014) via NachoSoto (@NachoSoto)
* Added `BackendErrorCode.purchasedProductMissingInAppleReceipt` (#2033) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: replaced `Purchases` dependency with `SPM` (#2027) via NachoSoto (@NachoSoto)
* `Integration Tests`: changed log output to `raw` (#2031) via NachoSoto (@NachoSoto)
* `Integration Tests`: run on iOS 16 (#2035) via NachoSoto (@NachoSoto)
* CI: fixed `iOS 14` tests Xcode version (#2030) via NachoSoto (@NachoSoto)
* `Async.call`: added non-throwing overload (#2006) via NachoSoto (@NachoSoto)
* Documentation: Fixed references in `V4_API_Migration_guide.md` (#2018) via NachoSoto (@NachoSoto)
* `eligiblePromotionalOffers`: don't log error if response is ineligible (#2019) via NachoSoto (@NachoSoto)
* Runs push-pods after make-release (#2025) via Cesar de la Vega (@vegaro)
* Some updates on notify-on-non-patch-release-branches: (#2026) via Cesar de la Vega (@vegaro)
* Deploy `PurchaseTesterSwiftUI` to TestFlight (#2003) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added "logs" screen (#2012) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: allow configuring API key at runtime (#1999) via NachoSoto (@NachoSoto)

## 4.14.0
### New Features
* Introduced `PurchasesDiagnostics` to help diagnose SDK configuration errors (#1977) via NachoSoto (@NachoSoto)
### Bugfixes
* Avoid posting empty receipts by making`TransactionsManager` always use `SK1` implementation (#2015) via NachoSoto (@NachoSoto)
* `NetworkOperation`: workaround for iOS 12 crashes (#2008) via NachoSoto (@NachoSoto)
### Other Changes
* Makes hold job wait for installation tests to pass (#2017) via Cesar de la Vega (@vegaro)
* Update fastlane-plugin-revenuecat_internal (#2016) via Cesar de la Vega (@vegaro)
* `bug_report.md`: changed SK2 wording (#2010) via NachoSoto (@NachoSoto)
* Added `Set + Set` and `Set += Set` operators (#2013) via NachoSoto (@NachoSoto)
* fix the link to StoreKit Config file from watchOS purchaseTester (#2009) via Andy Boedo (@aboedo)
* `PurchaseTesterSwiftUI`: combined targets into one multi-platform and fixed `macOS` (#1996) via NachoSoto (@NachoSoto)
* Less Array() (#2005) via SabinaHuseinova (@SabinaHuseinova)
* Docs: fixed `logIn` references (#2002) via NachoSoto (@NachoSoto)
* CI: use `Xcode 14.1` (#1992) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed warnings and simplified code using `async` methods (#1985) via NachoSoto (@NachoSoto)

## 4.13.4
### Bugfixes
* Fixed Xcode 13.2.x / Swift 5.5 compatibility (#1994) via NachoSoto (@NachoSoto)
### Other Changes
* Update `fastlane` (#1998) via NachoSoto (@NachoSoto)
* Documentation: fixed missing docs from inherited symbols (#1997) via NachoSoto (@NachoSoto)
* CI: added job to test compilation with `Xcode 13.2.1` / `Swift 5.5` (#1990) via NachoSoto (@NachoSoto)
* Extracted `TrialOrIntroPriceEligibilityCheckerType` (#1983) via NachoSoto (@NachoSoto)
* CI: removed redundant `swiftlint` installation (#1993) via NachoSoto (@NachoSoto)
* `Nimble`: use a fixed version (#1991) via NachoSoto (@NachoSoto)
* Update fastlane-plugin-revenuecat_internal (#1989) via Cesar de la Vega (@vegaro)
* `Purchases.logIn`: log warning if attempting to use a static `appUserID` (#1958) via NachoSoto (@NachoSoto)
* Created `InternalAPI` for "health" request (#1971) via NachoSoto (@NachoSoto)

## 4.13.3
### Other Changes
* `TrialOrIntroPriceEligibilityChecker`: only use SK2 implementation if enabled (#1984) via NachoSoto (@NachoSoto)

## 4.13.2
### Bugfixes
* Purchasing: fixed consumable purchases by fixing transaction-finishing (#1965) via NachoSoto (@NachoSoto)
* `ErrorUtils`: improved logging and `localizedDescription` to include underlying errors (#1974) via NachoSoto (@NachoSoto)
* `PaymentQueueWrapper`: also implement `shouldShowPriceConsent` (#1963) via NachoSoto (@NachoSoto)
* `ReceiptFetcher`: added retry mechanism (#1945) via NachoSoto (@NachoSoto)
* `PaymentQueueWrapper`: also conform to `SKPaymentTransactionObserver` to fix promoted purchases (#1962) via NachoSoto (@NachoSoto)
### Other Changes
*  Updating great support link via Miguel José Carranza Guisado (@MiguelCarranza)
* `OfferingsManager`: added ability to fail if any product is not found (#1976) via NachoSoto (@NachoSoto)
* `OfferingsManager`: added missing test for ignoring missing products (#1975) via NachoSoto (@NachoSoto)
* `PaymentQueueWrapper`: improved abstraction for active `SKPaymentQueue` wrapper (#1968) via NachoSoto (@NachoSoto)
* `ErrorUtils.purchasesError(withUntypedError:)` handle `PurchasesErrorConvertible` (#1973) via NachoSoto (@NachoSoto)
* Renamed `CallbackCache.add(callback:)` (#1970) via NachoSoto (@NachoSoto)
* Fixed iOS 12/13 test snapshots (#1972) via NachoSoto (@NachoSoto)
* Moved `SKPaymentQueue.presentCodeRedemptionSheet` to `StoreKitWorkarounds` (#1967) via NachoSoto (@NachoSoto)
* `Async.call` method to convert completion-block call to `async` (#1969) via NachoSoto (@NachoSoto)
* Remind about updating docs and parity spreadsheet on minor releases (#1955) via Cesar de la Vega (@vegaro)
* `PostReceiptDataOperation`: added `initiationSource` parameter (#1957) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: separated `SKPaymentTransactionObserver` and `SKPaymentQueueDelegate` implementations (#1961) via NachoSoto (@NachoSoto)
* Refactored `Error.isCancelledError` into `Error+Extensions` (#1960) via NachoSoto (@NachoSoto)
* Update fastlane plugin (#1959) via Cesar de la Vega (@vegaro)
* `Integration Tests`: simplified `testIneligibleForIntroAfterPurchaseExpires` to fix flakiness (#1952) via NachoSoto (@NachoSoto)
* fix typo in comment (#1956) via Andy Boedo (@aboedo)

## 4.13.1
### Other Changes
* `ProductsFetcherSK2`: removed now redundant caching logic (#1908) via NachoSoto (@NachoSoto)
* Created `CachingProductsManager` to provide consistent caching logic when fetching products (#1907) via NachoSoto (@NachoSoto)
* Refactored `ReceiptFetcher.receiptData` (#1941) via NachoSoto (@NachoSoto)
* Abstracted conversion from `async` to completion-block APIs (#1943) via NachoSoto (@NachoSoto)
* Moved `InAppPurchase` into `AppleReceipt` (#1942) via NachoSoto (@NachoSoto)
* `Purchases+async`: combined `@available` statements into a single one (#1944) via NachoSoto (@NachoSoto)
* `Integration Tests`: don't initialize `Purchases` until the `SKTestSession` has been re-created (#1946) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: print receipt data if `debug` logs are enabled (#1940) via NachoSoto (@NachoSoto)

## 4.13.0
### New Features
* 🚨 `StoreKit 2` is now enabled by default 🚨 (#1922) via NachoSoto (@NachoSoto)
* Extracted `PurchasesType` and `PurchasesSwiftType` (#1912) via NachoSoto (@NachoSoto)
### Bugfixes
* `StoreKit 1`: changed result of cancelled purchases to be consistent with `StoreKit 2` (#1910) via NachoSoto (@NachoSoto)
* `PaymentQueueWrapper`: handle promotional purchase requests from App Store when SK1 is disabled (#1901) via NachoSoto (@NachoSoto)
### Other Changes
* Fixed iOS 12 tests (#1936) via NachoSoto (@NachoSoto)
* `CacheableNetworkOperation`: fixed race condition in new test (#1932) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: changed default back to SK1 (#1935) via NachoSoto (@NachoSoto)
* `Logger`: refactored default `LogLevel` definition (#1934) via NachoSoto (@NachoSoto)
* `AppleReceipt`: refactored declarations into nested types (#1933) via NachoSoto (@NachoSoto)
* `Integration Tests`: relaunch tests when retrying failures (#1925) via NachoSoto (@NachoSoto)
* `CircleCI`: downgraded release jobs to Xcode 13.x (#1927) via NachoSoto (@NachoSoto)
* `ErrorUtils`: added test to verify that `PublicError`s can be `catch`'d as `ErrorCode` (#1924) via NachoSoto (@NachoSoto)
* `StoreKitIntegrationTests`: print `AppleReceipt` data whenever `verifyEntitlementWentThrough` fails (#1929) via NachoSoto (@NachoSoto)
* `OperationQueue`: log debug message when requests are found in cache and skipped (#1926) via NachoSoto (@NachoSoto)
* `GetCustomerInfoAPI`: avoid making a request if there's any `PostReceiptDataOperation` in progress (#1911) via NachoSoto (@NachoSoto)
* `PurchaseTester`: allow HTTP requests and enable setting `ProxyURL` (#1917) via NachoSoto (@NachoSoto)
## 4.12.1
### Bugfixes
* `Purchases.beginRefundRequest`: ensured errors are `PublicError` (#1913) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed macOS target (#1915) via NachoSoto (@NachoSoto)
### Other Changes
* Fixed `tvOS` tests (#1928) via NachoSoto (@NachoSoto)
* `SnapshotTesting`: require version 1.9.0 to keep supporting iOS 12/13 tests (#1931) via NachoSoto (@NachoSoto)
* `pre-commit` hook: also verify leftover API keys in `PurchaseTester` (#1914) via NachoSoto (@NachoSoto)
* `CircleCI`: changed iOS 12/13 to use Xcode 13 (#1918) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: removed unnecessary `UIApplicationDelegate` (#1916) via NachoSoto (@NachoSoto)
* `CircleCI`: changed all jobs to use Xcode 14 (#1909) via NachoSoto (@NachoSoto)
* `Atomic`: added unit test to verify `value`'s setter (#1905) via NachoSoto (@NachoSoto)
* `spm build` CI job: changed to release build (#1903) via NachoSoto (@NachoSoto)
* `StoreKitUnitTests`:  compile on iOS 11.0+ (#1904) via NachoSoto (@NachoSoto)
* `Purchases`: only expose testing data on `DEBUG` (#1902) via NachoSoto (@NachoSoto)
* `Integration Tests`: added test to verify re-subscription behavior (#1898) via NachoSoto (@NachoSoto)
* `IntegrationTests`: simplified `testExpireSubscription` to fix flaky test (#1899) via NachoSoto (@NachoSoto)
* `Integration Tests`: actually verify that entitlement is active (#1880) via NachoSoto (@NachoSoto)

## 4.12.0
### Bugfixes
* `watchOS`: fixed crash when ran on single-target apps with Xcode 14 and before `watchOS 9.0` (#1895) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`/`OfferingsManager`: improved display of underlying errors (#1888) via NachoSoto (@NachoSoto)
* `Offering`: improved confusing log for `PackageType.custom` (#1884) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: don't log warning if `allowSharingAppStoreAccount` setting was never explicitly set (#1885) via NachoSoto (@NachoSoto)
* Introduced type-safe `PurchasesError` and fixed some incorrect returned error types (#1879) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`: fixed thread-unsafe implementation (#1878) via NachoSoto (@NachoSoto)
### New Features
* Disable SK1's `StoreKitWrapper` if SK2 is enabled and available (#1882) via NachoSoto (@NachoSoto)
* `Sendable` support (#1795) via NachoSoto (@NachoSoto)
### Other Changes
* Renamed `StoreKitWrapper` to `StoreKit1Wrapper` (#1886) via NachoSoto (@NachoSoto)
* Enabled `DEAD_CODE_STRIPPING` (#1887) via NachoSoto (@NachoSoto)
* `HTTPClient`: added `X-Client-Bundle-ID` and logged on SDK initialization (#1883) via NachoSoto (@NachoSoto)
* add link to SDK reference (#1872) via Andy Boedo (@aboedo)
* Added `StoreKit2Setting.shouldOnlyUseStoreKit2` (#1881) via NachoSoto (@NachoSoto)
* Introduced `TestLogHandler` to simplify how we test logged messages (#1858) via NachoSoto (@NachoSoto)
* `Integration Tests`: added test for purchasing `StoreProduct` instead of `Package` (#1875) via NachoSoto (@NachoSoto)
* `ErrorUtils`: added test to verify that returned errors can be converted to `ErrorCode` (#1871) via NachoSoto (@NachoSoto)

## 4.11.0
### Bugfixes
* Fixed crash on `async` SK1 cancelled purchase (#1869) via NachoSoto (@NachoSoto)
### New Features
* Added `beginRefundRequest` overload with completion block (#1861) via NachoSoto (@NachoSoto)
### Other Changes
* Skip release if needed and adds automatic release to PR title and body (#1870) via Cesar de la Vega (@vegaro)

## 4.10.3
### Bugfixes
* `TrialOrIntroPriceEligibilityChecker`: return `.noIntroOfferExists` if the product has no introductory offer (#1859) via NachoSoto (@NachoSoto)
* `watchOS`: fixed crash on single-target apps (#1849) via NachoSoto (@NachoSoto)
### Other Changes
* Update fastlane-plugin-revenuecat_internal and fix release-train job (#1866) via Cesar de la Vega (@vegaro)
* fix typo in comment (#1863) via Andy Boedo (@aboedo)
* Use Dangerfile repository (#1864) via Cesar de la Vega (@vegaro)
* `CircleCI`: added job for building SDK with `SPM` (#1860) via NachoSoto (@NachoSoto)
* `Lock`: changed default implementation to use `NSLock` (#1819) via NachoSoto (@NachoSoto)
* `Offering`/`StoreProductType`: `Sendable` conformance (#1826) via NachoSoto (@NachoSoto)
* `ReceiptParser: Sendable` conformance (#1825) via NachoSoto (@NachoSoto)
* `CustomerInfo: Sendable` conformance (#1824) via NachoSoto (@NachoSoto)
* Added `Collection.onlyElement` (#1857) via NachoSoto (@NachoSoto)
* README updates (#1856) via rglanz-rc (@rglanz-rc)
* `IntegrationTests`: actually fail test if tests aren't configured (#1855) via NachoSoto (@NachoSoto)
* `Configuration.with(usesStoreKit2IfAvailable:)`: removed "experimental" warning (#1845) via NachoSoto (@NachoSoto)
* Build fix- Update package requirements for MagicWeather (#1852) via Joshua Liebowitz (@taquitos)
* `Fastfile`: `test_tvos` lane had duplicate parameter (#1846) via NachoSoto (@NachoSoto)

## 4.10.2
### Bugfixes
* `ErrorResponse`: don't add attribute errors to message if empty (#1844) via NachoSoto (@NachoSoto)
* Purchase cancellations: unify behavior between SK1 and SK2 (#1841) via NachoSoto (@NachoSoto)
* StoreKit 2: `PurchasesOrchestrator`: don't log "purchased product" if it was cancelled (#1840) via NachoSoto (@NachoSoto)
* `Backend`: fixed potential race conditions introduced by `OperationDispatcher.dispatchOnWorkerThread(withRandomDelay:)` (#1827) via NachoSoto (@NachoSoto)
* `DeviceCache`: `Sendable` conformance and fixed thread-safety (#1823) via NachoSoto (@NachoSoto)
* Directly send delegate customer info when delegate is set (always sends cached CustomerInfo value) (#1828) via Josh Holtz (@joshdholtz)
* `SystemInfo.finishTransactions`: made thread-safe (#1807) via NachoSoto (@NachoSoto)
* `Purchases.shared` and `Purchases.isConfigured` are now thread-safe (#1813) via NachoSoto (@NachoSoto)
* `PriceFormatterProvider: Sendable` conformance and fixed thread-safety (#1818) via NachoSoto (@NachoSoto)
* `StoreKitConfigTestCase.changeStorefront`: re-enabled on iOS 16 (#1811) via NachoSoto (@NachoSoto)

### Other Changes
* `DeviceCache`: no longer set cache timestamp before beginning request (#1839) via NachoSoto (@NachoSoto)
* `MagicWeatherSwiftUI`: updated to use `async` APIs (#1843) via NachoSoto (@NachoSoto)
* Release train (#1842) via Cesar de la Vega (@vegaro)
* Adds hotfixes section to RELEASING doc (#1837) via Cesar de la Vega (@vegaro)
* Update fastlane plugin (#1838) via Toni Rico (@tonidero)
* Update migration doc from didReceiveUpdatedCustomerInfo to receivedUpdatedCustomerInfo (#1836) via Josh Holtz (@joshdholtz)
* `PurchasesDelegate`: added test for latest cached customer info always being sent (#1830) via NachoSoto (@NachoSoto)
* `CallbackCache: Sendable` conformance (#1835) via NachoSoto (@NachoSoto)
* `CallbackCache`: simplified implementation using `Atomic` (#1834) via NachoSoto (@NachoSoto)
* `PurchasesLogInTests`: added test to verify `logIn` updates offerings cache (#1833) via NachoSoto (@NachoSoto)
* Created `PurchasesLoginTests` (#1832) via NachoSoto (@NachoSoto)
* `SwiftLint`: cleaned up output (#1821) via NachoSoto (@NachoSoto)
* Link to sdk reference (#1831) via aboedo (@aboedo)
* `Atomic: ExpressibleByBooleanLiteral` (#1822) via NachoSoto (@NachoSoto)
* `SwiftLint`: fixed build warning (#1820) via NachoSoto (@NachoSoto)
* Adds an approval job that will tag the release (#1815) via Cesar de la Vega (@vegaro)
* `Atomic: ExpressibleByNilLiteral` (#1804) via NachoSoto (@NachoSoto)
* `PurchasesAttributionDataTests`: fixed potential race condition in flaky test (#1805) via NachoSoto (@NachoSoto)
* Fixed warnings for unnecessary `try` (#1816) via NachoSoto (@NachoSoto)
* Moved `AttributionFetcherError` inside `AttributionFetcher` (#1808) via NachoSoto (@NachoSoto)
* Update documentation for presentCodeRedemptionSheet (#1817) via Joshua Liebowitz (@taquitos)
* `Dangerfile`: added "next_release" as supported label (#1810) via NachoSoto (@NachoSoto)
* PurchaseTester- Update Podfile.lock (#1814) via Joshua Liebowitz (@taquitos)
* Update to latest fastlane plugin (#1802) via Toni Rico (@tonidero)
* Clean up: moved `BackendIntegrationTests.xctestplan` to `TestPlans` folder (#1812) via NachoSoto (@NachoSoto)
* `SK2StoreProduct`: conditionally removed `@available` workaround (#1794) via NachoSoto (@NachoSoto)
* `SwiftLint`: fixed deprecation warning (#1809) via NachoSoto (@NachoSoto)
* Update gems (#1791) via Joshua Liebowitz (@taquitos)
* Replace usages of replace_in with replace_text_in_files action (#1803) via Toni Rico (@tonidero)

## 4.10.1
### Bugfixes
* Directly send delegate customer info when delegate is set (always sends cached CustomerInfo value) (#1828) via Josh Holtz (@joshdholtz)

## 4.10.0
### New Features
* New AdServices Integration (#1727) via Josh Holtz (@joshdholtz)
### Bugfixes
* `OfferingsManager`: expose underlying error when `ProductsManager` returns an error (#1792) via NachoSoto (@NachoSoto)
* Add missing logs to ProductsFetcherSK2 (#1780) via beylmk (@beylmk)
### Other Changes
* AdServices: Fix failing tests on main in iOS 12 and 13 - IOSAttributionPosterTests (#1797) via Josh Holtz (@joshdholtz)
* Invalidates gem caches and separates danger and macOS caches (#1798) via Cesar de la Vega (@vegaro)
* Pass CircleCI branch to prepare_next_version job (#1796) via Toni Rico (@tonidero)
* Configure Danger, enforce labels (#1761) via Cesar de la Vega (@vegaro)
* Support for new fastlane internal plugin for automation (#1779) via Toni Rico (@tonidero)

## 4.9.1
### Fixes:
* `CustomerInfoResponseHandler`: return `CustomerInfo` instead of error if the response was successful (#1778) via NachoSoto (@NachoSoto)
* Error logging: `logErrorIfNeeded` no longer prints message if it's the same as the error description (#1776) via NachoSoto (@NachoSoto)
* fix another broken link in docC docs (#1777) via aboedo (@aboedo)
* fix links to restorePurchase (#1775) via aboedo (@aboedo)
* fix getProducts docs broken link (#1772) via aboedo (@aboedo)

### Improvements:
* `Logger`: wrap `message` in `@autoclosure` to avoid creating when `LogLevel` is disabled (#1781) via NachoSoto (@NachoSoto)

### Other changes:
* Lint: fixed `SubscriberAttributesManager` (#1774) via NachoSoto (@NachoSoto)
## 4.9.0
* Update Configuration.swift to include platformInfo. Used by PurchasesHybridCommon (#1760) via Joshua Liebowitz (@taquitos)

## 4.8.0
### New API

* `EntitlementInfo`: added `isActiveInCurrentEnvironment` and `isActiveInAnyEnvironment` (#1755) via NachoSoto (@NachoSoto)

### Other Changes
* Plumb platformInfo in Configuration for PHC use (#1757) via Joshua Liebowitz (@taquitos)
* added a log when `autoSyncPurchases` is disabled (#1749) via aboedo (@aboedo)
* Re-fetch cached offerings and products after Storefront changes (3/4)  (#1743) via Juanpe Catalán (@Juanpe)
* `bug_report.md`: clarify SK2 support (#1752) via NachoSoto (@NachoSoto)
* `logErrorIfNeeded`: also log message if present (#1754) via NachoSoto (@NachoSoto)

## 4.7.0
### Changes:
* Replaced `CustomerInfo.nonSubscriptionTransactions` with a new non-`StoreTransaction` type (#1733) via NachoSoto (@NachoSoto)
* `Purchases.configure`: added overload taking a `Configuration.Builder` (#1720) via NachoSoto (@NachoSoto)
* Extract Attribution logic out of Purchases (#1693) via Joshua Liebowitz (@taquitos)
* Remove create alias (#1695) via Joshua Liebowitz (@taquitos)

All attribution APIs can now be accessed from `Purchases.shared.attribution`.

### Improvements:
* Improved purchasing logs, added promotional offer information (#1725) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: don't log attribute errors if there are none (#1742) via NachoSoto (@NachoSoto)
* `FatalErrorUtil`: don't override `fatalError` on release builds (#1736) via NachoSoto (@NachoSoto)
* `SKPaymentTransaction`: added more context to warnings about missing properties (#1731) via NachoSoto (@NachoSoto)
* New SwiftUI Purchase Tester example (#1722) via Josh Holtz (@joshdholtz)
* update docs for `showManageSubscriptions` (#1729) via aboedo (@aboedo)
* `PurchasesOrchestrator`: unify finish transactions between SK1 and SK2 (#1704) via NachoSoto (@NachoSoto)
* `SubscriberAttribute`: converted into `struct` (#1648) via NachoSoto (@NachoSoto)
* `CacheFetchPolicy.notStaleCachedOrFetched`: added warning to docstring (#1708) via NachoSoto (@NachoSoto)
* Clear cached offerings and products after Storefront changes (2/4) (#1583) via Juanpe Catalán (@Juanpe)
* `ROT13`: optimized initialization and removed magic numbers (#1702) via NachoSoto (@NachoSoto)

### Fixes:
* `logIn`/`logOut`: sync attributes before aliasing (#1716) via NachoSoto (@NachoSoto)
* `Purchases.customerInfo(fetchPolicy:)`: actually use `fetchPolicy` parameter (#1721) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: fix behavior dealing with `nil` `SKPaymentTransaction.productIdentifier` during purchase (#1680) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator.handlePurchasedTransaction`: always refresh receipt data (#1703) via NachoSoto (@NachoSoto)

## 4.6.1
### Bug fixes

* `EntitlementInfo.isActive` returns true if `requestDate == expirationDate` (#1684) via beylmk (@beylmk)
* Fixed usages of `seealso` (#1689) via NachoSoto (@NachoSoto)
* Fixed `ROT13.string` thread-safety (#1686) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: replaced calls to `syncPurchases` with posting receipt for an individual product during SK2 purchases (#1666) via NachoSoto (@NachoSoto)

## 4.6.0
_This release is compatible with Xcode 14 beta 1_

### New Features

* `EntitlementInfos`: added `activeInAnyEnvironment` and `activeInCurrentEnvironment` (#1647) via NachoSoto (@NachoSoto)

In addition to `EntitlementInfos.active`, two new methods are added to allow detecting entitlements from sandbox and production environments:
```swift
customerInfo.entitlements.activeInCurrentEnvironment
customerInfo.entitlements.activeInAnyEnvironment
```

### Bug fixes

* `MacDevice`: changed usage of `kIOMasterPortDefault` to fix Catalyst compilation on Xcode 14 (#1676) via NachoSoto (@NachoSoto)
* `Result.init(value:error:)`: avoid creating error if value is provided (#1672) via NachoSoto (@NachoSoto)

## 4.5.2
_This version supports Xcode 14 beta 1_

* `PurchasesOrchestrator.handleDeferredTransaction`: check `NSError.domain` too (#1665) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: replaced manual `Lock` with `Atomic` (#1664) via NachoSoto (@NachoSoto)
* `CodableStrings.decoding_error`: added underlying error information (#1668) via NachoSoto (@NachoSoto)
* Fixed Xcode 14 compilation: avoid `@available` properties (#1661) via NachoSoto (@NachoSoto)

## 4.5.1
### Fixes

- Fix an issue where entitlement identifiers and product identifiers would get converted to snake case and returned as empty.
    https://github.com/RevenueCat/purchases-ios/pull/1651
    https://github.com/RevenueCat/purchases-ios/issues/1650

## 4.5.0
### New Features
* `Purchases.customerInfo()`: added overload with a new `CacheFetchPolicy` (#1608) via NachoSoto (@NachoSoto)
* `Storefront`: added `sk1CurrentStorefront` for Objective-C (#1614) via NachoSoto (@NachoSoto)

### Bug Fixes
* Fix for not being able to read receipts on watchOS (#1625) via Patrick Busch (@patrickbusch)

### Other Changes
* Added tests for `PurchasesOrchestrator` invoking `listenForTransactions` only if SK2 is enabled (#1618) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: removed `lazy` hack for properties with `@available` (#1596) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator.purchase(sk2Product:promotionalOffer:)`: simplified implementation with new operator (#1602) via NachoSoto (@NachoSoto)

## 4.4.0
### New Features
* Added new API key validation (#1581) via NachoSoto (@NachoSoto)
* Sending `X-Is-Sandbox` header in API requests (#1582) via NachoSoto (@NachoSoto)
* Added `AmazonStore` to `Store` enum (#1586) via Will Taylor (@fire-at-will)
* Added `Configuration` object and API to configure Purchases (#1556) via Joshua Liebowitz (@taquitos)
* Exposed `shouldShowPriceConsent` on `PurchasesDelegate` (#1520) via Joshua Liebowitz (@taquitos)

### Fixes
* `ManageSubscriptionsHelper`: fixed discrepancy between `SystemInfo.isAppleSubscription(managementURL:)` and `SystemInfo.appleSubscriptionsURL` (#1607) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: don't listen for StoreKit 2 transactions if it's disabled (#1593) via NachoSoto (@NachoSoto)
* Added tests and fix to ensure `RawDataContainer` includes all data (#1565) via NachoSoto (@NachoSoto)
* Added obsoletion for `DeferredPromotionalPurchaseBlock` (#1600) via NachoSoto (@NachoSoto)
* `StoreKit 2` purchases: don't throw when purchase is cancelled (#1603) via NachoSoto (@NachoSoto)
* Ensure `SubscriptionPeriod`s are represented as 1week instead of 7days (#1591) via Will Taylor (@fire-at-will)
* `PurchaseStrings`: fixed transaction message formatting (#1571) via NachoSoto (@NachoSoto)
* `willRenew` update comment for lifetime will be false (#1579) via Josh Holtz (@joshdholtz)
* `SK1StoreProductDiscount`: handle `SKProductDiscount.priceLocale` being `nil` and created `StoreKitWorkarounds` (#1545) via NachoSoto (@NachoSoto)
* Fixed `ErrorUtils.logDecodingError` (#1539) via NachoSoto (@NachoSoto)

### Other changes
* `GetIntroEligibilityOperation`: replaced response parsing with `Decodable` (#1576) via NachoSoto (@NachoSoto)
* `PostOfferForSigningOperation`: changed response parsing to using `Decodable` (#1573) via NachoSoto (@NachoSoto)
* Converted `CustomerInfo` and related types to use `Codable` (#1496) via NachoSoto (@NachoSoto)
* `MagicWeatherSwiftUI`: fixed usage of `PurchaseDelegate` (#1601) via NachoSoto (@NachoSoto)
* Added tests for `PeriodType`/`PurchaseOwnershipType`/`Store` (#1558) via NachoSoto (@NachoSoto)
* Fix description of `StoreTransaction` (#1584) via aboedo (@aboedo)
* Prepare the codebase to listen to the Storefront changes (1/4) (#1557) via Juanpe Catalán (@Juanpe)
* `Purchases.canMakePayments`: moved implementation to `StoreKitWrapper` (#1580) via NachoSoto (@NachoSoto)
* `BackendGetIntroEligibilityTests`: fixed test that was passing before anything ran (#1575) via NachoSoto (@NachoSoto)
* `PeriodType`/`PurchaseOwnershipType`/`Store`: conform to `Encodable` (#1551) via NachoSoto (@NachoSoto)
* Improved `EntitlementInfosTests` (#1547) via NachoSoto (@NachoSoto)
* `ProductRequestData`: added `Storefront` for receipt posting (#1505) via NachoSoto (@NachoSoto)
* Added `RawDataContainer` conformances to APITesters (#1550) via NachoSoto (@NachoSoto)
* Simplified `EntitlementInfo.isEqual` (#1548) via NachoSoto (@NachoSoto)
* `CustomerInfo`: moved deprecated property to `Deprecations` (#1549) via NachoSoto (@NachoSoto)
* `PackageType`: simplified `typesByDescription` and implemented `CustomDebugStringConvertible` (#1531) via NachoSoto (@NachoSoto)

## 4.3.0

#### API updates:

- Introduced new `Storefront` type to abstract SK1's `SKStorefront` and SK2's `StoreKit.Storefront`.
- Exposed `Storefront.currentStorefront`.
- Added new `ErrorCode.offlineConnectionError` to differenciate offline errors versus the more generic `.networkError`.
- Added `Purchases-setFirebaseAppInstanceID` to allow associating RevenueCat users with Firebase.
- Added `Purchases.setPushTokenString` as an overload to `Purchases.setPushToken`.
- Renamed `PurchasesDelegate.purchases(_:shouldPurchasePromoProduct:defermentBlock:)` to `PurchasesDelegate.purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase:)` to clarify its usage (see #1460).

#### Other:

- Many improvements to error reporting and logging to help debugging.
- Optimized StoreKit 2 purchasing by eliminating a duplicate API request.
- A lot of under-the-hood improvements, mainly focusing on networking. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!


## 4.2.1

- Fixed a potential race condition when syncing user attributes #1479

## 4.2.0
#### API updates:

- Added new method `setMixpanelDistinctID` as a convenience method for setting the required attribute for the Mixpanel integration #1397

- `getPromotionalOffer` has been deprecated in favor of `promotionalOffer` #1405

- `getEligiblePromotionalOffers` has been deprecated in favor of `eligiblePromotionalOffers` #1405

- `StoreProductDiscount` now includes the `numberOfPeriods` property #1428


#### Other:

- Added workaround for StoreKit 1 incorrectly reporting purchase cancellations #1450

- MagicWeatherSwiftUI now includes an example for using `purchases(:shouldPurchasePromoProduct:defermentBlock:)` #1459

- Various documentation improvements

- Additional under-the-hood improvements, continuing to focus on network requests and tests.

## 4.1.0

#### API updates: 

- Added new method `checkTrialOrIntroDiscountEligibility(product:)`, which allows you to check for intro or discount eligibility for a single `StoreProduct`. 
    https://github.com/RevenueCat/purchases-ios/pull/1354

- Added explicit parameter name for `checkTrialOrIntroDiscountEligibility(productIdentifiers:)`. 
The existing method without the parameter name still work, but is now deprecated. Xcode will offer an auto fix-it for it. 
    https://github.com/RevenueCat/purchases-ios/pull/1362

- Made `StoreProduct` initializers public so they can be used for testing. 

#### Other:

- Added auto-fix-it for `invalidatePurchaserInfoCache` rename
    https://github.com/RevenueCat/purchases-ios/pull/1379

- Docs improvements
- A lot of under-the-hood improvements, mainly focusing on network requests and tests.


## 4.0.0

RevenueCat iOS SDK v4 is here!! 

![Dancing cats](https://media.giphy.com/media/lkbNG2zqzHZUA/giphy.gif)

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/main...4.0.0)

### Migration Guide
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
**Note:** This release is based off of 4.0.0-rc.4. Developers migrating from that version shouldn't see any changes. 

### API changes:
There have been a lot of changes since v3! 

Here are the highlights:

#### Async / Await alternative APIs
New `async / await` alternatives for all APIs that have completion blocks, as well as an `AsyncStream` for CustomerInfo. 

#### New types and cleaned up naming
New types that wrap StoreKit's native types, and we cleaned up the naming of other types and methods for a more consistent experience. 

#### New APIs for Customer Support
You can now use `showManageSubscriptions()` and `beginRefundRequest()` to help your users manage their subscriptions right from the app.

#### Rewritten in Swift 
We [rewrote the SDK in 100% Swift](https://www.revenuecat.com/blog/migrating-our-objective-c-sdk-to-swift). This made the code more uniform and easy to maintain, and helps us better support StoreKit 2. 

#### StoreKit 2 Support [Beta]
**[Experimental]** Introduced support for using StoreKit 2 under the hood for compatible devices. This is currently in beta phase, and disabled by default. 
When enabled, StoreKit 2 APIs will be used under the hood for purchases in compatible devices. You can enable this by configuring the SDK passing `useStoreKit2IfAvailable: true`. 
On devices that don't support StoreKit 2, StoreKit 1 will be used automatically instead. 
 
#### Full API changes list
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

### Documentation: 

We built a new Documentation site with Docc with cleaner and more detailed docs. 
The new documentation can be found [here](https://revenuecat-docs.netlify.app/documentation/Revenuecat). 

## 4.0.0-RC.4

- Fourth RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-rc.3...4.0.0-rc.4)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

RC 4 introduces the following updates:

### API changes:

#### Breaking changes: 
- Replaced `checkPromotionalDiscountEligibility` with `getPromotionalOffer`, which returns a `PromotionalOffer`. 
- Renamed `Purchases/purchase(package:discount:)` and its variants to `Purchases/purchase(package:promotionalOffer:)`. They now take a `PromotionalOffer` instead of a `StoreProductDiscount`.
- [Objective-C only]: Updated type of `StoreProduct.price` and `StoreProductDiscount.price` from `NSDecimal` to the much more useful `NSDecimalNumber`. 

#### Additions:
- Added `StoreProduct.ProductType`, and `StoreProduct.ProductCategory`, which provide extra information about whether a product is a consumable, non-consumable, auto-renewable or non-auto-renewable subscription.
- Added `currencyCode` to `StoreProduct` and `StoreProductDiscount`.
- Added `localizedPriceString` to `StoreProductDiscount`.

### Documentation: 

- Documentation can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 2, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.3/CHANGELOG.latest.md).

## 4.0.0-RC.3

- Third RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-rc.2...4.0.0-rc.3)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

RC 3 introduces the following updates:

### API changes:

- Added `setCleverTapID`, for integration with CleverTap.
- Added `.noIntroOfferExists` as an `IntroEligibilityStatus`, for more granularity when checking for intro pricing eligibility.
- Added `StoreProductDiscount.type`, which allows you to easily tell whether a discount represents a Promo Offer or an Intro Pricing.

### Documentation: 

- Documentation can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Migration fixes

- Fixed a few instances where Xcode's automatic migration tools wouldn't automatically suggest a fix-it for updated code.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 2, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.2/CHANGELOG.latest.md).

## 4.0.0-RC.2

- Second RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-rc.1...4.0.0-rc.2)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

RC 2 introduces the following updates:

### API changes:

- Removed `SubscriptionPeriod.Unit.unknown`. Subscriptions with empty `SubscriptionPeriod` values will have `nil` `subscriptionPeriod` instead.
- Removed `StoreProductDiscount.none`, since it wasn't needed.
- Added `useStoreKit2IfAvailable` (Experimental) configuration option. This is disabled by default.
If enabled, the SDK will use StoreKit 2 APIs for purchases under the hood.
**This is currently in an experimental phase, and we don't recommend using it in production in this build.**

### Documentation: 

- Documentation is now using DocC and it can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Migration fixes

- Fixed a few instances where Xcode's automatic migration tools wouldn't correctly update the code.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 1, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.1/CHANGELOG.latest.md).


## 4.0.0-RC.1

- First RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.10...4.0.0-rc.1)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

RC 1 introduces the following updates:

### API changes:

- `Purchases.paymentDiscount(forProductDiscount:product:completion:)` and `Purchases.paymentDiscount(forProductDiscount:product:)` have been removed. Now, instead of obtaining the `SKPaymentDiscount` from a `SKProductDiscount` to then call `purchase(package:discount:)`, you check eligibility for the promo offer by calling `checkPromotionalDiscountEligibility(forProductDiscount:product:)`, then get the `StoreProductDiscount` directly from the `StoreProduct` and pass that into `purchase(package:discount:)`. 

- `StoreProduct` and `StoreProductDiscount`, replace `SKProduct` and `SKProductDiscount` in the following methods:
    - `Purchases.getProducts(_:completion:)`
    - `Purchases.products(_:)`
    - `Purchases.purchase(product:completion:)`
    - `Purchases.purchase(product:)`
    - `Purchases.purchase(product:discount:completion:)`
    - `Purchases.purchase(product:discount:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `Purchases.purchase(package:discount:)`
    - `PurchasesDelegate.purchases(shouldPurchasePromoProduct:defermentBlock:)`
- `StoreProduct.introductoryPrice` has been renamed to `StoreProduct.introductoryDiscount`
- `StoreTransaction` now includes `quantity`
- Renamed `Purchases.restoreTransactions` to `Purchases.restorePurchases`
- Lowered `StoreProduct.introductoryDiscount` availability to iOS 11.2 and equivalent OS versions
- Added several `@available` annotations for automatic migration from StoreKit types

In addition to all of the changes from beta 10, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-beta.10/CHANGELOG.latest.md)


### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!


## 4.0.0-beta.10

- Tenth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.9...4.0.0-beta.10)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

Beta 10 introduces the following updates:

### Breaking changes:
- A new type, `StoreTransaction`, replaces `SKPaymentTransaction` in the return types of the following methods:
    - `Purchases.purchase(product:completion:)`
    - `Purchases.purchase(package:completion:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `PurchasesDelegate.purchases(shouldPurchasePromoProduct:defermentBlock:)`
    - `CustomerInfo.nonSubscriptionTransactions`
- `StoreProduct.PromotionalOffer` has been renamed to `StoreProduct.StoreProductDiscount`.

In addition to all of the changes from Beta 9, [listed here.](
https://github.com/RevenueCat/purchases-ios/blob/4.0.0-beta.9/CHANGELOG.latest.md)


### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

## 4.0.0-beta.9

- Ninth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.8...4.0.0-beta.9)
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

### Breaking changes:
- `identify`, previously deprecated, has been removed in favor of `logIn`.
- `reset`, previously deprecated, has been removed in favor of `logOut`.
- `Package.product` has been replaced with `Package.storeProduct`. This is an abstraction of StoreKit 1's `SKProduct` and StoreKit 2's `StoreKit.Product`, but it also adds useful features like `pricePerMonth` and `priceFormatter`. The underlying objects from StoreKit are available through `StoreProduct.sk1Product` and `StoreProduct.sk2Product`.

### Xcode version requirements and updated deployment targets
`purchases-ios` v4 requires using Xcode 13.2 or newer. 
It also updates the minimum deployment targets for iOS, macOS and tvOS. 

##### Minimum deployment targets
|  | v3 | v4 |
| :-: | :-: | :-: |
| iOS | 9.0 | 11.0 |
| tvOS | 9.0 | 11.0 |
| macOS | 10.12 | 10.13 |
| watchOS | 6.2 | 6.2 (unchanged) |

### StoreKit 2 support:
- This beta introduces new methods that add functionality using StoreKit 2:
    - `showManageSuscriptions(completion:)`
    - `beginRefundRequest(forProduct:)`
    - `beginRefundRequest(forEntitlement:)`. 
    - `beginRefundRequestForActiveEntitlement()`
 - `checkTrialOrIntroductoryPriceEligibility(productIdentifiers:completion:)` now uses StoreKit 2 if it's available, to make calculation more accurate and fast.
 - A new flag has been introduced to `setup`, `useStoreKit2IfAvailable` (defaults to `false`), to use StoreKit 2 APIs for purchases instead of StoreKit 1.

### `Async` / `Await` alternative APIs
- In purchases-ios v3, `Async` / `Await` alternative APIs were made available through Xcode's auto-generation for Objective-C projects. This beta re-adds the `Async` / `Await` alternative APIs for v4.

### New APIs:

- `showManageSuscriptions(completion:)`: Use this method to show the subscription management for the current user. Depending on where they made the purchase and their OS version, this might take them to the `managementURL`, or open the iOS Subscription Management page. 
- `beginRefundRequestForCurrentEntitlement`: Use this method to begin a refund request for the purchase that granted the current entitlement.
- `beginRefundRequest(forProduct:)`: Use this method to begin a refund request for a purchase, specifying the product identifier.
- `beginRefundRequest(forEntitlement:)`: Use this method to begin a refund request for a purchase, specifying the entitlement identifier.
- Adds an optional `useStoreKit2IfAvailable` parameter to `setup` (defaults to `false`). If enabled, purchases will be done by using StoreKit 2 APIs instead of StoreKit 1. **This is currently experimental, and not all features are supported with StoreKit 2 APIs**.
- Use `verboseLogHandler` or `verboseLogs` to enable more details in logs, including file names, line numbers and method names.

### Known issues:
- Promotional offers and deferred purchases are not currently supported with StoreKit 2. If your app uses either of those, you should omit `useStoreKit2IfAvailable` in `setup` or set it to `false`.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

## 4.0.0-beta.8
- Eighth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Replaced custom DateFormatter with new ISO8601DateFormatter
    https://github.com/RevenueCat/purchases-ios/pull/998
- Put CustomerInfo Logging into LoginHandler function
    https://github.com/RevenueCat/purchases-ios/pull/1095
- Pass underlying NSError localizedDescription
    https://github.com/RevenueCat/purchases-ios/pull/1077
- ErrorCode conforms to CustomNSError to provide description
    https://github.com/RevenueCat/purchases-ios/pull/1022

## 4.0.0-beta.7
- Seventh beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- macOS: improved ErrorCode.storeProblemError to indicate potential cancellation
    https://github.com/RevenueCat/purchases-ios/pull/943
- Log when duplicate subscription time lengths exist during Offering init
    https://github.com/RevenueCat/purchases-ios/pull/954
- PurchasesOrchestrator.paymentDiscount(forProductDiscount:product:completion:): improved error information
    https://github.com/RevenueCat/purchases-ios/pull/957
- Make a public rawData a thing for all our datatypes
    https://github.com/RevenueCat/purchases-ios/pull/956
- Detect ErrorCode.productAlreadyPurchasedError when SKError.unknown is actually caused by it
    https://github.com/RevenueCat/purchases-ios/pull/965

## 4.0.0-beta.6
- Sixth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Add more specific backend error subcodes
    https://github.com/RevenueCat/purchases-ios/pull/927

## 4.0.0-beta.5
- Fifth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Improve error handling for backend errors
    https://github.com/RevenueCat/purchases-ios/pull/922
- Replaced #file with #fileID
    https://github.com/RevenueCat/purchases-ios/pull/921
- Rename a few public APIs to reduce confusion
    https://github.com/RevenueCat/purchases-ios/pull/917

## 4.0.0-beta.4
- Fourth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Purchaser to Customer rename
    https://github.com/RevenueCat/purchases-ios/pull/878
    https://github.com/RevenueCat/purchases-ios/pull/899
- Ensure restoreTransactions called on main thread
    https://github.com/RevenueCat/purchases-ios/pull/908
- Fix logging messages for HTTPClient
    https://github.com/RevenueCat/purchases-ios/pull/901
- Offerings completion not called in edge case
    https://github.com/RevenueCat/purchases-ios/pull/879
- Fix Offerings:completion: not returning if SKProductsRequest hangs
    https://github.com/RevenueCat/purchases-ios/pull/909
- Added setAirshipChannelID
    https://github.com/RevenueCat/purchases-ios/pull/869
    https://github.com/RevenueCat/purchases-ios/pull/877

## 4.0.0-beta.3
- Third beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Fix bug logging the incorrect missing product IDs in `getOfferings`
- Fix MagicWeather sample app with latest updates
- Add caching of completion blocks for `createAlias` and `identify` calls to avoid sending calls with the same parameters at the same time

## 4.0.0-beta.2
- Second beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.
- Our API is now more consistent, `completionBlock` -> `completion` across Swift/ObjC
- Fixed SPM warning relating to excluding `RequiresXcode13` 
- Make parameter labels that were optional pre-migration optional again

## 4.0.0-beta.1
- First beta for RevenueCat (previously Purchases) framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](Sources/DocCDocumentation/DocCDocumentation.docc/V4_API_Migration_guide.md) for API updates.

## 3.12.5
- Cache callbacks for `createAlias` and `identify` to avoid sending multiple calls with same parameters at the same time
    https://github.com/RevenueCat/purchases-ios/pull/874

## 3.12.4
- Updated `getOfferings` call to be performed serially instead of concurrently.
    https://github.com/RevenueCat/purchases-ios/pull/831

## 3.12.3
- Fixed a bug where checkTrialOrIntroductoryPriceEligibility would return `eligible` for products that don't have intro pricing
    https://github.com/RevenueCat/purchases-ios/pull/679
- Calls to `addAttribution` will now automatically get translated into `subscriberAttributes`
    https://github.com/RevenueCat/purchases-ios/pull/609
- Updated links to community and support in `README.md`
    https://github.com/RevenueCat/purchases-ios/commit/209615b9b8b4dc29ad37f51bf211e3710a2fe443
- Excluded swift migration tasks in stale issue detection
    https://github.com/RevenueCat/purchases-ios/pull/698
    https://github.com/RevenueCat/purchases-ios/pull/702

## 3.12.2
- Fixed a bug where calling setDebugLogsEnabled(false) enables debug logs when it should not. 
    https://github.com/RevenueCat/purchases-ios/pull/663

## 3.12.1
- Fixed an issue in some versions of Xcode where compiling would fail with `Definition conflicts with previous value` in `ETagManager.swift`
    https://github.com/revenuecat/purchases-ios/pull/659

## 3.12.0

### Identity V3:

#### New methods
- Introduces `logIn`, a new way of identifying users, which also returns whether a new user has been registered in the system. 
`logIn` uses a new backend endpoint. 
- Introduces `logOut`, a replacement for `reset`. 

#### Deprecations
- deprecates `createAlias` in favor of `logIn`
- deprecates `identify` in favor of `logIn`
- deprecates `reset` in favor of `logOut`
- deprecates `allowSharingAppStoreAccount` in favor of dashboard-side configuration

    https://github.com/RevenueCat/purchases-ios/pull/453
    https://github.com/RevenueCat/purchases-ios/pull/438
    https://github.com/RevenueCat/purchases-ios/pull/506


### Other changes: 

#### Public additions
##### SharedPurchases nullability
- Fixed `sharedPurchases` nullability
- Introduced new property, `isConfigured`, that can be used to check whether the SDK has been configured and `sharedPurchases` won't be `nil`.
    https://github.com/RevenueCat/purchases-ios/pull/508

##### Improved log handling
- Added new property `logLevel`, which provides more granular settings for the log level. Valid values are `debug`, `info`, `warn` and `error`.
- Added new method, `setLogHandler`, which allows developers to use their own code to handle logging, and integrate their existing systems.
    https://github.com/RevenueCat/purchases-ios/pull/481
    https://github.com/RevenueCat/purchases-ios/pull/515


#### Deprecations
- Deprecated `debugLogsEnabled` property in favor of `LogLevel`. Use `Purchases.logLevel = .debug` as a replacement.

#### Other

- Fixed CI issues with creating pull requests
    https://github.com/RevenueCat/purchases-ios/pull/504
- Improved Github Issues bot behavior
    https://github.com/RevenueCat/purchases-ios/pull/507
- Added e-tags to reduce network traffic usage
    https://github.com/RevenueCat/purchases-ios/pull/509
- Fixed a warning in Xcode 13 with an outdated path in Package.swift
    https://github.com/RevenueCat/purchases-ios/pull/522
- Switched to Swift Package Manager for handling dependencies for test targets.
    https://github.com/RevenueCat/purchases-ios/pull/527
- Removed all `fatalError`s from the codebase
    https://github.com/RevenueCat/purchases-ios/pull/529
    https://github.com/RevenueCat/purchases-ios/pull/527
- Updated link for error message when UserDefaults are deleted outside the SDK
    https://github.com/RevenueCat/purchases-ios/pull/531
- Improved many of the templates and added `CODE_OF_CONDUCT.md` to make contributing easier
    https://github.com/RevenueCat/purchases-ios/pull/534
    https://github.com/RevenueCat/purchases-ios/pull/537
    https://github.com/RevenueCat/purchases-ios/pull/589

## 3.11.1
- Updates log message for `createAlias` to improve clarity
    https://github.com/RevenueCat/purchases-ios/pull/498
- Adds `rc_` to all Foundation extensions to prevent name collisions
    https://github.com/RevenueCat/purchases-ios/pull/500

## 3.11.0
- Exposes `ownershipType` in `EntitlementInfo`, which can be used to determine whether a given entitlement was shared by a family member or purchased directly by the user. 
    https://github.com/RevenueCat/purchases-ios/pull/483
- Adds new `RCConfigurationError` type, which will be thrown when SDK configuration errors are detected.
    https://github.com/RevenueCat/purchases-ios/pull/494

## 3.10.7
- Obfuscates calls to `AppTrackingTransparency` to prevent unnecessary rejections for kids apps when the framework isn't used at all. 
    https://github.com/RevenueCat/purchases-ios/pull/486

## 3.10.6
- Fix automatic Apple Search Ads Attribution collection for iOS 14.5
    https://github.com/RevenueCat/purchases-ios/pull/473
- Fixed `willRenew` values for consumables and promotionals
    https://github.com/RevenueCat/purchases-ios/pull/475
- Improves tests for EntitlementInfos
    https://github.com/RevenueCat/purchases-ios/pull/476

## 3.10.5
- Fixed a couple of issues with `.xcframework` output in releases
    https://github.com/RevenueCat/purchases-ios/pull/470
    https://github.com/RevenueCat/purchases-ios/pull/469
- Fix Carthage builds from source, so that end customers can start leveraging XCFramework support for Carthage >= 0.37
    https://github.com/RevenueCat/purchases-ios/pull/471

## 3.10.4
- Added .xcframework output to Releases, alongside the usual fat frameworks.
    https://github.com/RevenueCat/purchases-ios/pull/466
- Added PurchaseTester project, useful to test features while working on `purchases-ios`.
    https://github.com/RevenueCat/purchases-ios/pull/464
- Renamed the old `SwiftExample` project to `LegacySwiftExample` to encourage developers to use the new MagicWeather apps
    https://github.com/RevenueCat/purchases-ios/pull/461
- Updated the cache duration in background from 24 hours to 25 to prevent cache misses when the app is woken every 24 hours exactly by remote push notifications.
    https://github.com/RevenueCat/purchases-ios/pull/463

## 3.10.3
- Added SwiftUI sample app
    https://github.com/RevenueCat/purchases-ios/pull/457
- Fixed a bug where `🍎‼️ Invalid Product Identifiers` would show up even in the logs even when no invalid product identifiers were requested.
    https://github.com/RevenueCat/purchases-ios/pull/456

## 3.10.2
- Re-added `RCReceiptInUseByOtherSubscriberError`, but with a deprecation warning, so as not to break existing apps.
    https://github.com/RevenueCat/purchases-ios/pull/452

## 3.10.1
- Enables improved logging prefixes so they're easier to locate.
    https://github.com/RevenueCat/purchases-ios/pull/441
    https://github.com/RevenueCat/purchases-ios/pull/443
- Fixed issue with Prepare next version CI job, which was missing the install gems step. 
    https://github.com/RevenueCat/purchases-ios/pull/440

## 3.10.0
- Adds a new property `simulateAsksToBuyInSandbox`, that allows developers to test deferred purchases easily.
    https://github.com/RevenueCat/purchases-ios/pull/432
    https://github.com/RevenueCat/purchases-ios/pull/436
- Slight optimization so that offerings and purchaserInfo are returned faster if they're cached.
    https://github.com/RevenueCat/purchases-ios/pull/433
    https://github.com/RevenueCat/purchases-ios/issues/401
- Revamped logging strings, makes log messages from `Purchases` easier to spot and understand. Removed `RCReceiptInUseByOtherSubscriberError`, replaced by `RCReceiptAlreadyInUseError`.
    https://github.com/RevenueCat/purchases-ios/pull/426
    https://github.com/RevenueCat/purchases-ios/pull/428
    https://github.com/RevenueCat/purchases-ios/pull/430
    https://github.com/RevenueCat/purchases-ios/pull/431
    https://github.com/RevenueCat/purchases-ios/pull/422
- Fix deploy automation bugs when preparing the next version PR
    https://github.com/RevenueCat/purchases-ios/pull/434
    https://github.com/RevenueCat/purchases-ios/pull/437

## 3.9.2
- Fixed issues when compiling with Xcode 11 or earlier
    https://github.com/RevenueCat/purchases-ios/pull/416
- Fixed termination warnings for finished SKRequests
    https://github.com/RevenueCat/purchases-ios/pull/418
- Fixed CI deploy bugs
    https://github.com/RevenueCat/purchases-ios/pull/421
- Prevents unnecessary backend calls when the appUserID is an empty string
    https://github.com/RevenueCat/purchases-ios/pull/414
- Prevents unnecessary POST requests when the JSON body can't be correctly formed
    https://github.com/RevenueCat/purchases-ios/pull/415
- Updates git commit pointer for SPM Integration tests
    https://github.com/RevenueCat/purchases-ios/pull/412

## 3.9.1
- Added support for `SKPaymentQueue`'s `didRevokeEntitlementsForProductIdentifiers:`, so entitlements are automatically revoked from a family-shared purchase when a family member leaves or the subscription is canceled.
    https://github.com/RevenueCat/purchases-ios/pull/413
- Added support for automated deploys
    https://github.com/RevenueCat/purchases-ios/pull/411
- Fixed Xcode direct integration failing on Mac Catalyst builds
    https://github.com/RevenueCat/purchases-ios/pull/419

## 3.9.0
- Added support for StoreKit Config Files and StoreKitTest testing
    https://github.com/RevenueCat/purchases-ios/pull/407
- limit running integration tests to tags and release branches
    https://github.com/RevenueCat/purchases-ios/pull/406
- added deployment checks
    https://github.com/RevenueCat/purchases-ios/pull/404

## 3.8.0
- Added a silent version of restoreTransactions, called `syncPurchases`, meant to be used by developers performing migrations for other systems.
    https://github.com/RevenueCat/purchases-ios/pull/387
    https://github.com/RevenueCat/purchases-ios/pull/403
- Added `presentCodeRedemptionSheet`, which allows apps to present code redemption sheet for offer codes
    https://github.com/RevenueCat/purchases-ios/pull/400
- Fixed sample app on macOS, which would fail to build because the watchOS app was embedded into it
    https://github.com/RevenueCat/purchases-ios/pull/402

## 3.7.6
- Fixed a race condition that could cause a crash after deleting and reinstalling the app
    https://github.com/RevenueCat/purchases-ios/pull/383
- Fixed possible overflow when performing local receipt parsing on 32-bit devices
    https://github.com/RevenueCat/purchases-ios/pull/384
- Fixed string comparison when deleting synced subscriber attributes
    https://github.com/RevenueCat/purchases-ios/pull/385
- Fixed docs-deploy job
    https://github.com/RevenueCat/purchases-ios/pull/386
- Fixed a typo in a RCPurchases.h
    https://github.com/RevenueCat/purchases-ios/pull/380

## 3.7.5
- Move test dependencies back to carthage
    https://github.com/RevenueCat/purchases-ios/pull/371
    https://github.com/RevenueCat/purchases-ios/pull/373
- fixed tests for iOS < 12.2
    https://github.com/RevenueCat/purchases-ios/pull/372
- Make cocoapods linking dynamic again
    https://github.com/RevenueCat/purchases-ios/pull/374

## 3.7.4
- Fix parsing of dates in receipts with milliseconds
    https://github.com/RevenueCat/purchases-ios/pull/367
- Add jitter and extra cache for background processes
    https://github.com/RevenueCat/purchases-ios/pull/366
- Skip install to fix archives with direct integration
    https://github.com/RevenueCat/purchases-ios/pull/364

## 3.7.3
- Renames files with names that caused issues when building on Windows
    https://github.com/RevenueCat/purchases-ios/pull/362
- Fixes crash when parsing receipts with an unexpected number of internal containers in an IAP ASN.1 Container
    https://github.com/RevenueCat/purchases-ios/pull/360
- Fixes crash when sending `NSNull` attributes to `addAttributionData:fromNetwork:`
    https://github.com/RevenueCat/purchases-ios/pull/359
- Added starter string constants file for logging
    https://github.com/RevenueCat/purchases-ios/pull/339

## 3.7.2
- Updates the Pod to make it compile as a static framework, fixing build issues on hybrid SDKs. Cleans up imports in `RCPurchases.h`.
    https://github.com/RevenueCat/purchases-ios/pull/353
- Fixes Catalyst builds and build warnings
    https://github.com/RevenueCat/purchases-ios/pull/352
    https://github.com/RevenueCat/purchases-ios/pull/351

## 3.7.1
-  Fix 'Invalid bundle' validation error when uploading builds to App Store using Carthage or binary
    https://github.com/RevenueCat/purchases-ios/pull/346

## 3.7.0
- Attribution V2:
        - Deprecated `addAttributionData:fromNetwork:` and `addAttributionData:fromNetwork:forNetworkUserId:` in favor of `setAdjustId`, `setAppsflyerId`, `setFbAnonymousId`, `setMparticleId`
        - Added support for OneSignal via `setOnesignalId`
        - Added `setMediaSource`, `setCampaign`, `setAdGroup`, `setAd`, `setKeyword`, `setCreative`, and `collectDeviceIdentifiers`
    https://github.com/RevenueCat/purchases-ios/pull/321
    https://github.com/RevenueCat/purchases-ios/pull/340
    https://github.com/RevenueCat/purchases-ios/pull/331
- Prevent unnecessary receipt posts
    https://github.com/RevenueCat/purchases-ios/pull/323
- Improved migration process for legacy Mac App Store apps moving to Universal Store 
    https://github.com/RevenueCat/purchases-ios/pull/336
- Added new SKError codes for Xcode 12
    https://github.com/RevenueCat/purchases-ios/pull/334
    https://github.com/RevenueCat/purchases-ios/pull/338
- Renamed StoreKitConfig schemes
    https://github.com/RevenueCat/purchases-ios/pull/329
- Fixed an issue where cached purchaserInfo would be returned after invalidating purchaserInfo cache
    https://github.com/RevenueCat/purchases-ios/pull/333
- Fix cocoapods and carthage release scripts 
    https://github.com/RevenueCat/purchases-ios/pull/324
- Fixed a bug where `checkIntroTrialEligibility` wouldn't return when calling it from an OS version that didn't support intro offers
    https://github.com/RevenueCat/purchases-ios/pull/343

## 3.6.0
- Fixed a race condition with purchase completed callbacks
	https://github.com/RevenueCat/purchases-ios/pull/313
- Made RCTransaction public to fix compiling issues on Swift Package Manager
	https://github.com/RevenueCat/purchases-ios/pull/315
- Added ability to export XCFrameworks
	https://github.com/RevenueCat/purchases-ios/pull/317
- Cleaned up dispatch calls
	https://github.com/RevenueCat/purchases-ios/pull/318
- Created a separate module and framework for the Swift code
	https://github.com/RevenueCat/purchases-ios/pull/319
- Updated release scripts to be able to release the new Pod as well
	https://github.com/RevenueCat/purchases-ios/pull/320
- Added a local receipt parser, updated intro eligibility calculation to perform on device first
	https://github.com/RevenueCat/purchases-ios/pull/302
- Fix crash when productIdentifier or payment is nil.
    https://github.com/RevenueCat/purchases-ios/pull/297
- Fixes ask-to-buy flow and will now send an error indicating there's a deferred payment.
    https://github.com/RevenueCat/purchases-ios/pull/296
- Fixes application state check on app extensions, which threw a compilation error.
    https://github.com/RevenueCat/purchases-ios/pull/303
- Restores will now always refresh the receipt.
    https://github.com/RevenueCat/purchases-ios/pull/287
- New properties added to the PurchaserInfo to better manage non-subscriptions.
    https://github.com/RevenueCat/purchases-ios/pull/281
- Bypass workaround in watchOS 7 that fixes watchOS 6.2 bug where devices report wrong `appStoreReceiptURL`
	https://github.com/RevenueCat/purchases-ios/pull/330
- Fix bug where 404s in subscriber attributes POST would mark them as synced
    https://github.com/RevenueCat/purchases-ios/pull/328

## 3.5.3
- Addresses an issue where subscriber attributes might not sync correctly if subscriber info for the user hadn't been synced before the subscriber attributes sync was performed.
    https://github.com/RevenueCat/purchases-ios/pull/327

## 3.5.2
- Feature/defer cache updates if woken from push notification
https://github.com/RevenueCat/purchases-ios/pull/288

## 3.5.1
- Removes all references to ASIdentifierManager and advertisingIdentifier. This should help with some Kids apps being rejected 
https://github.com/RevenueCat/purchases-ios/pull/286
- Fix for posting wrong duration P0D on consumables
https://github.com/RevenueCat/purchases-ios/pull/289

## 3.5.0
- Added a sample watchOS app to illustrate how to integrate in-app purchases on watchOS with RevenueCat
https://github.com/RevenueCat/purchases-ios/pull/263
- Fixed build warnings from Clang Static Analyzer
https://github.com/RevenueCat/purchases-ios/pull/265
- Added StoreKit Configuration files for local testing + new schemes configured to use them. 
https://github.com/RevenueCat/purchases-ios/pull/267
https://github.com/RevenueCat/purchases-ios/pull/270
- Added GitHub Issue Templates
https://github.com/RevenueCat/purchases-ios/pull/269

## 3.4.0
- Added `proxyKey`, useful for kids category apps, so that they can set up a proxy to send requests through. **Do not use this** unless you've talked to RevenueCat support about it. 
https://github.com/RevenueCat/purchases-ios/pull/258
- Added `managementURL` to purchaserInfo. This provides an easy way for apps to create Manage Subscription buttons that will correctly redirect users to the corresponding subscription management page on all platforms. 
https://github.com/RevenueCat/purchases-ios/pull/259
- Extra fields sent to the post receipt endpoint: `normal_duration`, `intro_duration` and `trial_duration`. These will feed into the LTV model for more accurate LTV values. 
https://github.com/RevenueCat/purchases-ios/pull/256
- Fixed a bug where if the `appUserID` was not found in `NSUserDefaults` and `createAlias` was called, the SDK would create an alias to `(null)`. 
https://github.com/RevenueCat/purchases-ios/pull/255
- Added [mParticle](https://www.mparticle.com/) as an option for attribution. 
https://github.com/RevenueCat/purchases-ios/pull/251
- Fixed build warnings for Mac Catalyst
https://github.com/RevenueCat/purchases-ios/pull/247
- Simplified Podspec and minor cleanup
https://github.com/RevenueCat/purchases-ios/pull/248


## 3.3.1
- Fixed version numbers that accidentally included the `-SNAPSHOT` suffix

## 3.3.0
- Reorganized file system structure for the project
	https://github.com/RevenueCat/purchases-ios/pull/242
- New headers for observer mode and platform version
    https://github.com/RevenueCat/purchases-ios/pull/237
    https://github.com/RevenueCat/purchases-ios/pull/240
    https://github.com/RevenueCat/purchases-ios/pull/241
- Fixes subscriber attributes migration edge cases
	https://github.com/RevenueCat/purchases-ios/pull/233
- Autodetect appUserID deletion
    https://github.com/RevenueCat/purchases-ios/pull/232
    https://github.com/RevenueCat/purchases-ios/pull/236
- Removes old trello link
    https://github.com/RevenueCat/purchases-ios/pull/231
- Removes unused functions
    https://github.com/RevenueCat/purchases-ios/pull/228
- Removes unnecessary no-op call to RCBackend's postSubscriberAttributes
	https://github.com/RevenueCat/purchases-ios/pull/227
- Fixes a bug where subscriber attributes are deleted when an alias is created.
    https://github.com/RevenueCat/purchases-ios/pull/222
- Fixes crash when payment.productIdentifier is nil
    https://github.com/RevenueCat/purchases-ios/pull/226
- Updates invalidatePurchaserInfoCache docs 
    https://github.com/RevenueCat/purchases-ios/pull/223

## 3.2.2
- Fixed build warnings about nil being passed to callees that require non-null parameters
    https://github.com/RevenueCat/purchases-ios/pull/216

## 3.2.1
- Fixed build warnings on tvOS and API availability checks
    https://github.com/RevenueCat/purchases-ios/pull/212

## 3.2.0
- Added support for WatchOS and tvOS, fixed some issues with pre-processor macro checks on different platforms. 
    https://github.com/RevenueCat/purchases-ios/pull/183

## 3.1.2
- Added an extra method, `setPushTokenString`, to be used by multi-platform SDKs that don't 
have direct access to the push token as `NSData *`, but rather as `NSString *`.
    https://github.com/RevenueCat/purchases-ios/pull/208

## 3.1.1
- small fixes to docs and release scripts: 
    - the release script was referencing a fastlane lane that was under the group ios, 
    so it needs to be called with ios first
    - the docs for setPushToken in RCPurchases.m say to pass an empty string or nil to erase data, 
    however since the param is of type NSData, you can't pass in an empty string.
    
    https://github.com/RevenueCat/purchases-ios/pull/203
    
## 3.1.0
- Added Subscriber Attributes, which allow developers to store additional, structured information 
for a user in RevenueCat. More info: // More info: https://docs.revenuecat.com/docs/user-attributes.
https://github.com/RevenueCat/purchases-ios/pull/196
- Fixed an issue where the completion block of `purchaserInfoWithCompletion` would get called more than once if cached information existed and was stale. https://github.com/RevenueCat/purchases-ios/pull/199
- Exposed `original_purchase_date`, which can be useful for migrating data for developers who don't increment the build number on every release and therefore can't rely on it being different on all releases.
- Addressed a couple of build warnings: https://github.com/RevenueCat/purchases-ios/pull/200

## 3.0.4
- Fixed an issue where Swift Package Manager didn't pick up the new Caching group from 3.0.3 https://github.com/RevenueCat/purchases-ios/issues/176

## 3.0.3
- Added new method to invalidate the purchaser info cache, useful when promotional purchases are granted from outside the app. https://github.com/RevenueCat/purchases-ios/pull/168
- Made sure we dispatch offerings, and purchaser info https://github.com/RevenueCat/purchases-ios/pull/146

## 3.0.2
- Fixes an issue where Apple Search Ads attribution information would be sent even if the user hadn't clicked on 
a search ad.

## 3.0.1
- Adds observer_mode to the backend post receipt call.

## 3.0.0
- Support for new Offerings system.
- Deprecates `makePurchase` methods. Replaces with `purchasePackage`
- Deprecates `entitlements` method. Replaces with `offerings`
- See our migration guide for more info: https://docs.revenuecat.com/v3.0/docs/offerings-migration
- Added `Purchases.` prefix to Swift classes to avoid conflicts https://github.com/RevenueCat/purchases-ios/issues/131
- Enabled base internationalisation to silence a warning (#119)
- Migrates tests to Swift 5 (#138)
- New identity changes (#133):
  - The `.createAlias()` method is no longer required, use .identify() instead
  - `.identify()` will create an alias if being called from an anonymous ID generated by RevenueCat
  - Added an `isAnonymous` property to `Purchases.shared`
  - Improved offline use

## 2.6.1
- Support for Swift Package Manager
- Adds a conditional to protect against nil products or productIdentifier (https://github.com/RevenueCat/purchases-ios/pull/129)

## 2.6.0
- Deprecates `activeEntitlements` in `RCPurchaserInfo` and adds `entitlements` object to `RCPurchaserInfo`. For more info look into https://docs.revenuecat.com/docs/purchaserinfo

## 2.5.0
- **BREAKING CHANGE**: fixed a typo in `addAttributionData` Swift's name.
- Error logs for AppsFlyer if using deprecated `rc_appsflyer_id`
- Error logs for AppsFlyer if missing networkUserID

## 2.4.0
- **BUGFIX**: `userId` parameter in identify is not nullable anymore.
- **DEPRECATION**: `automaticAttributionCollection` is now deprecated in favor of `automaticAppleSearchAdsAttributionCollection` since it's a more clear name.
- **NEW FEATURE**: UIKitForMac support.
- **NEW FEATURE**: Facebook Ads Attribution support https://docs.revenuecat.com/docs/facebook-ads.

## 2.3.0
- `addAttribution` is now a class method that can be called before the SDK is configured.
- `addAttribution` will automatically add the `rc_idfa` and `rc_idfv` parameters if the `AdSupport` and `UIKit` frameworks are included, respectively.
- A network user identifier can be send to the `addAttribution` function, replacing the previous `rc_appsflyer_id` parameter.
- Apple Search Ad attribution can be automatically collected by setting the `automaticAttributionCollection` boolean to `true` before the SDK is configured.
- Adds an optional configuration boolean `observerMode`. This will set the value of `finishTransactions` at configuration time.
- Header updates to include client version which will be used for debugging and reporting in the future.

## 2.2.0
- Adds subscription offers

## 2.1.1
- Avoid refreshing receipt everytime restore is called

## 2.1.0
- Adds userCancelled as a parameter to the completion block of the makePurchase function.
- Better error codes.

## 2.0.0
- Refactor to all block based methods
- Optional delegate method to receive changes in Purchaser Info
- Ability to turn on detailed logging by setting `debugLogsEnabled`

## 1.2.1
- Adds support for Tenjin

## 1.2.0
- Singleton management handled by the SDK
- Adds reset, identify and create alias calls

## 1.1.5
- Conform RCPurchasesDelegate to NSObject
- Adds requestDate to the purchaser info to avoid edge cases
- Add iOS 11.2 availability annotations

## 1.1.4
- Make RCPurchases initializer return a non-optional

## 1.1.3
- Add option for disabling transaction finishing.

## 1.1.2
- Fix to ensure prices are properly collected when using entitlements

## 1.1.1
- Delegate methods now only dispatch if they are not on the main thread. This makes sure the cached PurchaserInfo is delivered on setting the delegate.
- Allow developer to indicate anonymous ID behavior
- Add "Purchases.h" to CocoaPods headers

## 1.1.0
- Attribution! You can now pass attribution data from Apple Search Ads, AppsFlyer, Adjust and Branch. You can then view the ROI of your campaigns, including revenue coming from referrals.

## 1.0.5
- Fix for entitlements will now have null active products if the product is not available from StoreKit

## 1.0.4
- Fix version number in Plist for real

## 1.0.3
- Fix version number in Plist

## 1.0.2
- Improved error handling for fetching entitlements
- Delegate methods are now guaranteed to run on the main thread

## 1.0.1
- Fix a bug with parsing dates for Thai locales

## 1.0.0
- Oh my oh whoa! We made it to version one point oh!
- Entitlements now supported by the SDK. See [the guide](https://docs.revenuecat.com/v1.0/docs/entitlements) for more info.
- Improved caching of `RCPurchaserInfo`

## 0.12.0
- Remove Carthage dependencies
- Add delegate methods for restoring
- Allow RCPurchases to be instantiated with a UserDefaults object, useful for syncing between extensions

## 0.11.0
- RCPurchases now caches the most recent RCPurchaserInfo. Apps no longer need to implement there own offline caching of subscription status.
- Change block based methods to use delegate. restoreTransactions and updatePurchaserInfo no longer take blocks. This means all new RCPurchaserInfo objects will be sent via the delegate methods.
- macOS support. Purchases now works with macOS. Contact jacob@revenuecat.com if interested in beta testing.

## 0.10.2
- Workaround for a StoreKit issue (38476489) where priceLocale is missing on promotional purchases

## 0.10.1
- Fix cache preventing prices from being posted

## 0.10.0
- Prevent race conditions refreshing receipts.
- Make processing of multiple receipt posts more efficient.
- Add support for original application version so users can be grandfathered easily

## 0.9.0
- Add support of checking eligibilty of introductory prices. RevenueCat will now be able to tell you definitively what version of a product you should present in your UI.

## 0.8.0
- Add support of initializing without an `appUserID`. This standardizes and simplifies behavior for apps without account systems.

## 0.7.0
- Change `restoreTransactionsForAppStoreAccount:` to take a completion block since it no long relies on the app store queue. Removed delegate methods.
- Added `updatedPurchaserInfo:` that allows force refreshing of `RCPurchaserInfo`. Useful if your app needs the latest purchaser info.
- Removed `makePurchase:quantity:`.
- Add `nonConsumablePurchases` on `RCPurchaserInfo`. Non-consumable purchases will now Just Work (tm).

## 0.6.0
- Add support for [promotional purchases](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/PromotingIn-AppPurchases/PromotingIn-AppPurchases.html).
- Adds support for `appUserId`s with non-url compatable characters

## 0.5.0
- Add support for restoring purchases via `restoreTransactionsForAppStoreAccount`
- Add support for iOS 9.0

## 0.4.0
- Add tracking of product prices to allow for real time revenue tracking on RevenueCat.com

## 0.3.0
- Improve handling of Apple and Backend errors
- Handles missing receipts case
- Fixed issue with timezone parsing

## 0.2.0
- Rename shared secret to API key
- Remove `purchaserInfoWithCompletion`, now `RCPurchases` fetches updated purchaser info automatically on `UIApplicationDidBecomeActive`.
- Remove `purchasing` KVO property

## 0.1.0

- Initial version
- Requires access to the private beta, email jacob@revenuecat.com for a key.
