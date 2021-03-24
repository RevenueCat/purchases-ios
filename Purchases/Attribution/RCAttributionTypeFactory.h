//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);

typedef NS_ENUM(NSUInteger, FakeTrackingManagerAuthorizationStatus) {
    FakeTrackingManagerAuthorizationStatusNotDetermined = 0,
    FakeTrackingManagerAuthorizationStatusRestricted,
    FakeTrackingManagerAuthorizationStatusDenied,
    FakeTrackingManagerAuthorizationStatusAuthorized
};

@protocol FakeAdClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(RCAttributionDetailsBlock)completionHandler;

@end


@protocol FakeASIdentifierManager <NSObject>

+ (instancetype)sharedManager;

@end

@protocol FakeATTrackingManager <NSObject>

+ (NSInteger)trackingAuthStatusProperty;

@end


NS_SWIFT_NAME(AttributionTypeFactory)
@interface RCAttributionTypeFactory : NSObject

- (Class<FakeAdClient> _Nullable)adClientClass;
- (Class<FakeATTrackingManager> _Nullable)atTrackingClass;
- (Class<FakeASIdentifierManager> _Nullable)asIdentifierClass;

- (NSString *)asIdentifierPropertyName;

@property (readonly) NSString *mangledIdentifierClassName;
@property (readonly) NSString *mangledIdentifierPropertyName;
@property (readonly) NSString *mangledTrackingClassName;

@end


NS_ASSUME_NONNULL_END
