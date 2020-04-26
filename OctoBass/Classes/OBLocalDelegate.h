//
//  OBLocalDelegate.h
//  OctoBass
//
//  Created by Darwin on 4/24/20.
//

#import <Foundation/Foundation.h>
#import "OBAppController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBLocalDelegate : NSObject
+ (instancetype)localDelegate;
@property (nonatomic, strong, readonly) OBAppController *appController;
@end

NS_ASSUME_NONNULL_END
