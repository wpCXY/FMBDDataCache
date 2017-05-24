//
//  ViewController.m
//  FMBDDataCache
//
//  Created by 王鹏 on 16/6/3.
//  Copyright © 2016年 王鹏. All rights reserved.
//

#import "ViewController.h"
#import "WPCacheManager.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textVIew;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WPCacheManager *manager = [WPCacheManager shareManager];
//    [manager setValue:@{@"1":@"one"} forKey:@"dict"];
//    [manager setValue:@[@1,@2] forKey:@"array"];
    [manager setStringValue:@"string" foeKey:@"string"];
//    [manager clearCache];
//    sleep(1);
//    [manager valueForKey:@"dict" completedDict:^(NSDictionary *dict) {
//        _textVIew.text = dict.description;
//    }];
//    
//    [manager valueForKey:@"array" completedArray:^(NSArray *array) {
//        _textVIew.text = array.description;
//    }];
    [manager valueForKey:@"string" completedString:^(NSString *str) {
        _textVIew.text = str;
    }];
    [manager deleteAllCache];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
