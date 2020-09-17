//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h"
#import "RCSubscriberAttribute.h"

@class RCSubscriberAttribute, RCSubscriberAttributesManager, RCOperationDispatcher;

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchases (SubscriberAttributes)

- (RCSubscriberAttributeDict)unsyncedAttributesByKey;
- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error;
- (void)syncSubscriberAttributesIfNeeded;

@end

@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;
@property (nonatomic) RCOperationDispatcher *operationDispatcher;

@end


NS_ASSUME_NONNULL_END
