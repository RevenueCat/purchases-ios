//
// Created by Andrés Boedo on 2/21/20.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"
#import "RCPurchases+SubscriberAttributes.h"

@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@implementation RCPurchases (SubscriberAttributes)

#pragma mark protected methods

- (RCSubscriberAttributeDict)unsyncedAttributesByKey {
    NSString *appUserID = self.appUserID;
    RCSubscriberAttributeDict unsyncedAttributes = [self.subscriberAttributesManager
                                                    unsyncedAttributesByKeyWithAppUserID:appUserID];

    [RCLog debug:[NSString stringWithFormat:RCStrings.attribution.unsynced_attributes_count,
                  (unsigned long)unsyncedAttributes.count, appUserID]];
    if (unsyncedAttributes.count > 0) {
        [RCLog debug:[NSString stringWithFormat:RCStrings.attribution.unsynced_attributes, unsyncedAttributes]];
    }

    return unsyncedAttributes;
}

- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error {
    if (error && !error.rc_successfullySynced) {
        return;
    }

    if (error.rc_subscriberAttributesErrors) {
        [RCLog error:[NSString stringWithFormat:RCStrings.attribution.subscriber_attributes_error,
                      error.rc_subscriberAttributesErrors]];
    }
    [self.subscriberAttributesManager markAttributesAsSynced:syncedAttributes appUserID:appUserID];
}

- (void)syncSubscriberAttributesIfNeeded {
    [self.operationDispatcher dispatchOnWorkerThreadWithRandomDelay:NO block:^{
        [self.subscriberAttributesManager syncAttributesForAllUsersWithCurrentAppUserID:self.appUserID];
    }];
}

@end


NS_ASSUME_NONNULL_END
