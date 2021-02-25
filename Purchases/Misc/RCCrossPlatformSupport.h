//
//  RCCrossPlatformSupport.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#if TARGET_OS_IOS || TARGET_OS_TV
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME UIApplicationDidBecomeActiveNotification
#define APP_WILL_RESIGN_ACTIVE_NOTIFICATION_NAME UIApplicationWillResignActiveNotification
#elif TARGET_OS_OSX
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME NSApplicationDidBecomeActiveNotification
#define APP_WILL_RESIGN_ACTIVE_NOTIFICATION_NAME NSApplicationWillResignActiveNotification
#elif TARGET_OS_WATCH
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME NSExtensionHostDidBecomeActiveNotification
#define APP_WILL_RESIGN_ACTIVE_NOTIFICATION_NAME NSExtensionHostWillResignActiveNotification
#endif

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_MACCATALYST
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#elif TARGET_OS_WATCH
#import <UIKit/UIKit.h>
#import <WatchKit/WatchKit.h>
#endif

#if TARGET_OS_MACCATALYST
#define PLATFORM_HEADER @"uikitformac"
#elif TARGET_OS_IOS
#define PLATFORM_HEADER @"iOS"
#elif TARGET_OS_OSX
#define PLATFORM_HEADER @"macOS"
#elif TARGET_OS_WATCH
#define PLATFORM_HEADER @"watchOS"
#elif TARGET_OS_TV
#define PLATFORM_HEADER @"tvOS"
#endif

// Should match available platforms in
// https://developer.apple.com/documentation/uikit/uidevice?language=objc
#if TARGET_OS_IOS || TARGET_OS_TV
#define UI_DEVICE_AVAILABLE 1
#else
#define UI_DEVICE_AVAILABLE 0
#endif

// Should match available platforms in
// https://developer.apple.com/documentation/watchkit/wkinterfacedevice?language=objc
#if TARGET_OS_WATCH
#define WKINTERFACE_DEVICE_AVAILABLE 1
#else
#define WKINTERFACE_DEVICE_AVAILABLE 0
#endif


// Should match available platforms in
// https://developer.apple.com/documentation/iad/adclient?language=objc
#if TARGET_OS_IOS
#define AD_CLIENT_AVAILABLE 1
#else
#define AD_CLIENT_AVAILABLE 0
#endif

// Should match available platforms in
// https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/2877502-paymentqueue?language=objc
#if TARGET_OS_TV || (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)
#define PURCHASES_INITIATED_FROM_APP_STORE_AVAILABLE 1
#else
#define PURCHASES_INITIATED_FROM_APP_STORE_AVAILABLE 0
#endif


// Should match platforms that require permissions detailed in
// https://developer.apple.com/app-store/user-privacy-and-data-use/
#if TARGET_OS_WATCH || TARGET_OS_OSX || TARGET_OS_MACCATALYST
#define APP_TRACKING_TRANSPARENCY_REQUIRED 0
#else
#define APP_TRACKING_TRANSPARENCY_REQUIRED 1
#endif
