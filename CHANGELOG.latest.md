### Other Changes
* Updated Gemfile.lock via NachoSoto (@NachoSoto)
* Removed submodule via NachoSoto (@NachoSoto)
* Merge branch 'paywalls' into release/4.25.7 via NachoSoto (@NachoSoto)
* `Paywalls`: update snapshot generation with new separate git repo (#3116)

Follow up to #3115.

Note that this won't update the commit that the branch is pointing to.
But one all PRs are merged, one can easily update that one commit in
your local PR.

Example:
https://github.com/RevenueCat/purchases-ios-snapshots/pull/4/files via NachoSoto (@NachoSoto)
* `Purchases`: don't clear intro eligibility / purchased products cache on first launch (#3067)

These caches are important, especially for `RevenueCatUI`.
Without this fix, launching the app was doing this:
- Pre-warming cache
- Pre-warming cache a second time (to be fixed by a separate PR)
- Clearing cache

Which meant that the cache wasn't really warm when launching paywalls.

To fix that, this only clears the cache after receiving an actual
change.

I've also removed
`CustomerInfoManager.sendCachedCustomerInfoIfAvailable` because it
wasn't used. via NachoSoto (@NachoSoto)
* `CI`: add workaround for `Carthage` timing out (#3119)

`xcodebuild -list` loads all SPM dependencies, which includes our own
repo (necessary to test `RevenueCat_CustomEntitlementComputation`):
```
Resolve Package Graph

Resolve Package Graph

Resolved source packages:
  CwlPreconditionTesting: https://github.com/mattgallagher/CwlPreconditionTesting.git @ 2.1.2
  swift-snapshot-testing: https://github.com/pointfreeco/swift-snapshot-testing @ 1.11.1
  CwlCatchException: https://github.com/mattgallagher/CwlCatchException.git @ 2.1.2
  Nimble: https://github.com/quick/nimble @ 10.0.0
  OHHTTPStubs: https://github.com/AliSoftware/OHHTTPStubs.git @ 9.1.0
  RevenueCat: https://github.com/RevenueCat/purchases-ios @ main
```

`Carthage` has as [hardcoded timeout of 60
seconds](https://github.com/Carthage/Carthage/blob/0.39.0/Source/CarthageKit/XCDBLDExtensions.swift#L79).
This has been failing ti due to our repo size growing combined with
CircleCI's network issues.

To prevent that, this updates all lanes that use `Carthage` to pre-load
SPM dependencies by calling `xcodebuild -list` first. via NachoSoto (@NachoSoto)
* `Paywalls`: add support for CTA button gradients (#3121)

![Screenshot 2023-08-29 at 15 41
31](https://github.com/RevenueCat/purchases-ios/assets/685609/349d7d84-ac3b-4a81-85d8-d876d63dc4b6) via NachoSoto (@NachoSoto)
* `Paywalls`: template 5 (#3095) via NachoSoto (@NachoSoto)
* `Paywalls`: replaced submodule with `gitignore`d reference (#3125)

The `submodule` approach had 2 issues:
- Inconsistent results if users don't have a valid SSH key (#3124)
- `SPM` actually clones the submodule, which users don't need

This new approach only fetches the snapshots through a new `fastlane
fetch_snapshots` lane.

#3116 will be updated to support this. via NachoSoto (@NachoSoto)
* `Catalyst`: fixed a couple of Catalyst build warnings (#3120) via NachoSoto (@NachoSoto)
* `Paywalls`: reference test snapshots from submodule (#3115)

See https://github.com/RevenueCat/purchases-ios-snapshots via NachoSoto (@NachoSoto)
* `Paywalls`: reference test snapshots from submodule (#3115)

See https://github.com/RevenueCat/purchases-ios-snapshots via NachoSoto (@NachoSoto)
* Merge branch 'paywalls' into release/4.25.7 via NachoSoto (@NachoSoto)
* `Paywalls`: removed `presentedPaywallViewMode` (#3109)

We're going to track this in a different way in the future. via NachoSoto (@NachoSoto)
* `Paywalls`: remove duplicate `RevenueCat` scheme to fix Carthage (#3105) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed iOS 12 build (#3104) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed template 2 inconsistent spacing (#3091)

![Screenshot 2023-08-25 at 12 22
57](https://github.com/RevenueCat/purchases-ios/assets/685609/e8a5a662-7374-402f-b6d2-f2a306ea00e0)

![Screenshot 2023-08-25 at 12 18
02](https://github.com/RevenueCat/purchases-ios/assets/685609/1d7fe837-657b-435e-9d66-6baa218677c6) via NachoSoto (@NachoSoto)
* `Paywalls`: improved test custom paywall (#3089)

Credit to @charliemchapman for the design + implementation:


![simulator_screenshot_B5041028-848B-462E-A270-573A777FC53D](https://github.com/RevenueCat/purchases-ios/assets/685609/f45dd300-579e-4311-89e6-55a1f8a9ea71) via NachoSoto (@NachoSoto)
* `Paywalls`: avoid warming up cache multiple times (#3068)

This prevents us from warming up the cache twice on app launch (because
of the explicit call in `Purchases.init` +
`applicationWillEnterForeground`).

I turned `PaywallCacheWarming` into an `actor` to simplify thread-safety
of the internal state. via NachoSoto (@NachoSoto)
* `Paywalls`: added all localization (#3080) via NachoSoto (@NachoSoto)
* `Paywalls`: temporarily disable `PaywallTemplate.template4` (#3088)

It's not available in the dashboard so we don't want the first SDK
releases to support it yet.

I was going to remove the `enum` `case` but that required commenting out
a lot of extra code.
This is a much simpler one-line change. via NachoSoto (@NachoSoto)
* `Paywalls`: enabled `Catalyst` support (#3087)

![Screenshot 2023-08-24 at 15 18
51](https://github.com/RevenueCat/purchases-ios/assets/685609/7a243aad-1558-419b-b2f8-b39f620794f4)

With "native" design:
![Screenshot 2023-08-25 at 10 11
10](https://github.com/RevenueCat/purchases-ios/assets/685609/8d0c529d-0b5a-4ca5-b7b0-7462187f6864) via NachoSoto (@NachoSoto)
* `Paywalls`: iPad polish (#3061) via NachoSoto (@NachoSoto)
* `Paywalls`: added MIT license to all headers (#3084)

`Xcode` doesn't allow customizing the header (looks like maybe it worked
at some point but not anymore:
https://stackoverflow.com/questions/67614785/changing-the-default-header-comment-license-in-swift-package).

At least this adds the license to all the initial files in the package. via NachoSoto (@NachoSoto)
* `Paywalls`: improved unselected package background color (#3079)

From the design feedback. via NachoSoto (@NachoSoto)
* `Paywalls`: handle already purchased state (#3046) via NachoSoto (@NachoSoto)
* `Paywalls`: only dismiss `PaywallView` when explicitly presenting it with `.presentPaywallIfNeeded` (#3075) via NachoSoto (@NachoSoto)
* `Paywalls`: add support for generating snapshots on CI (#3055) via NachoSoto (@NachoSoto)
* `Paywalls`: removed unnecessary `PaywallFooterView` (#3064)

Since this is no longer `public`, it was just duplicating all the API
surface area of `PaywallView` in an unnecessary way. This became clear
in #3046 when a lot of the same changes had to be made in both view
types. via NachoSoto (@NachoSoto)
* `Paywalls`: new `PaywallFooterView` to replace `modes` (#3051)

## Motivation

It was a little unclear how and when to use the different `PaywallView`
modes (`.fullscreen`, `.card`, and `.condensedCard`). The actual
functionality of the modes is great but they seemed like three different
components in one view and it was just trying to do too much for one
public API.

This change will...
- Remove modes from being a public parameter in `PaywallView` and only
allow it to be full screen
- Create a new `PaywallFooterView` which will combine `.footer`
(previously `.card`) and `.condensedFooter` (previously
`.condensedCard`)
- Removed the `modes` parameter from `PaywallView`

### New `PaywallFooterView`

- Wraps `PaywallView` and will only choose between `.footer` and
`.footerCondensed`
- Currently offers a `condensed` parameter but this might be switched to
being a remote setting inside of `PaywalData`

### New `.paywallFooter()` view modifier

- Easy way for developers to place `PaywallFooterView` where it is
supposed to be placed
- This places the view in `.safeAreaInset(edge: .bottom)`
- This works on any view but is ideal in `ScrollView` as it will
automatically handle adjusting the scroll insets with the paywalls size

### New footer structure and animation (with some hacks)

- No parts of `PaywallFooterView` uses `.overlay` anymore
  - The whole grows in `.condensedFooter` when "All Plans" is toggled

## Demo

### My sample app


https://github.com/RevenueCat/purchases-ios/assets/401294/17c52bba-956d-404e-b991-a2272e7fc4f1

### Simple sample app 


https://github.com/RevenueCat/purchases-ios/assets/401294/4ea94156-8367-4dea-9640-0cce8ffa1deb

---------

Co-authored-by: NachoSoto <ignaciosoto90@gmail.com> via Josh Holtz (@joshdholtz)
* `Paywalls`: rename card to footer (#3049)

Rename "card" to "footer" to because that is how we expect developers to
use the current implementation of the non-fullscreen modes as a footer
to their custom paywalls.

- Renamed `card` to `footer`
- Renamed `condensedCard` to `condensedFooter`

---------

Co-authored-by: NachoSoto <ignaciosoto90@gmail.com> via Josh Holtz (@joshdholtz)
* `Paywalls`: changed `total_price_and_per_month` to include period (#3044)

From beta feedback. This allows distinguishing subscriptions versus
non-subscriptions. via NachoSoto (@NachoSoto)
* `Paywalls`: internal documentation for implementing templates (#3053)

This is a start of some basic documentation for some basic principles to
follow when implementing new templates. via NachoSoto (@NachoSoto)
* `Paywalls`: finished `iOS 15` support (#3043) via NachoSoto (@NachoSoto)
* `Paywalls`: validate `PaywallData` to ensure displayed data is always correct (#3019)

See
https://docs.google.com/document/d/1oLZR77apAjZf04hDzlrJpPaFV0xhuQ1-hApsNBohhfA/edit

This simplifies `PaywallView`: the validated `PaywallData` is what's
always displayed, and a `DebugErrorView` containing an error description
will potentially explain why a default paywall is being displayed.

### Validations:

- [x] `Offering` contains a `PaywallData`
- [x] `PaywallLocalizedConfiguration` contains no unrecognized variables
- [x] `PaywallIcon`s are all recognized
- [x] `PaywallTemplate` is recognized via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `total_price_and_per_month` for custom monthly packages (#3027) via NachoSoto (@NachoSoto)
* `Paywalls`: tweaking colors on template 2&3 (#3011) via NachoSoto (@NachoSoto)
* `Paywalls`: changed snapshots to scale 1 (#3016)

This reduces the total size of all paywall snapshots from 247MB to 34MB. via NachoSoto (@NachoSoto)
* `Paywalls`: replaced `defaultLocale` with `preferredLocales` (#3003)

Depends on #3002.

This is the new logic for finding the locale to use

```swift
var localizedConfiguration: LocalizedConfiguration {
    let locales: [Locale] = [.current] + Locale.preferredLocales

    return locales
        .lazy
        .compactMap(self.config(for:))
        .first ?? self.fallbackLocalizedConfiguration
}
```

And note that `config(for:)` is a fuzzy-lookup (#2847). via NachoSoto (@NachoSoto)
* `Paywalls`: improved `PaywallDisplayMode.condensedCard` layout (#3001) via NachoSoto (@NachoSoto)
* `Paywalls`: `.card` and `.condensedCard` modes (#2995) via NachoSoto (@NachoSoto)
* `Paywalls`: prevent multiple concurrent purchases (#2991) via NachoSoto (@NachoSoto)
* `Paywalls`: improved variable warning (#2984) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed horizontal padding on template 1 (#2987) via NachoSoto (@NachoSoto)
* `Paywalls`: changed `FooterView` to always use `text1` color (#2992) via NachoSoto (@NachoSoto)
* `Paywalls`: retry test failures (#2985)

This avoids false negatives due to flaky failures. via NachoSoto (@NachoSoto)
* `Paywalls`: send presented `PaywallViewMode` with purchases (#2859)

I've moved `PaywallViewMode` from `RevenueCatUI` to `RevenueCat`. This
uses the same approach as #2645. This method is `public` so it can be
used from `RevenueCatUI`, but the documentation stays its purpose.

The behavior is covered with integration tests and a snapshot test.

Depends on https://github.com/RevenueCat/khepri/pull/6364. via NachoSoto (@NachoSoto)
* `Paywalls`: added support for custom fonts (#2988)

This adds a new `PaywallFontProvider` `protocol` as well as 2
implementations:
- `DefaultPaywallFontProvider`: exactly equivalent to the existing font
behavior
- `CustomPaywallFontProvider` allows using a custom font name and still
use dynamic type

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/3659576c-a957-4f33-86ba-e3633520aa17)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/250304ae-c2e7-4726-888c-bb454651664e) via NachoSoto (@NachoSoto)
* `Paywalls`: improved template 2 unselected packages (#2982)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/b5f9654d-e326-4754-adba-04f29f38bd5e) via NachoSoto (@NachoSoto)
* `Paywalls`: fix template 2 selected text offer details color (#2975)

Selected offer details text color was using background color

Switched selected offer details foreground to using `accent1Color`

![Simulator Screenshot - iPhone 14 Pro - 2023-08-07 at 06 38
13](https://github.com/RevenueCat/purchases-ios/assets/401294/90f66345-6458-45ab-9b4d-4eeba9b5d571)

---------

Co-authored-by: NachoSoto <ignaciosoto90@gmail.com> via Josh Holtz (@joshdholtz)
* `Paywalls`: warm-up image cache (#2978)

This relies on `AsyncImage` using `URLSession.shared`

I've tested this, and the app doesn't even make a request the second
time around because the images are caches on disk. via NachoSoto (@NachoSoto)
* `Paywalls`: extracted `PaywallCacheWarming` (#2977)

This refactors #2860 extracting it to a separate type so we can easily
extend it to pre-warm the image cache as well (PWL-10). via NachoSoto (@NachoSoto)
* `Paywalls`: fixed color in template 3 (#2980)

Thanks to @joshdholtz for finding this. via NachoSoto (@NachoSoto)
* `Paywalls`: improved default template (#2973)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/f84357af-76a3-4431-9653-bcc863a7034b)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/1c19cb15-b7b3-4d48-9441-3b6187dd2713) via NachoSoto (@NachoSoto)
* `Paywalls`: added links to documentation (#2974) via NachoSoto (@NachoSoto)
* `Paywalls`: updated template names (#2971) via NachoSoto (@NachoSoto)
* `Paywalls`: updated variable names (#2970)

These match the new agreed upon variables.

- Improved the localized unit abbreviations
- Refactored `VariableDataProvider` so all the logic is now in `Package`
- Added new tests for `Package` variables via NachoSoto (@NachoSoto)
* `Paywalls`: added JSON debug screen to `debugRevenueCatOverlay` (#2972) via NachoSoto (@NachoSoto)
* `Paywalls`: multi-package horizontal template  (#2949)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/a5cc3f4b-99d0-40a2-8a85-82f243383978) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed template 3 icon aspect ratio (#2969)

See snapshots.
Thanks @guido732 for pointing this out. via NachoSoto (@NachoSoto)
* `Paywalls`: iOS 17 tests on CI (#2955) via NachoSoto (@NachoSoto)
* `Paywalls`: deploy `debug` sample app (#2966)

I broke something and noticed that I wasn't seeing the error in
TestFlight. Because this is a test app, it's useful to see the debug
errors there too. via NachoSoto (@NachoSoto)
* `Paywalls`: sort offerings list in sample app (#2965)

I noticed that every time I opened this it was in a different order.
That's because `dictionary.values` is non-deterministic, so this sorts
them by description now. via NachoSoto (@NachoSoto)
* `Paywalls`: initial iOS 15 support (#2933)

`PaywallView` and `PaywallViewController` (along with the extensions)
still require iOS 16, but this paves the way to support iOS 15 down the
road if we need to.

### Main Changes:

- Changed all `@available` annotations
- Added CI tests
- Replaced `ViewThatFits` with the "biggest" version
- Because of that, `scrollableIfNeeded` is always scrollable
- Double `Regex` implementation (keeping the modern one), so once we
drop support for iOS 15 we can just keep the modern one.

### TODO: 
- [x] Add snapshots
- [x] Test paywalls
- [x] Updated APITester to verify this via NachoSoto (@NachoSoto)
* `Paywalls`: changed default `PaywallData` to display available packages (#2964)

Currently it was doing a best effort and showing
`weekly`/`monthly`/`annual` if those existed in the offering. This makes
it so it doesn't have to guess, and it creates a `Paywall` using the
`availablePackages`. via NachoSoto (@NachoSoto)
* `Paywalls`: changed `offerDetails` to be optional (#2963)

In template 4 this is optional, so all templates will support this now. via NachoSoto (@NachoSoto)
* `Paywalls`: markdown support (#2961)

This relies on `SwiftUI`'s automatic rendering of markdown when using
`Text(LocalizedStringKey)`

![Screenshot 2023-08-03 at 11 52
55](https://github.com/RevenueCat/purchases-ios/assets/685609/0f19be26-aaa1-4bb2-ab0f-e0b3b1396f0b) via NachoSoto (@NachoSoto)
* `Paywalls`: updated icon set to match frontend (#2962) via NachoSoto (@NachoSoto)
* `Paywalls`: added support for `PackageType.custom` (#2959)

Fixes [PWL-80]. via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `tvOS` compilation by making it explicitly unavailable (#2956)

Follow up to #2821. via NachoSoto (@NachoSoto)
* `Paywalls`: fix crash when computing localization with duplicate packages (#2958)

Thanks to @joshdholtz for catching this. via NachoSoto (@NachoSoto)
* `Paywalls`: UIKit `PaywallViewController` (#2934) via NachoSoto (@NachoSoto)
* `Paywalls`: `presentPaywallIfNecessary` -> `presentPaywallIfNeeded` (#2953)

This is a slightly clearer API. via NachoSoto (@NachoSoto)
* `Paywalls`: added support for custom and lifetime products (#2941)

The main change is that `VariableHandler` no longer cashes when trying
to determine price per month for non-subscriptions. I added a test to
cover this behavior. via NachoSoto (@NachoSoto)
* `Paywalls`: changed `SamplePaywallsList` to work offline (#2937)

It no longer loads the real packages and creates demo paywalls.


![simulator_screenshot_7D7C41AC-3D39-43D7-8DE9-80079A43BA07](https://github.com/RevenueCat/purchases-ios/assets/685609/38829e6c-2c35-43a5-8d6c-1e12d3ec7293) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed header image mask on first template (#2936)

any device size. Also fixes the inconsistent vertical spacing on the
template. via NachoSoto (@NachoSoto)
* `Paywalls`: new `subscription_duration` variable (#2942)

This will be used by template 4, but also useful in others. via NachoSoto (@NachoSoto)
* `Paywalls`: removed `mode` parameter from `presentPaywallIfNecessary` (#2940)

This displays a paywall fullscreen, which implies that
`PaywallViewMode`. Also corrected the docstring in `PaywallView` since
it doesn't necessary imply fullscreen. via NachoSoto (@NachoSoto)
* `Paywalls`: improved `RemoteImage` error layout (#2939)

The layout should be determined by either the image or the
`placeholderView`. This ensures that. via NachoSoto (@NachoSoto)
* `Paywalls`: added default close button when using `presentPaywallIfNecessary` (#2935)

![Simulator Screenshot - iPhone 14 Pro - 2023-08-02 at 07 57
24](https://github.com/RevenueCat/purchases-ios/assets/685609/322675aa-0886-4164-89b7-97fea0947190) via NachoSoto (@NachoSoto)
* `Paywalls`: added ability to preview templates in a `.sheet` (#2938)

This is necessary to get the proper size / aspect-ratio when previewing
on iPad. via NachoSoto (@NachoSoto)
* `Paywalls`: avoid recomputing variable `Regex` (#2944)

See #2811.
It's unclear from the docs whether this is a performance optimization,
but at least it's a nice refactor. via NachoSoto (@NachoSoto)
* `Paywalls`: improved `FooterView` scaling (#2948)

- Added `bold` parameter, necessary for upcoming template
- Avoid scaling beyond largest dynamic type sizes
- Scale separator view with dynamic type setting to ensure consistency via NachoSoto (@NachoSoto)
* `Paywalls`: added ability to calculate and localize subscription discounts (#2943)

![Screenshot 2023-08-02 at 08 17
45](https://github.com/RevenueCat/purchases-ios/assets/685609/0c3ee7b8-1b37-4e6d-81d0-4b2d18086d82)

Useful for template 4, but also for others. via NachoSoto (@NachoSoto)
* `Offering`: improved description (#2912) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `FooterView` color in template 1 (#2951) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `View.scrollableIfNecessary` (#2947)

This wasn't setting the correct axes on the scroll view. This will be
necessary for the upcoming paywall using a horizontal scroll view. via NachoSoto (@NachoSoto)
* `Paywalls`: improved `IntroEligibilityStateView` to avoid layout changes (#2946) via NachoSoto (@NachoSoto)
* `Paywalls`: updated offerings snapshot with new asset base URL (#2950) via NachoSoto (@NachoSoto)
* `Paywalls`: extracted `TemplateBackgroundImageView` (#2945) via NachoSoto (@NachoSoto)
* `Paywalls`: more polish from design feedback (#2932) via NachoSoto (@NachoSoto)
* `Paywalls`: more unit tests for purchasing state (#2931)

Follow up to #2930.

Added `PresentIfNecessaryTests` and `PurchaseHandlerTests`.
This also removes the last source of "crashes" whenever `Purchases`
isn't configured, leading to errors instead. via NachoSoto (@NachoSoto)
* `Paywalls`: new `.onPurchaseCompleted` modifier (#2930)

This allows users to present a `PaywallView` and be notified of
purchasing events. Example:
```swift
VStack {
    YourViews()

    if !self.didPurchase {
        PaywallView()
    }
}
    .onPurchaseCompleted { customerInfo in
        print("Purchase completed: \(customerInfo.entitlements)")
        self.didPurchase = true
    }
```

Additionally, an explicit optional closure is added to
`.presentPaywallIfNecessary`:
```swift
YourApp()
    .presentPaywallIfNecessary {
        !$0.entitlements.active.keys.contains("entitlement_identifier")
    } purchaseCompleted: { customerInfo in
        print("Customer info unlocked entitlement: \(customerInfo.entitlements)")
    }
```

These are now tested through new unit tests. via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `LoadingPaywallView` displaying a progress view (#2929)

This was broken in #2923. Unfortunately it couldn't be caught by
snapshot tests because those don't display progress views.

I simplified `PackageButtonStyle` to get the shared
`PurchaseHandler.actionInProgress` state instead of relying on whether
the button is enabled. via NachoSoto (@NachoSoto)
* `Paywalls`: added default template to `SamplePaywallsList` (#2928)

This allows debugging the default template.

![Simulator Screenshot - iPhone 14 Pro - 2023-07-31 at 13 05
39](https://github.com/RevenueCat/purchases-ios/assets/685609/bb683d5d-31c1-402d-9213-064fd13071d6) via NachoSoto (@NachoSoto)
* `Paywalls`: added a few more logs (#2927)

Also improved logging by using `verboseLogHandler` and a new `Strings`
enum. via NachoSoto (@NachoSoto)
* `Paywalls` added individual previews for templates (#2924)

This makes it easier to preview and iterate on each individual template
instead of doing that through `PaywallView`. I extracted a lot of the
common code into a new `PreviewHelpers` for this. via NachoSoto (@NachoSoto)
* `Paywalls`: improved default paywall configuration (#2926)

This could still use more polish, but some basic fixes:
- Fixed colors
- Added application name as a title
- Using `total_price_and_per_month` instead of `price_per_month` so it
also works with monthly subscriptions
- Added snapshot test for its dark mode version via NachoSoto (@NachoSoto)
* `Paywalls`: moved purchasing state to `PurchaseHandler` (#2923)

This allows `PaywallView` to handle state handling during a purchase:
instead of the previous behavior where only `PurchaseButton` would
disable itself, now the entire `PaywallView` is disabled.

I extracted `PackageButtonStyle` so any template with multi-package
selection can get this same behavior: the package selection also becomes
disabled, as well as any other button (like restore purchases).

I've also cleaned up the templates since we no longer needed the
"Content" inside view, and they can be simplified with a single type.

By making `PurchaseHandler` `@MainActor` we also ensure that all these
state transitions lead to UI changes happening exclusively on the main
thread. via NachoSoto (@NachoSoto)
* `Paywalls`: updated Integration Test snapshot (#2921)

I added a paywall to the integration test offering so we can validate
the response format with our integration tests. via NachoSoto (@NachoSoto)
* `Paywalls`: pre-warm intro eligibility in background thread (#2925)

Follow-up to #2860.
Thanks to integration tests for catching this (#2123).

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/cf1e8e32-5d5e-47ba-b900-394aa780d865) via NachoSoto (@NachoSoto)
* `Paywalls`: removed "couldn't find package" log (#2922)

This is unnecessary noise, especially potentially when displaying
`PaywallData.default` because those packages might not exist in a given
app. via NachoSoto (@NachoSoto)
* `Paywalls`: SimpleApp reads API key from Xcode Cloud environment (#2919)

This will allow us to automatically make new releases from the
`paywalls` branch.

See
[docs](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts).

<img width="553" alt="Screenshot 2023-07-30 at 10 55 47"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/d40a00e7-6a57-4340-8160-d903d765b814"> via NachoSoto (@NachoSoto)
* `Paywalls`: improved template accessibility support (#2920)

Just some low hanging fruit to make paywalls work better with voice
over. There's still more we can improve but this makes them already 100%
usable. via NachoSoto (@NachoSoto)
* `Paywalls`: work around SwiftUI bug to allow embedding `PaywallView` inside `NavigationStack` (#2918)

Turns out that this:
```swift
NavigationStack {
    PaywallView()
}
```

Exposed `FB12674350`
(https://twitter.com/nachosoto/status/1681447887077801989?s=61&t=gy8vpJJPeGJzezleoRlJiw).
Except this also reproduced on simulator AND device.

Notice how it's the same thing: an `if` statement changing branches
after a `@State` change. Luckily the same workaround works. via NachoSoto (@NachoSoto)
* `Paywalls`: some basic polish from design feedback (#2917)

PWL-28, PWL-29, PWL-30 via NachoSoto (@NachoSoto)
* `Paywalls`: added `OfferingsList` to preview all paywalls (#2916)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/86e1f203-8d5e-47d4-9069-a7bdd91f0b5a) via NachoSoto (@NachoSoto)
* `Paywalls`: fixed tappable area for a couple of buttons (#2915)

After testing this on a device I realized that both the paywall list in
the sample app and the package buttons were only tappable on the labels. via NachoSoto (@NachoSoto)
* `Paywalls`: new `text1` and `text2` colors (#2903)

`foreground` becomes `text1`, allowing us to keep growing that list just
like accents.
`accent1` is now also optional. via NachoSoto (@NachoSoto)
* `Paywalls`: updated multi-package bold template design (#2908)

Added new border around unselected packages.
(Note that the test snapshots don't included blurred background)

![simulator_screenshot_BF1077DF-9976-4404-9AFB-9A45798CC619](https://github.com/RevenueCat/purchases-ios/assets/685609/f78245d3-ee8a-4afa-8674-12ab9698bd3f) via NachoSoto (@NachoSoto)
* `Paywalls`: added sample paywalls to `SimpleApp` (#2907)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/33f2adaf-3b4a-49a0-b60b-4fafbda20153) via NachoSoto (@NachoSoto)
* `Paywalls`: one package with features template (#2902)

Depends on #2882.

<img width="391" alt="Screenshot 2023-07-26 at 16 49 26"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/4daf9dbf-0731-436c-a0b5-e9387f59f1e0"> via NachoSoto (@NachoSoto)
* `Paywalls`: initial support for icons (#2882)

```swift
IconView(name: .lock, tint: .green)
IconView(name: .lock, tint: .green.gradient.shadow(.inner(color: .black, radius: 2)))
```

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/abc89782-cbcf-47f4-9b59-f3d15be82da9) via NachoSoto (@NachoSoto)
* `Paywalls`: extracted intro eligibility out of templates (#2901)

This simplifies template views further. Before they needed to get the
`TrialOrIntroEligibilityChecker` environment and call the appropriate
method.

Now they just need to inject the new `IntroEligibilityViewModel`, and
extract either `.allEligibility` or `singleEligibility` based on the
type of template. Everything else is done automatically outside of
templates. via NachoSoto (@NachoSoto)
* `Paywalls`: changed `subtitle` to be optional (#2900)

Not all templates require it, so it's optional from here on. via NachoSoto (@NachoSoto)
* `Paywalls`: added "features" to `LocalizedConfiguration` (#2899)

To be used by upcoming templates. via NachoSoto (@NachoSoto)
* `Paywalls`: fixed `{{ total_price_and_per_month }}` (#2881)

We were relying on both the price and price per month to be formatted
the same way. When debugging in the simulator, the actual region doesn't
change, so StoreKit's internal price formatter doesn't pick it up.
To make this more resilient, this now checks whether it's a monthly
subscription instead of comparing strings.

This is an example where `Locale.current` is only overriden partially
and the logic breaks:

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/76eabfdb-ea16-4d67-b7b3-411a3c4393a5) via NachoSoto (@NachoSoto)
* `Paywalls`: updated template names (#2878)

These now match our initial 2 templates.

I've updated everything for consistency:
- `PaywallTemplate`
- `View`s
- Snapshot tests
- Test fixtures via NachoSoto (@NachoSoto)
* `Paywalls`: added accent colors (#2883)

Also updated the second template with them:
<img width="435" alt="Screenshot 2023-07-25 at 23 18 31"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/0ecb2406-0ef9-451d-a145-90820dd108b3"> via NachoSoto (@NachoSoto)
* `Paywalls`: changed images representation to an object (#2875)

This is much better, no longer relying on array index. via NachoSoto (@NachoSoto)
* `Paywalls`: added `offerName` parameter (#2877)

This is now used in `MultiPackageTemplate`, defaulting to the
`productName` if none is set. via NachoSoto (@NachoSoto)
* `Paywalls`: new `{{ period }}` variable (#2876)

This represents the localized `PackageType`. via NachoSoto (@NachoSoto)
* `Paywalls`: disabled `PaywallViewMode`s for now (#2874)

We won't ship these initially, but still leaving the infrastructure in
place. via NachoSoto (@NachoSoto)
* `Paywalls`: added new `defaultPackage` configuration (#2871)

It's optional, so it defaults to the first package if not set. via NachoSoto (@NachoSoto)
* `Paywalls`: fixed tests on CI (#2872)

- Added JUnit test reporting for CircleCI:
<img width="624" alt="Screenshot 2023-07-25 at 11 02 52"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/a6e73b34-6d90-4b88-aa4d-f108bab47d21">

- Fixed `macOS` build
- Fixed snapshots
- Uploading `.xcarchive` to CircleCI to inspect failures (like
Snapshots)
- Simplified snapshot testing via NachoSoto (@NachoSoto)
* `Paywalls`: pre-fetch intro eligibility for paywalls (#2860) via NachoSoto (@NachoSoto)
* `Paywalls`: clean up the error view (#2873)

Tiny PR so I can feel like I'm contributing 😅 
Also helps me catch up with current status
| Before | After |
| :-: | :-: |
| ![Simulator Screenshot - iPhone 14 Pro - 2023-07-24 at 19 06
03](https://github.com/RevenueCat/purchases-ios/assets/3922667/2d6be10f-891a-48da-8c3f-0b0728438130)
| ![Simulator Screenshot - iPhone 14 Pro - 2023-07-24 at 19 05
26](https://github.com/RevenueCat/purchases-ios/assets/3922667/8b65c898-df9e-4fcd-bd0e-fc738652330d)
| via Andy Boedo (@aboedo)
* `Paywalls`: new API for easily displaying `PaywallView` with just one line (#2869)

Self-explanatory. This removes a lot of boilerplate, reducing the
required code to just:
```swift
var body: some View {
   YourApp()
      .presentPaywallIfNecessary(requiredEntitlementIdentifier: "pro")
}
``` via NachoSoto (@NachoSoto)
* `Paywalls`: handle missing paywalls gracefully (#2855)

- Improved `PaywallView` API: now there's only 2 constructors (with
optional `Mode` parameters):
    - `PaywallView()`
    - `PaywallView(offering:)`
- New `PaywallData.default` as a fallback when trying to present a
paywall with missing data (either because it failed to decode, or it's
missing)
- Extracted error state handling to `ErrorDisplay` (used by
`PaywallView` and `AsyncButton` now). It can optionally dismiss the
presenting sheet.
- Handling offering loading errors in `PaywallView`
- Improved `DebugErrorView` to allow displaying a fallback view:
```swift
DebugErrorView(
    "Offering '\(offering.identifier)' has no configured paywall.\n" +
    "The displayed paywall contains default configuration.\n" +
    "This error will be hidden in production.",
    releaseBehavior: .replacement(
        AnyView(
            LoadedOfferingPaywallView(
                offering: offering,
                paywall: .default,
                mode: mode,
                introEligibility: checker,
                purchaseHandler: purchaseHandler
            )
        )
    )
)
```
- Added `LoadingPaywallView` as a placeholder view during loading
- Improved `MultiPackageTemplate` and `RemoteImage` to fix some layout
issues during transitions
- Added transition animations between loading state and loaded paywall via NachoSoto (@NachoSoto)
* `Paywalls`: temporarily disable non-fullscreen `PaywallView`s (#2868)

They're not quite ready yet so we don't want to show them in the sample
app. via NachoSoto (@NachoSoto)
* `Paywalls`: added test to ensure package selection maintains order (#2853)

I thought I saw a bug because this wasn't true, and realized that it's
important to cover in a test. The order of package should depend on the
setting, not the offering order. This test ensures that. via NachoSoto (@NachoSoto)
* `Paywalls`: added new `blurredBackgroundImage` configuration (#2852)

<img width="387" alt="Screenshot 2023-07-20 at 18 21 42"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/b8cb4109-fdc7-4c6a-8014-b2f778b03bcd"> via NachoSoto (@NachoSoto)
* `Paywalls`: fuzzy `Locale` lookups (#2847)

`Locale.current` might only report a language and not a region. For
example when configuring the scheme like this:
<img width="409" alt="Screenshot 2023-07-21 at 10 23 37"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/c5813dca-770d-4297-8f0d-10b56cdb6445">

iOS localization supports this, and so should we. via NachoSoto (@NachoSoto)
* `Paywalls`: basic localization support (#2851)

Most of the changes are to support the creation of the new
`PaywallViewLocalizationTests` by being able to override the environment
`Locale`.

![Simulator Screenshot - iPhone 14 Pro - 2023-07-20 at 18 10
20](https://github.com/RevenueCat/purchases-ios/assets/685609/27972228-0956-499e-a90c-e8f1ae84bebe) via NachoSoto (@NachoSoto)
* `Paywalls`: added `FooterView` (#2850)

This adds 3 new features: restore purchases, ToS, and privacy policy.
All configurable.

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/b38dadec-9fa1-4d48-876d-b53d0dda93d9) via NachoSoto (@NachoSoto)
* `Paywalls`: multi-package template (#2840)

- Added support for `PackageSetting.multiple`
- Changed `PackageConfiguration.multiple` to ensure at compile time that
the list of packages is not empty
- Renamed `Example1Template` to `SinglePackageTemplate`
- Extracted `RemoteImage`
- Added snapshot tests

<img width="196" alt="screenshot_2023-07-20_at_16 01 14"
src="https://github.com/RevenueCat/purchases-ios/assets/685609/c7d6ae58-a608-414a-b5b1-11638e1a2a67"> via NachoSoto (@NachoSoto)
* `Paywalls`: disable animations during unit tests (#2848)

This improves snapshot tests, and means we can reduce the polling time. via NachoSoto (@NachoSoto)
* `Paywalls`: `TrialOrIntroEligibilityChecker.eligibility(for packages:)` (#2846)

This will be used for the multi-package template.

Includes #2858. via NachoSoto (@NachoSoto)
* `Paywalls`: added new `total_price_and_per_month` variable (#2845)

This also expands `Localization` support to be able to format this in
any language. via NachoSoto (@NachoSoto)
* `Paywalls`: extracted `PurchaseButton` (#2839)

Another small refactor, follow up to #2837.
Slowly taking implementation details from `Example1Template` to make it
easier to implement more templates. via NachoSoto (@NachoSoto)
* `Paywalls`: extracted `IntroEligibilityStateView` (#2837)

Small refactor, starting to take views out of `Example1Template` so
they're usable by other templates. This also removes some of the
duplicate code. via NachoSoto (@NachoSoto)
* `Paywalls`: support for multiple `PaywallViewMode`s (#2834)

This adds 2 new modes: `.square` and `.banner`:

![iOS16-testSquarePaywall
1](https://github.com/RevenueCat/purchases-ios/assets/685609/5d1a0a52-e02b-4877-90ac-fdeb2dcea058)
![iOS16-testBannerPaywall
1](https://github.com/RevenueCat/purchases-ios/assets/685609/a9f208d8-f920-4abd-a914-1dd86e940b1a)

-------

I've updated `Example1Template` to support both as an example, and added
that as snapshot tests.

This also adds a new constructor to `PaywallView` that doesn't require
passing an `Offering` or `PaywallData`, it automatically loads that from
`Purchases.shared`. With that, embedding these mini-paywalls is trivial:

```swift
struct MyApp: View {
  var body: some View {
    MyOtherViews()
    if !customerInfo.hasPro {
      PaywallView(mode: .card)
    }
  }
}
```

I've added these as examples to the testing app:

![simulator_screenshot_84270E1A-F7C6-4C5D-8773-F4F2E646CB0F](https://github.com/RevenueCat/purchases-ios/assets/685609/e368cab3-55af-4a87-88aa-b678deb5d2e5) via NachoSoto (@NachoSoto)
* `Paywalls`: add support for multiple images in template configuration (#2832)

Changed `PaywallData.Configuration.headerImageName` to `imageNames`.
This more flexible definition allows future templates to display a
carrousel of images instead of a single image.

Depends on #2831. via NachoSoto (@NachoSoto)
* `Paywalls`: extracted configuration processing into a new `TemplateViewConfiguration` (#2830)

### Changes:
- Created `TemplateViewConfiguration` to encapsulate all processed
configuration for a paywall
- Created `TemplateViewConfiguration.PackageSetting` and
`TemplateViewConfiguration.PackageConfiguration` to represent paywalls
that support 1 or N packages
- Taken all common logic out of `Example1Template`
- Added new `PaywallViewMode` for upcoming "ramps" views via NachoSoto (@NachoSoto)
* `Paywalls`: improved support for dynamic type with snapshots (#2827)

This improves the layout of the template, and adds a scroll view that
optionally scrolls if the content is too large.
This can serve as a the basis for future templates.

![iOS16-testAccessibility3
1](https://github.com/RevenueCat/purchases-ios/assets/685609/40cb6929-d7f0-49d4-a9c5-7fdea9747db9) via NachoSoto (@NachoSoto)
* `Paywalls`: disable `macOS`/`macCatalyst`/`watchOS` for now (#2821)

In the future we'll be able to polish support for those platforms. via NachoSoto (@NachoSoto)
* `Paywalls`: using new color information in template (#2823) via NachoSoto (@NachoSoto)
* `Paywalls`: set up CI tests and API Tester (#2816) via NachoSoto (@NachoSoto)
* `Paywalls`: added support for decoding colors (#2822) via NachoSoto (@NachoSoto)
* `Paywalls`: ignore empty strings in `LocalizedConfiguration` (#2818) via NachoSoto (@NachoSoto)
* `Paywalls`: updated `PaywallData` field names (#2817)

These now match how the frontend is configuring them. via NachoSoto (@NachoSoto)
* `Paywalls`: added support for purchasing (#2812)

This adds a new `PurchaseHandler` type, which can be instantiated with
`Purchases` or with a mock implementation for previews. That gets
injected, and templates can now purchase and dismiss themselves.

I've improved the `SimpleApp` setup to better work with the lifetime of
purchases. Now it only displays the paywall if the user doesn't have an
entitlement.

I've also added some basic error handling to the new `AsyncButton`:
![Simulator Screenshot - iPhone 14 Pro - 2023-07-13 at 15 32
06](https://github.com/RevenueCat/purchases-ios/assets/685609/e8c2e6e3-f1e0-411f-9ca2-8a3cc3823a42) via NachoSoto (@NachoSoto)
* `Paywalls`: added tests for `PackageType` filtering (#2810)

Some missing tests for the logic added in #2798.
I've also moved this function to be fined in `PaywallData` instead of
the `TemplateViewType` protocol, which makes more sense. via NachoSoto (@NachoSoto)
* `Paywalls`: changed variable handling to use Swift `Regex` (#2811)

Had to join in the fun!

This PR updates the regex logic for variables to use RegexBuilder. via Andy Boedo (@aboedo)
* `Paywalls`: added `price` variable (#2809) via NachoSoto (@NachoSoto)
* `Paywalls`: determine intro eligibility (#2808)

Follow up to #2796.
This also makes `PaywallData.Configuration`'s intro strings optional.

- Injected `TrialOrIntroEligibilityChecker`
- Created mock `TrialOrIntroEligibilityChecker` for previews
- Handling state and transitions for loading eligibility
- Snapshot tests for the different new cases
- Improved `SnapshotTesting` delay management
- Expanded `DebugErrorView` to customize release behavior via NachoSoto (@NachoSoto)
* `Paywalls`: added header image to configuration (#2800)

- Added `PaywallData.assetBaseURL` and
`PaywallData.Configuration.headerImageName`
- Changed template to fetch image from network
- Updated snapshot testing to support asynchronous checking, necessary
for `AsyncImageView`
- Added support for overriding images for snapshot tests
- Extracted `DebugErrorView` via NachoSoto (@NachoSoto)
* `Paywalls`: added `packages` to configuration (#2798)

This allows configuring which package(s) will be displayed in each
paywall. via NachoSoto (@NachoSoto)
* `Paywalls`: add support for displaying `StoreProductDiscount`s (#2796)

![image](https://github.com/RevenueCat/purchases-ios/assets/685609/2e009460-5faf-42af-8dd0-8ff416e51335) via NachoSoto (@NachoSoto)
* `Paywalls`: added support for variables (#2793)

- Added `subtitle` and `offerDetails` to `LocalizedConfiguration`
- Improved sample paywall to include these with test variables
- Updated snapshot test to display the current progress
- Added initial implementation of `VariableHandler` with tests via NachoSoto (@NachoSoto)
* `Paywalls`: using `PaywallData` and setting up basic template loading (#2781)

This adds a new `TemplateViewType` that different templates can conform
to.
`PaywallView` now takes `PaywallData` and renders the paywall depending
on its template. via NachoSoto (@NachoSoto)
* `Paywalls`: initial configuration types (#2780)

- Added `Offering.paywall`
- Decoding `PaywallData` in `OfferingsResponse`, using
`IgnoreDecodeErrors` (this will be better after #2778)
- New `PaywallData` `struct`
- Added new APIs to testers
- Testing paywall deserialization from `Offerings`
- Testing paywall deserialization separately to check edge cases via NachoSoto (@NachoSoto)
* `Paywalls`: initial `RevenueCatUI` target setup (#2776)

- Added `RevenueCatUI` to `Package.json`
- Set up tests for `RevenueCatUI` using `snapshot-testing` (not in CI
during initial development)
- Added Schemes to allow easily building packages while working on the
`Package.swift`
- Updated `SimpleApp` to use new package via NachoSoto (@NachoSoto)
* Version bump for 4.25.7 via RCGitBot (@RCGitBot)