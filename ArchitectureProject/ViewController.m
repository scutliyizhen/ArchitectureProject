//
//  ViewController.m
//  ArchitectureProject
//
//  Created by 李义真 on 2016/11/3.
//  Copyright © 2016年 李义真. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"

@interface ViewController ()
@property(nonatomic,strong)UIButton* postNotificationBtn;
@property(nonatomic,strong)UIButton* testButton;
@property(nonatomic,strong)TestObject* testObjc;
@property(nonatomic,strong)NSMutableArray<TestObject*>* testObjList;
@end

@implementation ViewController
- (void)loadView
{
    [super loadView];
    self.postNotificationBtn.frame = CGRectMake(100, 100, 100, 100);
    self.testButton.frame = CGRectMake(100, 300, 100, 100);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.testObjc = [TestObject new];
}

- (void)postButtonClick:(UIButton*)btn
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lyznotification" object:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:@"xyznotification" object:nil];
    });
    NSLog(@"postButtonClick lyznotification  Time:%f",[[NSDate date] timeIntervalSince1970]);
}

- (void)testButtonClick:(UIButton*)btn
{
    self.testObjc = nil;
}

- (UIButton*)postNotificationBtn
{
    if(_postNotificationBtn == nil)
    {
        _postNotificationBtn = [UIButton new];
        _postNotificationBtn.backgroundColor = [UIColor blueColor];
        _postNotificationBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [_postNotificationBtn setTitle:@"发送通知" forState:UIControlStateNormal];
        [_postNotificationBtn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        [self.view addSubview:_postNotificationBtn];
        
        [_postNotificationBtn addTarget:self action:@selector(postButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _postNotificationBtn;
}

- (UIButton*)testButton
{
    if(_testButton == nil)
    {
        _testButton = [UIButton new];
        _testButton.backgroundColor = [UIColor greenColor];
        _testButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [_testButton setTitle:@"测试" forState:UIControlStateNormal];
        [_testButton setTintColor:[UIColor redColor]];
        [_testButton setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        [self.view addSubview:_testButton];
        
        [_testButton addTarget:self action:@selector(testButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _testButton;
}
@end
