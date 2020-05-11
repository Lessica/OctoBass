//
//  OBTouchRocket.h
//  OctoBass
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OBTouchRocket : NSObject

+ (NSInteger)touchWithFinger:(NSInteger)pointId atPoint:(CGPoint)point withPhase:(UITouchPhase)phase;
+ (NSInteger)tapAtPoint:(CGPoint)point;
+ (NSInteger)availableFinger;

@end

