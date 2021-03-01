//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);


@protocol FakeAdClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(RCAttributionDetailsBlock)completionHandler;

@end


@protocol FakeASIdentifierManager <NSObject>

+ (instancetype)sharedManager;

@end

@protocol FakeATTrackingManager <NSObject>

+ (NSInteger)trackingAuthorizationStatus;

@end


NS_SWIFT_NAME(AttributionTypeFactory)
@interface RCAttributionTypeFactory : NSObject

- (Class<FakeAdClient> _Nullable)adClientClass;
- (Class<FakeATTrackingManager> _Nullable)trackingManagerClass;

@end


NS_ASSUME_NONNULL_END
