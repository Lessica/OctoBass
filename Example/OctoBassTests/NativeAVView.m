//
//  NativeAVView.m
//  OctoBassTests
//

#import "NativeAVView.h"


@implementation NativeAVView

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    _playerLayer.frame = self.layer.bounds;
}

@end

