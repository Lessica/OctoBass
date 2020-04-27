#ifndef MY_CHHOOK_H
#define MY_CHHOOK_H

#import <malloc/malloc.h>
#import <mach/mach_time.h>
#import <libkern/OSAtomic.h>
#import <dlfcn.h>

#define CHAppName "OctoBass"
#if DEBUG
#define CHDebug
#endif

#import "CaptainHook.h"

#define OCGetIvar(obj, name) object_getIvar((obj), class_getInstanceVariable(object_getClass(obj), #name))
#define OCSetIvar(obj, name, value) object_setIvar((obj), class_getInstanceVariable(object_getClass(obj), #name), (value))

#define OCall(obj, sel, args...) \
	(id)objc_msgSend(obj, @selector(sel), args)
#define OCal0(obj, sel) \
	(id)objc_msgSend(obj, @selector(sel))


#ifdef __cplusplus
extern "C" id objc_msgSendSuper2(struct objc_super *, SEL, ...);
#define EDGF_CAPI extern "C" 
#else
extern id objc_msgSendSuper2(struct objc_super *, SEL, ...);
#define EDGF_CAPI extern 
#endif

#define OCSuperDealloc(obj) \
{\
	struct objc_super the_super;\
	the_super.receiver = obj;\
	the_super.super_class = class_getSuperclass(object_getClass(obj));\
	objc_msgSendSuper2(&the_super, @selector(dealloc));\
}

#define _cc(cls) objc_getClass(CHStringify(cls))
#define _mcc(cls) objc_getMetaClass(CHStringify(cls))

#define IS_OBJECT_VALID(P) (malloc_zone_from_ptr(P) != NULL)

#ifdef CHDebug
	#define MyLog CHDebugLogSource
#else
	#define MyLog(...)
#endif

__attribute__((unused)) CHInline
static BOOL MyHookMessage(Class cls, SEL sel, IMP repl_imp, IMP *orig_imp_export)
{
	if (cls != nil) {
		Method orig_method = class_getInstanceMethod(cls, sel);
		if (orig_method != nil) {
			IMP orig_imp = method_getImplementation(orig_method);
			if (orig_imp_export != nil) {
				*orig_imp_export = orig_imp;
			}
			method_setImplementation(orig_method, (IMP)repl_imp);
			return YES;
		}
	}
	return NO;
}

__attribute__((unused)) CHInline
static BOOL MyHookClassMessage(Class cls, SEL sel, IMP repl_imp, IMP *orig_imp_export)
{
	if (cls != nil) {
		Method orig_method = class_getClassMethod(cls, sel);
		if (orig_method != nil) {
			IMP orig_imp = method_getImplementation(orig_method);
			if (orig_imp_export != nil) {
				*orig_imp_export = orig_imp;
			}
			method_setImplementation(orig_method, (IMP)repl_imp);
			return YES;
		}
	}
	return NO;
}

#endif  /* MY_CHHOOK_H */

