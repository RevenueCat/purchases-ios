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


@interface RCPurchases (SubscriberAttributes)

@end


NS_ASSUME_NONNULL_END


@implementation RCPurchases (SubscriberAttributes)

#pragma mark public methods

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    NSLog(@"setAttributes called");
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID];
}

- (void)setEmail:(nullable NSString *)email {
    NSLog(@"setEmail called");
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    NSLog(@"setPhoneNumber called");
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    NSLog(@"setDisplayName called");
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID];
}

- (void)setPushToken:(nullable NSString *)pushToken {
    NSLog(@"setPushToken called");
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID];
}

#pragma mark protected methods

- (void)configureSubscriberAttributesManager {
    [self initializeSubscriberAttributesManager];
    [self subscribeToAppDidBecomeActiveNotifications];
    [self subscribeToAppBackgroundedNotifications];
}

- (void)clearSubscriberAttributesCache {
    [self.subscriberAttributesManager clearAttributesForAppUserID:self.appUserID];
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKey {
    return [self.subscriberAttributesManager unsyncedAttributesByKeyForAppUserID:self.appUserID];
}

- (void)markAttributesAsSynced:(RCSubscriberAttributeDict)syncedAttributes
                     appUserID:(NSString *)appUserID {
    [self.subscriberAttributesManager markAttributesAsSynced:syncedAttributes appUserID:appUserID];
}

#pragma mark private methods

- (void)initializeSubscriberAttributesManager {
    RCSubscriberAttributesManager
        *subscriberAttributesManager = [[RCSubscriberAttributesManager alloc] initWithBackend:self.backend
                                                                                  deviceCache:self.deviceCache];
    self.subscriberAttributesManager = subscriberAttributesManager;
}

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
            RCErrorLog(@"error when syncing subscriber attributes. Details: %@", error.localizedDescription);
        } else {
            RCLog(@"Subscriber attributes synced successfully");
        }
    }];
}

@end
