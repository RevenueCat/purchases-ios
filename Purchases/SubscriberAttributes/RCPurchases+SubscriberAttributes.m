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
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@implementation RCPurchases (SubscriberAttributes)

#pragma mark protected methods

- (void)configureSubscriberAttributesManager {
    [self subscribeToAppDidBecomeActiveNotifications];
    [self subscribeToAppBackgroundedNotifications];
}

- (RCSubscriberAttributeDict)unsyncedAttributesByKey {
    NSString *appUserID = self.appUserID;
    RCSubscriberAttributeDict unsyncedAttributes = [self.subscriberAttributesManager
                                                    unsyncedAttributesByKeyForAppUserID:appUserID];
    RCLog(@"found %lu unsynced attributes for appUserID: %@", unsyncedAttributes.count, appUserID);
    if (unsyncedAttributes.count > 0) {
        RCLog(@"unsynced attributes: %@", unsyncedAttributes);
    }

    return unsyncedAttributes;
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
    [self.operationDispatcher dispatchOnWorkerThread:^{
        [self.subscriberAttributesManager syncAttributesForAllUsersWithCurrentAppUserID:self.appUserID];
    }];
}

@end


NS_ASSUME_NONNULL_END
