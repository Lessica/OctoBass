//
//  OBMediaStatus.h
//  OctoBass
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    OBMediaTypeUnknown = 0,
    OBMediaTypeHTMLVideoTag,
    OBMediaTypeHTMLAudioTag,
    OBMediaTypeHTMLEmbedTag,
    OBMediaTypeNativeAVPlayer,
#if ENABLE_MPMOVIEPLAYER
    OBMediaTypeNativeMPMoviePlayer,
#endif
} OBMediaType;

@interface OBMediaStatus : NSObject

@property (nonatomic, copy, readonly) NSURL *src;

@property (nonatomic, assign, readonly) OBMediaType mediaType;
- (BOOL)isNativeMediaType;

@property (nonatomic, assign, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, assign, readonly, getter=isEnded) BOOL ended;
- (BOOL)isPlaying;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, strong, readonly) NSDate *createdAt;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)statusWithDictionary:(NSDictionary <NSString *, id> *)dict;
- (instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dict NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

