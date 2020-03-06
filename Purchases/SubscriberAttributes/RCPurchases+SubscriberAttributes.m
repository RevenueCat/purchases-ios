//
// Created by Andrés Boedo on 2/21/20.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"
#import "RCPurchases+SubscriberAttributes.h"
#import "RCSubscriberAttributesManager.h"
#import "RCCrossPlatformSupport.h"
#import "RCUtils.h"

NS_ASSUME_NONNULL_BEGIN


@implementation RCPurchases (SubscriberAttributes)

#pragma mark protected methods

- (void)_setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    NSLog(@"setAttributes called");
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID];
}

- (void)_setEmail:(nullable NSString *)email {
    NSLog(@"setEmail called");
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID];
}

- (void)_setPhoneNumber:(nullable NSString *)phoneNumber {
    NSLog(@"setPhoneNumber called");
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID];
}

- (void)_setDisplayName:(nullable NSString *)displayName {
    NSLog(@"setDisplayName called");
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID];
}

- (void)_setPushToken:(nullable NSString *)pushToken {
    NSLog(@"setPushToken called");
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID];
}

- (void)configureSubscriberAttributesManager {
    [self subscribeToAppDidBecomeActiveNotifications];
    [self subscribeToAppBackgroundedNotifications];
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKey {
    return [self.subscriberAttributesManager unsyncedAttributesByKeyForAppUserID:self.appUserID];
}

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID {
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
    [self.subscriberAttributesManager syncIfNeededWithAppUserID:self.appUserID completion:^(NSError *error) {
        if (error != nil) {
            RCErrorLog(@"error when syncing subscriber attributes. Details: %@\n UserInfo:%@",
                       error.localizedDescription,
                       error.userInfo);
        } else {
            RCLog(@"Subscriber attributes synced successfully");
        }
    }];
}

@end


NS_ASSUME_NONNULL_END
