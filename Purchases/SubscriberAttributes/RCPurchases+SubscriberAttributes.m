//
// Created by Andrés Boedo on 2/21/20.
//

#import "RCPurchases.h"
#import "RCPurchases.m"
#import "RCSubscriberAttributesManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

@end


NS_ASSUME_NONNULL_END


@implementation RCPurchases (SubscriberAttributes)

#pragma mark public methods

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    NSLog(@"setAttributes called");
    [self.subscriberAttributesManager setAttributes:attributes appUserID:self.appUserID appID:nil];
}

- (void)setEmail:(nullable NSString *)email {
    NSLog(@"setEmail called");
    [self.subscriberAttributesManager setEmail:email appUserID:self.appUserID appID:nil];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    NSLog(@"setPhoneNumber called");
    [self.subscriberAttributesManager setPhoneNumber:phoneNumber appUserID:self.appUserID appID:nil];
}

- (void)setDisplayName:(nullable NSString *)displayName {
    NSLog(@"setDisplayName called");
    [self.subscriberAttributesManager setDisplayName:displayName appUserID:self.appUserID appID:nil];
}

- (void)setPushToken:(nullable NSString *)pushToken {
    NSLog(@"setPushToken called");
    [self.subscriberAttributesManager setPushToken:pushToken appUserID:self.appUserID appID:nil];
}

#pragma mark protected methods

- (void)configureSubscriberAttributesManager {
    [self initializeSubscriberAttributesManager];
    [self subscribeToAppBackgroundedNotifications];
    [self subscribeToAppDidBecomeActiveNotifications];
}

- (void)clearSubscriberAttributesCache {
    [self.subscriberAttributesManager clearAttributesForAppUserID:nil appID:nil];
}

- (NSArray <RCSubscriberAttribute *> *)unsyncedAttributes {
    return [self.subscriberAttributesManager unsyncedAttributesForAppUserID:nil appID:nil];
}

#pragma mark private methods

- (void)initializeSubscriberAttributesManager {
    RCSubscriberAttributesManager
        *subscriberAttributesManager = [[RCSubscriberAttributesManager alloc] initWithBackend:self.backend
                                                                                  deviceCache:self.deviceCache];
    self.subscriberAttributesManager = subscriberAttributesManager;
}

- (void)subscribeToAppBackgroundedNotifications {
    // TODO
}

- (void)subscribeToAppDidBecomeActiveNotifications {
    [self.notificationCenter addObserver:self
                                selector:@selector(syncSubscriberAttributesIfNeeded)
                                    name:APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME
                                  object:nil];

}

- (void)syncSubscriberAttributesIfNeeded {
    [self.subscriberAttributesManager syncIfNeededWithAppUserID:nil appID:nil completion:^(NSError *error) {
        if (error != nil) {
            RCErrorLog(@"error when syncing subscriber attributes. Details: %@", error.localizedDescription);
        } else {
            RCLog(@"Subscriber attributes synced successfully");
        }
    }];
}

@end
