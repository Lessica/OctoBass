//
//  UIView+Description.m
//  OctoBass
//

#import "UIView+Description.h"


@implementation UIView (Description)


- (NSString *)ob_description {
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d)>", NSStringFromClass([self class]), self, (int)self.bounds.origin.x, (int)self.bounds.origin.y, (int)self.bounds.size.width, (int)self.bounds.size.height];
}


@end

