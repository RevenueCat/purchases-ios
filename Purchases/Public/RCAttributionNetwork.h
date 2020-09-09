//
// Created by Andrés Boedo on 9/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

/**
 Enum of supported attribution networks
 */
typedef NS_ENUM(NSInteger, RCAttributionNetwork) {
    /**
     Apple's search ads
     */
    RCAttributionNetworkAppleSearchAds = 0,
    /**
     Adjust https://www.adjust.com/
     */
    RCAttributionNetworkAdjust,
    /**
     AppsFlyer https://www.appsflyer.com/
     */
    RCAttributionNetworkAppsFlyer,
    /**
     Branch https://www.branch.io/
     */
    RCAttributionNetworkBranch,
    /**
     Tenjin https://www.tenjin.io/
     */
    RCAttributionNetworkTenjin,
    /**
     Facebook https://developers.facebook.com/
     */
    RCAttributionNetworkFacebook,
    /**
    mParticle https://www.mparticle.com/
    */
    RCAttributionNetworkMParticle
};
