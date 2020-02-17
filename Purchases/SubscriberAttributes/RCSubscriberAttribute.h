//
// Created by Andrés Boedo on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttribute : NSObject

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *value;
@property (nonatomic, copy, readonly) NSString *appUserID;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, readonly) NSDate *syncStartedTime;
@property (nonatomic, assign, readonly) BOOL isSynced;

@end


NS_ASSUME_NONNULL_END
