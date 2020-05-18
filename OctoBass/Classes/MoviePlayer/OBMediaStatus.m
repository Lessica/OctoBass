//
//  OBMediaStatus.m
//  OctoBass
//

#import "OBMediaStatus.h"


@implementation OBMediaStatus

+ (instancetype)statusWithDictionary:(NSDictionary<NSString *,id> *)dict {
    return [[OBMediaStatus alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dict {
    self = [super init];
    if (self) {
        
        NSAssert([dict[@"src"] isKindOfClass:[NSString class]], @"invalid src");
        _src = [NSURL URLWithString:dict[@"src"]];
        NSAssert(_src != nil, @"invalid src");
        
        NSAssert([dict[@"type"] isKindOfClass:[NSString class]], @"invalid type");
        if ([(NSString *)dict[@"type"] isEqualToString:@"video"]) {
            _mediaType = OBMediaTypeHTMLVideoTag;
        }
        else if ([(NSString *)dict[@"type"] isEqualToString:@"audio"]) {
            _mediaType = OBMediaTypeHTMLAudioTag;
        }
        else if ([(NSString *)dict[@"type"] isEqualToString:@"embed"]) {
            _mediaType = OBMediaTypeHTMLEmbedTag;
        }
        else if ([(NSString *)dict[@"type"] isEqualToString:@"AVPlayer"]) {
            _mediaType = OBMediaTypeNativeAVPlayer;
        }
#if ENABLE_MPMOVIEPLAYER
        else if ([(NSString *)dict[@"type"] isEqualToString:@"MPMoviePlayerController"]) {
            _mediaType = OBMediaTypeNativeMPMoviePlayer;
        }
#endif
        else {
            _mediaType = OBMediaTypeUnknown;
        }
        NSAssert(_mediaType != OBMediaTypeUnknown, @"invalid type");
        
        NSAssert([dict[@"paused"] isKindOfClass:[NSNumber class]], @"invalid status");
        NSAssert([dict[@"ended"] isKindOfClass:[NSNumber class]], @"invalid status");
        _paused = [(NSNumber *)dict[@"paused"] boolValue];
        _ended = [(NSNumber *)dict[@"ended"] boolValue];
        
        NSAssert([dict[@"duration"] isKindOfClass:[NSNumber class]], @"invalid status");
        NSAssert([dict[@"currentTime"] isKindOfClass:[NSNumber class]], @"invalid status");
        _duration = [(NSNumber *)dict[@"duration"] doubleValue];
        _currentTime = [(NSNumber *)dict[@"currentTime"] doubleValue];
        
        _createdAt = [NSDate date];
        
    }
    return self;
}

- (BOOL)isPlaying {
    return !_paused && !_ended;
}

- (BOOL)isNativeMediaType {
#if ENABLE_MPMOVIEPLAYER
    return _mediaType == OBMediaTypeNativeAVPlayer || _mediaType == OBMediaTypeNativeMPMoviePlayer;
#else
    return _mediaType == OBMediaTypeNativeAVPlayer;
#endif
}


#pragma mark - Private

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

- (NSString *)description {
    
    NSString *typeDesc = nil;
    switch (self.mediaType) {
        case OBMediaTypeHTMLVideoTag:
            typeDesc = @"HTML <video>";
            break;
        case OBMediaTypeHTMLAudioTag:
            typeDesc = @"HTML <audio>";
            break;
        case OBMediaTypeHTMLEmbedTag:
            typeDesc = @"HTML <embed>";
            break;
        case OBMediaTypeNativeAVPlayer:
            typeDesc = @"AVPlayer (AVKit)";
            break;
#if ENABLE_MPMOVIEPLAYER
        case OBMediaTypeNativeMPMoviePlayer:
            typeDesc = @"MPMoviePlayerController (MediaPlayer)";
            break;
#endif
        default:
            typeDesc = @"Unknown";
            break;
    }
    
    NSString *statusDesc = nil;
    if (self.ended) {
        statusDesc = @"Ended";
    }
    else if (self.paused) {
        statusDesc = @"Paused";
    }
    else {
        statusDesc = @"Playing";
    }
    
    return [NSString stringWithFormat:@"<%@: %p>\n  - Type: %@\n  - URL: %@\n  - Status: %@\n  - Progress: %@ / %@\n  - Created At: %@", NSStringFromClass([self class]), self, typeDesc, self.src, statusDesc, [self timeFormatted:(int)self.currentTime], [self timeFormatted:(int)self.duration], [self.createdAt descriptionWithLocale:[NSLocale currentLocale]]];
    
}

@end

