//
//  NSNoficationCenter+Extension.m
//  ArchitectureProject
//
//  Created by 李义真 on 2016/11/10.
//  Copyright © 2016年 李义真. All rights reserved.
//

#import <objc/runtime.h>
#import "NSNoficationCenter+Extension.h"

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
- (void)lyz_inject_addObserver:(id)observer
                      selector:(SEL)aSelector
                          name:(NSNotificationName)aName
                        object:(id)anObject;//注入对象注册观察者
@end

@implementation GBLInjectObject(Notification)
//去掉SEL中的：
- (NSString*)getSelectorName:(SEL)sel
{
    NSString* stringSel = NSStringFromSelector(sel);
    NSMutableString* observerSELName = [NSMutableString new];
    for(int i = 0 ; i < stringSel.length ; i ++)
    {
        NSString* charIndex = [stringSel substringWithRange:NSMakeRange(i, 1)];
        if([charIndex isEqualToString:@":"])
        {
            break;
        }else
        {
            [observerSELName appendString:charIndex];
        }
    }
    
    return [observerSELName copy];
}

//注入对象中替换响应方法命名
- (NSString*)getInjectNotificationSELName:(NSString*)observerSELName hasArgs:(BOOL)hasArgs
{
    if(observerSELName.length == 0) return nil;
    
    NSString* injectSELName = nil;
    if(hasArgs)
    {
    	injectSELName =	[NSString stringWithFormat:@"GBLInject_%@:",observerSELName];
    }else
    {
    	injectSELName =	[NSString stringWithFormat:@"GBLInject_%@",observerSELName];
    }
    return injectSELName;
}

- (void)lyz_inject_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    if([observer isKindOfClass:[NSObject class]])
    {
        NSObject* obj = observer;
        NSString* observerSELName = [self getSelectorName:aSelector];
        Method observerMethod = class_getInstanceMethod([obj class], aSelector);
        
        NSArray* argTypeList = [self getObserverArgumentsType:obj aSelector:aSelector];
        
        NSString* injectSELName = nil;
        Method injectMethod = nil;
        if(argTypeList.count == 2)
        {
            injectSELName = [self getInjectNotificationSELName:observerSELName hasArgs:NO];
            injectMethod = class_getInstanceMethod([self class], @selector(lyz_inject_responseNotificationNoArg));
        }
        
        if(argTypeList.count == 3)
        {
            injectSELName = [self getInjectNotificationSELName:observerSELName hasArgs:YES];
            injectMethod = class_getInstanceMethod([self class], @selector(lyz_inject_responseNotificationWithArg:));
        }
        
        if(injectSELName && injectMethod)
        {
            //动态添加响应方法
            SEL injectSEL = NSSelectorFromString(injectSELName);
            IMP injectIMP = method_getImplementation(injectMethod);
            class_addMethod([self class], injectSEL, injectIMP, method_getTypeEncoding(injectMethod));
            
            //交换方法 注意：一定要根据SEL重新获取Method
            Method newInjectMethod = class_getInstanceMethod([self class], injectSEL);
            method_exchangeImplementations(observerMethod, newInjectMethod);
            
            NSLog(@"lyz_inject_addObserver injectSEL:%@ \n",NSStringFromSelector(injectSEL));
        }

        NSLog(@"lyz_inject_addObserver postName:%@ \n observer:%@ \n observerSelector:%@ \n",aName,obj,NSStringFromSelector(aSelector));
    }
}


- (void)notificationResponse:(NSNotification*)notification cmd:(SEL)cmd observer:(id)observer
{
	//此时self 指的是GBLInjectObject实例
    NSString* observerSELName = [self getSelectorName:cmd];
    NSString* newInjectSELName = [self getInjectNotificationSELName:observerSELName hasArgs:notification == nil ? NO : YES];
    
    NSLog(@"notificationResponse \n observer:%@ \n sel:%@ \n notification:%@",observer,observerSELName,notification.description);
    
    SEL newInjectSelector = NSSelectorFromString(newInjectSELName);
    Method newInjectMethod = class_getInstanceMethod([self class], newInjectSelector);
    IMP newInjectIMP = method_getImplementation(newInjectMethod);
    
    if(notification == nil)
    {
        void (*func)(id, SEL) = (void *)newInjectIMP;
        func(self.referenceObj,newInjectSelector);
    }else
    {
        void (*func)(id, SEL,NSNotification *) = (void *)newInjectIMP;
        func(self.referenceObj,newInjectSelector,notification);
    }
}

- (void)lyz_inject_responseNotificationNoArg
{
    //方法交换以后，如果在此方法中取self，此时的self是原observer
    if([NSThread isMainThread])
    {
        NSLog(@"lyz_inject_responseNotificationNoArg  MainThread \n");
        [self.injectObj notificationResponse:nil cmd:_cmd observer:self];
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"lyz_inject_responseNotificationNoArg  DispatchMainQueue \n");
            [self.injectObj notificationResponse:nil cmd:_cmd observer:self];
        });
    }
}

- (void)lyz_inject_responseNotificationWithArg:(NSNotification *)notification
{
    //方法交换以后，如果在此方法中取self，此时的self是原observer
    if([NSThread isMainThread])
    {
        NSLog(@"lyz_inject_responseNotificationWithArg  MainThread \n");
        [self.injectObj notificationResponse:notification cmd:_cmd observer:self];
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"lyz_inject_responseNotificationWithArg  DispatchMainQueue \n");
            [self.injectObj notificationResponse:notification cmd:_cmd observer:self];
        });
    }
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

#ifdef GBL_NOTIFICATIONCENTER_SWITCH
+ (void)load
{
    //交换注册通知方法
    Method orgObserverMethod = class_getInstanceMethod([self class], @selector(addObserver:selector:name:object:));
    Method lyzObserverMethod = class_getInstanceMethod([self class], @selector(lyz_addObserver:selector:name:object:));
    method_exchangeImplementations(orgObserverMethod, lyzObserverMethod);
}
#endif

- (void)lyz_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    if([NSThread isMainThread])
    {
        [self rigisterObserverNotification:observer selector:aSelector name:aName object:anObject];
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rigisterObserverNotification:observer selector:aSelector name:aName object:anObject];
        });
    }
}

- (void)rigisterObserverNotification:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    if([observer isKindOfClass:[NSObject class]])
    {
        NSObject* obj = observer;
        if(obj.injectObj == nil)//保证仅注入一次内部对象
        {
            obj.injectObj = [GBLInjectObject new];
        }
        NSLog(@"lyz_addObserver observer:%@ postName:%@ selector:%@",obj,aName,NSStringFromSelector(aSelector));
        [obj.injectObj lyz_inject_addObserver:obj selector:aSelector name:aName object:anObject];
    }
    [self lyz_addObserver:observer selector:aSelector name:aName object:anObject];
}
@end
