//
//  NSNoficationCenter+Extension.m
//  ArchitectureProject
//
//  Created by 李义真 on 2016/11/10.
//  Copyright © 2016年 李义真. All rights reserved.
//

#import <objc/runtime.h>
#import "NSNoficationCenter+Extension.h"
#import "TestObject.h"

//注入对象
@interface GBLInjectObject:NSObject
@property(nonatomic,weak)id referenceObj;//外部使用weak属性，防止外部使用者使用已经释放的对象；内部使用__unsafe__unretain
@end

@interface GBLInjectObject()
@property(nonatomic,unsafe_unretained)id _inner_referenceObj;
@end

@implementation GBLInjectObject
- (void)setReferenceObj:(id)referenceObj
{
    _referenceObj = referenceObj;
    self._inner_referenceObj = referenceObj;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:__inner_referenceObj];
}
@end

//基类对象扩展
@interface NSObject(Inject)
@property(nonatomic,strong)GBLInjectObject* injectObj;
@end

static const void* INJECT_OBJECT_KEY = "__inject__object__key__";

@implementation NSObject(Inject)
- (void)setInjectObj:(GBLInjectObject *)injectObj
{
    injectObj.referenceObj = self;
    objc_setAssociatedObject(self, INJECT_OBJECT_KEY, injectObj, OBJC_ASSOCIATION_RETAIN);
}

- (GBLInjectObject*)injectObj
{
    return objc_getAssociatedObject(self, INJECT_OBJECT_KEY);
}
@end

//注入对象扩展
@interface GBLInjectObject(Notification)
@property(nonatomic,copy)NSString* observerSELName;
@property(nonatomic,copy)NSString* notificationName;
- (void)lyz_inject_addObserver:(id)observer
                      selector:(SEL)aSelector
                          name:(NSNotificationName)aName
                        object:(id)anObject;//注入对象注册观察者
@end

static const void* INJECT_OBJECT_OBSERVER_SEL_KEY = "__inject__object__observer__sel__key__";
static const void* INJECT_OBJECT_NOTIFICATION_NAME = "__inject__object__notification__name__";

@implementation GBLInjectObject(Notification)
- (void)setObserverSELName:(NSString *)observerSELName
{
    objc_setAssociatedObject(self, INJECT_OBJECT_OBSERVER_SEL_KEY, observerSELName, OBJC_ASSOCIATION_COPY);
}

- (NSString*)observerSELName
{
    return objc_getAssociatedObject(self, INJECT_OBJECT_OBSERVER_SEL_KEY);
}

- (void)setNotificationName:(NSString *)notificationName
{
     objc_setAssociatedObject(self, INJECT_OBJECT_NOTIFICATION_NAME, notificationName, OBJC_ASSOCIATION_COPY);
}

- (NSString*)notificationName
{
    return objc_getAssociatedObject(self, INJECT_OBJECT_NOTIFICATION_NAME);
}

- (void)lyz_inject_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    if([observer isKindOfClass:[NSObject class]])
    {
        NSObject* obj = observer;
        NSArray* argTypeList = [self getObserverArgumentsType:obj aSelector:aSelector];
        NSString* lastType = argTypeList.lastObject;
//        if(argTypeList.count == 3 && [lastType isEqualToString:@"@"])
//        {
        
        if([obj isKindOfClass:[TestObject class]])
        {
            self.observerSELName = NSStringFromSelector(aSelector);
            self.notificationName = aName;
            Method observerMethod = class_getInstanceMethod([obj class], aSelector);
            Method injectMethod = class_getInstanceMethod([self class], @selector(lyz_inject_responseNotification:));
            
            NSLog(@"lyz_inject_addObserver \n observer:%@ \n selector:%@ \n ",obj,self.observerSELName);
            method_exchangeImplementations(observerMethod, injectMethod);
        }
        
//       }
        
    }
}

- (void)lyz_inject_responseNotification:(NSNotification *)notification
{
    //方法交换以后，如果在此方法中取self，此时的self是原observer
    NSLog(@"lyz_inject_responseNotification \n");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"notificationResponse \n Time:%f \n notificationName:%@ \n observer:%@ \n sel:%@ \n notification:%@  ",[[NSDate date] timeIntervalSince1970],self.injectObj.notificationName,self.description,self.injectObj.observerSELName,notification.description);
        [self.injectObj lyz_inject_responseNotification:notification];
    });
}

- (NSArray<NSString*>*)getObserverArgumentsType:(NSObject*)obj aSelector:(SEL)aSelector
{
    NSMutableArray* argList = [NSMutableArray new];
    // 获取方法的参数类型
    Method responseMethod = class_getInstanceMethod([obj class], aSelector);
    unsigned int argumentsCount = method_getNumberOfArguments(responseMethod);
    for (unsigned int argCounter = 0; argCounter < argumentsCount; ++argCounter)
    {
        char* arg =  method_copyArgumentType(responseMethod, argCounter);
        NSString* argType = [NSString stringWithUTF8String:arg];
        if(argType)
        {
            [argList addObject:argType];
        }
    }
    
    return argList;
}
@end

//通知扩展
@implementation NSNotificationCenter(Extension)
+ (void)load
{
    //交换注册通知方法
    Method orgObserverMethod = class_getInstanceMethod([self class], @selector(addObserver:selector:name:object:));
    Method lyzObserverMethod = class_getInstanceMethod([self class], @selector(lyz_addObserver:selector:name:object:));
    method_exchangeImplementations(orgObserverMethod, lyzObserverMethod);
}

- (void)lyz_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        if([observer isKindOfClass:[NSObject class]])
        {
            NSObject* obj = observer;
            if(obj.injectObj == nil)
            {
                obj.injectObj = [GBLInjectObject new];
                [obj.injectObj lyz_inject_addObserver:obj selector:aSelector name:aName object:anObject];
            }
           
        }
        [self lyz_addObserver:observer selector:aSelector name:aName object:anObject];
//    });
}
@end
