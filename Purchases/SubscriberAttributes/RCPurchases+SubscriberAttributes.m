//
// Created by Andrés Boedo on 2/21/20.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"
#import "RCPurchases+SubscriberAttributes.h"
#import "RCSubscriberAttributesManager.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"
#import "NSError+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN


@implementation RCPurchases (SubscriberAttributes)

#pragma mark protected methods

- (void)_setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    RCDebugLog(@"setAttributes called");
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID];
}

- (void)_setEmail:(nullable NSString *)email {
    RCDebugLog(@"setEmail called");
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID];
}

- (void)_setPhoneNumber:(nullable NSString *)phoneNumber {
    RCDebugLog(@"setPhoneNumber called");
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID];
}

- (void)_setDisplayName:(nullable NSString *)displayName {
    RCDebugLog(@"setDisplayName called");
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID];
}

- (void)_setPushToken:(nullable NSData *)pushToken {
    RCDebugLog(@"setPushToken called");
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID];
}

- (void)_setPushTokenString:(nullable NSString *)pushToken {
    RCDebugLog(@"setPushTokenString called");
    [self.subscriberAttributesManager setPushTokenString:pushToken appUserID:self.appUserID];
}

- (void)_setAdjustID:(nullable NSString *)adjustID {
    RCDebugLog(@"setAdjustID called");
    [self.subscriberAttributesManager setAdjustID:adjustID appUserID:self.appUserID];
}

- (void)_setAppsflyerID:(nullable NSString *)appsflyerID {
    RCDebugLog(@"setAppsflyerID called");
    [self.subscriberAttributesManager setAppsflyerID:appsflyerID appUserID:self.appUserID];
}

- (void)_setFBAnonymousID:(nullable NSString *)fbAnonymousID {
    RCDebugLog(@"setFBAnonymousID called");
    [self.subscriberAttributesManager setFBAnonymousID:fbAnonymousID appUserID:self.appUserID];
}

- (void)_setMparticleID:(nullable NSString *)mparticleID {
    RCDebugLog(@"setMparticleID called");
    [self.subscriberAttributesManager setMparticleID:mparticleID appUserID:self.appUserID];
}

- (void)_setOnesignalID:(nullable NSString *)onesignalID {
    RCDebugLog(@"setOnesignalID called");
    [self.subscriberAttributesManager setOnesignalID:onesignalID appUserID:self.appUserID];
}

- (void)_setMediaSource:(nullable NSString *)mediaSource {
    RCDebugLog(@"setMediaSource called");
    [self.subscriberAttributesManager setMediaSource:mediaSource appUserID:self.appUserID];
}

- (void)_setCampaign:(nullable NSString *)campaign {
    RCDebugLog(@"setCampaign called");
    [self.subscriberAttributesManager setCampaign:campaign appUserID:self.appUserID];
}

- (void)_setAdGroup:(nullable NSString *)adGroup {
    RCDebugLog(@"setAdGroup called");
    [self.subscriberAttributesManager setAdGroup:adGroup appUserID:self.appUserID];
}

- (void)_setAd:(nullable NSString *)ad {
    RCDebugLog(@"setAd called");
    [self.subscriberAttributesManager setAd:ad appUserID:self.appUserID];
}

- (void)_setKeyword:(nullable NSString *)keyword {
    RCDebugLog(@"setKeyword called");
    [self.subscriberAttributesManager setKeyword:keyword appUserID:self.appUserID];
}

- (void)_setCreative:(nullable NSString *)creative {
    RCDebugLog(@"setCreative called");
    [self.subscriberAttributesManager setCreative:creative appUserID:self.appUserID];
}

- (void)_collectDeviceIdentifiers {
    RCDebugLog(@"collectDeviceIdentifiers called");
    [self.subscriberAttributesManager collectDeviceIdentifiersForAppUserID:self.appUserID];
}

- (void)configureSubscriberAttributesManager {
    [self subscribeToAppDidBecomeActiveNotifications];
    [self subscribeToAppBackgroundedNotifications];
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKey {
    return [self.subscriberAttributesManager unsyncedAttributesByKeyForAppUserID:self.appUserID];
}

- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error {
    if (error && !error.successfullySynced) {
        return;
    }

    if (error.subscriberAttributesErrors) {
        RCLog(@"Subscriber attributes errors: %@", error.subscriberAttributesErrors);
    }
    [self.subscriberAttributesManager markAttributesAsSynced:syncedAttributes appUserID:appUserID];
}

#pragma mark private methods

- (void)subscribeToAppDidBecomeActiveNotifications {
    [self.notificationCenter addObserver:self
                                selector:@selector(syncSubscriberAttributesIfNeeded)
                                    name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME
                                  object:nil];
}

- (void)subscribeToAppBackgroundedNotifications {
    [self.notificationCenter addObserver:self
                                selector:@selector(syncSubscriberAttributesIfNeeded)
                                    name:APP_WILL_RESIGN_ACTIVE_NOTIFICATION_NAME
                                  object:nil];
}

- (void)syncSubscriberAttributesIfNeeded {
    [self.subscriberAttributesManager syncAttributesForAllUsersWithCurrentAppUserID:self.appUserID];
}

@end


NS_ASSUME_NONNULL_END
