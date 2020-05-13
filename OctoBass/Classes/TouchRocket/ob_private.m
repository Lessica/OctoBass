//
//  ob_private.m
//  OctoBass
//

#import <UIKit/UIKit.h>
#import <mach/mach_time.h>
#import <dlfcn.h>
#import "ob_private.h"


#define IOHIDEventFieldBase(type) (type << 16)
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif  // __LP64__

typedef UInt32 IOOptionBits;
typedef uint32_t IOHIDDigitizerTransducerType;
typedef uint32_t IOHIDEventField;
typedef uint32_t IOHIDEventType;


enum {
    kIOHIDDigitizerTransducerTypeStylus = 0,
    kIOHIDDigitizerTransducerTypePuck,
    kIOHIDDigitizerTransducerTypeFinger,
    kIOHIDDigitizerTransducerTypeHand
};


enum {
    kIOHIDEventTypeNULL,                    // 0
    kIOHIDEventTypeVendorDefined,
    kIOHIDEventTypeButton,
    kIOHIDEventTypeKeyboard,
    kIOHIDEventTypeTranslation,
    kIOHIDEventTypeRotation,                // 5
    kIOHIDEventTypeScroll,
    kIOHIDEventTypeScale,
    kIOHIDEventTypeZoom,
    kIOHIDEventTypeVelocity,
    kIOHIDEventTypeOrientation,             // 10
    kIOHIDEventTypeDigitizer,
    kIOHIDEventTypeAmbientLightSensor,
    kIOHIDEventTypeAccelerometer,
    kIOHIDEventTypeProximity,
    kIOHIDEventTypeTemperature,             // 15
    kIOHIDEventTypeNavigationSwipe,
    kIOHIDEventTypePointer,
    kIOHIDEventTypeProgress,
    kIOHIDEventTypeMultiAxisPointer,
    kIOHIDEventTypeGyro,                    // 20
    kIOHIDEventTypeCompass,
    kIOHIDEventTypeZoomToggle,
    kIOHIDEventTypeDockSwipe,               // Just like kIOHIDEventTypeNavigationSwipe, but intended for consumption by Dock.
    kIOHIDEventTypeSymbolicHotKey,
    kIOHIDEventTypePower,                   // 25
    kIOHIDEventTypeLED,
    kIOHIDEventTypeFluidTouchGesture,       // This will eventually superseed Navagation and Dock swipes.
    kIOHIDEventTypeBoundaryScroll,
    kIOHIDEventTypeBiometric,
    kIOHIDEventTypeUnicode,                 // 30
    kIOHIDEventTypeAtmosphericPressure,
    kIOHIDEventTypeUndefined,
    kIOHIDEventTypeCount,                   // This should always be last.
    // DEPRECATED:
    kIOHIDEventTypeSwipe = kIOHIDEventTypeNavigationSwipe,
    kIOHIDEventTypeMouse = kIOHIDEventTypePointer
};


enum {
    kIOHIDDigitizerEventRange                               = 0x00000001,
    kIOHIDDigitizerEventTouch                               = 0x00000002,
    kIOHIDDigitizerEventPosition                            = 0x00000004,
    kIOHIDDigitizerEventStop                                = 0x00000008,
    kIOHIDDigitizerEventPeak                                = 0x00000010,
    kIOHIDDigitizerEventIdentity                            = 0x00000020,
    kIOHIDDigitizerEventAttribute                           = 0x00000040,
    kIOHIDDigitizerEventCancel                              = 0x00000080,
    kIOHIDDigitizerEventStart                               = 0x00000100,
    kIOHIDDigitizerEventResting                             = 0x00000200,
    kIOHIDDigitizerEventSwipeUp                             = 0x01000000,
    kIOHIDDigitizerEventSwipeDown                           = 0x02000000,
    kIOHIDDigitizerEventSwipeLeft                           = 0x04000000,
    kIOHIDDigitizerEventSwipeRight                          = 0x08000000,
    kIOHIDDigitizerEventSwipeMask                           = 0xFF000000,
};


enum {
    kIOHIDEventFieldDigitizerX = IOHIDEventFieldBase(kIOHIDEventTypeDigitizer),
    kIOHIDEventFieldDigitizerY,
    kIOHIDEventFieldDigitizerZ,
    kIOHIDEventFieldDigitizerButtonMask,
    kIOHIDEventFieldDigitizerType,
    kIOHIDEventFieldDigitizerIndex,
    kIOHIDEventFieldDigitizerIdentity,
    kIOHIDEventFieldDigitizerEventMask,
    kIOHIDEventFieldDigitizerRange,
    kIOHIDEventFieldDigitizerTouch,
    kIOHIDEventFieldDigitizerPressure,
    kIOHIDEventFieldDigitizerAuxiliaryPressure, // BarrelPressure
    kIOHIDEventFieldDigitizerTwist,
    kIOHIDEventFieldDigitizerTiltX,
    kIOHIDEventFieldDigitizerTiltY,
    kIOHIDEventFieldDigitizerAltitude,
    kIOHIDEventFieldDigitizerAzimuth,
    kIOHIDEventFieldDigitizerQuality,
    kIOHIDEventFieldDigitizerDensity,
    kIOHIDEventFieldDigitizerIrregularity,
    kIOHIDEventFieldDigitizerMajorRadius,
    kIOHIDEventFieldDigitizerMinorRadius,
    kIOHIDEventFieldDigitizerCollection,
    kIOHIDEventFieldDigitizerCollectionChord,
    kIOHIDEventFieldDigitizerChildEventMask,
    kIOHIDEventFieldDigitizerIsDisplayIntegrated,
    kIOHIDEventFieldDigitizerQualityRadiiAccuracy,
};


#define B64DEC(str) ([[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@(str) options:kNilOptions] encoding:NSUTF8StringEncoding] UTF8String])
extern IOHIDEventRef ob_func0(NSArray <UITouch *> *touches) {
    
    /* IOHIDEventAppendEvent */
    static void (*func1)(IOHIDEventRef event, IOHIDEventRef childEvent);
    /* IOHIDEventSetIntegerValue */
    static void (*func2)(IOHIDEventRef event, IOHIDEventField field, int value);
    /* IOHIDEventSetSenderID */
    //static void (*func3)(IOHIDEventRef event, uint64_t sender);
    /* IOHIDEventCreateDigitizerEvent */
    static IOHIDEventRef (*func4)(CFAllocatorRef allocator, AbsoluteTime timeStamp, IOHIDDigitizerTransducerType type,
                                  uint32_t index, uint32_t identity, uint32_t eventMask, uint32_t buttonMask,
                                  IOHIDFloat x, IOHIDFloat y, IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat barrelPressure,
                                  Boolean range, Boolean touch, IOOptionBits options);
    /* IOHIDEventCreateDigitizerFingerEventWithQuality */
    static IOHIDEventRef (*func5)(CFAllocatorRef allocator, AbsoluteTime timeStamp,
                                  uint32_t index, uint32_t identity, uint32_t eventMask,
                                  IOHIDFloat x, IOHIDFloat y, IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat twist,
                                  IOHIDFloat minorRadius, IOHIDFloat majorRadius, IOHIDFloat quality, IOHIDFloat density, IOHIDFloat irregularity,
                                  Boolean range, Boolean touch, IOOptionBits options);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *IOKit = dlopen(B64DEC("L1N5c3RlbS9MaWJyYXJ5L0ZyYW1ld29ya3MvSU9LaXQuZnJhbWV3b3JrL0lPS2l0"), RTLD_NOW);
        func1       = dlsym(IOKit, B64DEC("SU9ISURFdmVudEFwcGVuZEV2ZW50"));
        func2       = dlsym(IOKit, B64DEC("SU9ISURFdmVudFNldEludGVnZXJWYWx1ZQ=="));
        func4       = dlsym(IOKit, B64DEC("SU9ISURFdmVudENyZWF0ZURpZ2l0aXplckV2ZW50"));
        func5       = dlsym(IOKit, B64DEC("SU9ISURFdmVudENyZWF0ZURpZ2l0aXplckZpbmdlckV2ZW50V2l0aFF1YWxpdHk="));
    });
    
    uint64_t abTime = mach_absolute_time();
    AbsoluteTime timeStamp;
    timeStamp.hi = (UInt32)(abTime >> 32);
    timeStamp.lo = (UInt32)(abTime);
    
    IOHIDEventRef handEvent = func4(kCFAllocatorDefault,               // allocator
                                    timeStamp,                         // timestamp
                                    kIOHIDDigitizerTransducerTypeHand, // type
                                    0,                                 // index
                                    0,                                 // identity
                                    kIOHIDDigitizerEventTouch,         // eventMask
                                    0,                                 // buttonMask
                                    0,                                 // x
                                    0,                                 // y
                                    0,                                 // z
                                    0,                                 // tipPressure
                                    0,                                 // barrelPressure
                                    0,                                 // range
                                    true,                              // touch
                                    0);                                // options
    
    func2(handEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, true);
    
    for (UITouch *touch in touches)
    {
        
        uint32_t eventMask = (touch.phase == UITouchPhaseMoved) ? kIOHIDDigitizerEventPosition : (kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch);
        uint32_t isTouching = (touch.phase == UITouchPhaseEnded) ? 0 : 1;
        CGPoint touchLocation = [touch locationInView:touch.window];
        
        IOHIDEventRef fingerEvent = func5(kCFAllocatorDefault,                       // allocator
                                          timeStamp,                                 // timestamp
                                          (UInt32)[touches indexOfObject:touch] + 1, // index
                                          2,                                         // identity
                                          eventMask,                                 // eventMask
                                          (IOHIDFloat)touchLocation.x,               // x
                                          (IOHIDFloat)touchLocation.y,               // y
                                          0.0,                                       // z
                                          0,                                         // tipPressure
                                          0,                                         // twist
                                          5.0,                                       // minor radius
                                          5.0,                                       // major radius
                                          1.0,                                       // quality
                                          1.0,                                       // density
                                          1.0,                                       // irregularity
                                          (IOHIDFloat)isTouching,                    // range
                                          (IOHIDFloat)isTouching,                    // touch
                                          0);                                        // options
        
        func2(fingerEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);
        func1(handEvent, fingerEvent);
        
        CFRelease(fingerEvent);
        
    }
    
    return handEvent;
}

