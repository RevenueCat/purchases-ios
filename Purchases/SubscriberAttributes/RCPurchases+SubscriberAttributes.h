//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h"
#import "RCSubscriberAttribute.h"

@class RCSubscriberAttribute, RCSubscriberAttributesManager;

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchases (SubscriberAttributes)

- (void)configureSubscriberAttributesManager;
- (RCSubscriberAttributeDict)unsyncedAttributesByKey;
- (void)markAttributesAsSyncedIfNeeded:(nullable RCSubscriberAttributeDict)syncedAttributes
                             appUserID:(NSString *)appUserID
                                 error:(nullable NSError *)error;
@end

@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

@end


NS_ASSUME_NONNULL_END
