//
//  WPCacheManager.h
//  FMBDDataCache
//
//  Created by 王鹏 on 16/6/6.
//  Copyright © 2016年 王鹏. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CompleteDict)(NSDictionary *dict);
typedef void(^CompleteData)(NSData *data);
typedef void(^CompleteArray)(NSArray *array);
typedef void(^CompleteString)(NSString *str);



/**
 数据缓存类：缓存格式为字典、数组、字符串、二进制数据
 原本因为存在子线程去在主线程，可能即存即取可能取不到，但是因为内存中有缓存，所以不会存在该问题。
 数据操作线程安全
 主要使用于App中数据的轻量缓存 简单缓存，每一个用户对应一个缓存数据库，记录对应的操作设置，简单的网络数据缓存
 */
@interface WPCacheManager : NSObject

+ (instancetype)shareManager;
+ (void)destroy;

#pragma mark - 取 主线程中操作 主要是考虑到取完数据刷新页面是需要在主线程中
- (void)valueForKey:(NSString *)key completedDict:(CompleteDict)completed;
- (void)valueForKey:(NSString *)key completedData:(CompleteData)completed;
- (void)valueForKey:(NSString *)key completedArray:(CompleteArray)completed;
- (void)valueForKey:(NSString *)key completedString:(CompleteString)completed;

#pragma mark - 存 子线程操作

- (void)setDictValue:(NSDictionary *)value forKey:(NSString *)key;
- (void)setArrayValue:(NSArray *)value forKey:(NSString *)key;
- (void)setStringValue:(NSString *)str foeKey:(NSString *)key;
- (void)setDataValue:(NSData*)data forKey:(NSString*)key;

#pragma mark - 删 子线程操作

/**
 根据key清除缓存
 
 @param key 字符串
 */
- (void)deleteForKey:(NSString *)key;

/**
 清除内存缓存
 */
- (void)clearCache;

/**
 清除数据库与内存缓存
 */
- (void)deleteAllCache;
@end
