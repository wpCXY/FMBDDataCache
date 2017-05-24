//
//  WPCacheManager.m
//  FMBDDataCache
//
//  Created by 王鹏 on 16/6/6.
//  Copyright © 2016年 王鹏. All rights reserved.
//

#import "WPCacheManager.h"
#import <FMDB.h>
#define  CreatTabelSqlate @"CREATE TABLE IF NOT EXISTS \"main\".\"modelCache\" (key VARCHAR PRIMARY KEY  NOT NULL  UNIQUE, value BLOB )"
#define InsertSqlite @"INSERT OR REPLACE INTO modelCache (\'key\',\'value\') VALUES (?,?)"
#define SelectSqlite @"SELECT value FROM modelCache WHERE key=?"
#define DeleteSqlite @"DELETE FROM modelCache where key=?"
#define AllDeleteSQL @"DELETE FROM modelCache"


@interface WPCacheManager ()
@property (nonatomic, strong) FMDatabase          *dataBase;
@property (nonatomic, strong) FMDatabaseQueue     *dataBaseQueue;
@property (nonatomic, strong) NSMutableDictionary *cacheQueue;



@end

@implementation WPCacheManager

static WPCacheManager *cacheManager;

#pragma mark - Life Cycle
+ (instancetype)shareManager {
    
    if (cacheManager) {
        return cacheManager;
    }
    @synchronized(self) {
        if (!cacheManager) {
            cacheManager = [[WPCacheManager alloc] init];
        }
    }
    return cacheManager;
}

+ (void)destroy {
    cacheManager = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self creatDataBase];
    }
    return self;
}

- (void)creatDataBase {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *userPath = [documentPath stringByAppendingPathComponent:@"UserID"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager fileExistsAtPath:userPath]) {
        [fileManager createDirectoryAtPath:userPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    NSString *dbPath = [userPath stringByAppendingPathComponent:@"cache.sqlite"];
    if (![fileManager fileExistsAtPath:dbPath]) {
        _dataBase = [FMDatabase databaseWithPath:dbPath];
        if ([_dataBase open]) {
            [_dataBase executeUpdate:CreatTabelSqlate];
            [_dataBase close];
        }
    }
    _dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
 
    _cacheQueue = [NSMutableDictionary dictionary];
    NSLog(@"------------dbpath:%@--------",dbPath);
}

#pragma mark - 取

- (void)valueForKey:(NSString *)key completedDict:(CompleteDict)completed {

    [self valueForKey:key completedData:^(NSData *data) {
        if (data == nil) {
            if (completed) {
                completed(nil);
            }
            return ;
        }
        NSError *error;
        NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:data
                                                                       options:NSPropertyListMutableContainers
                                                                        format:NULL
                                                                         error:&error];
        completed(dict);

    }];
}
- (void)valueForKey:(NSString *)key completedArray:(CompleteArray)completed {

    [self valueForKey:key completedData:^(NSData *data) {
        if (data == nil) {
            if (completed) {
                completed(nil);
            }
            return ;
        }
        NSError *error;
        NSArray *arrya = [NSPropertyListSerialization propertyListWithData:data
                                                                       options:NSPropertyListMutableContainers
                                                                        format:NULL
                                                                         error:&error];
        completed(arrya);
        
    }];
}
- (void)valueForKey:(NSString *)key completedString:(CompleteString)completed {

    [self valueForKey:key completedData:^(NSData *data) {
        if (data == nil) {
            if (completed) {
                completed(nil);
            }
            return ;
        }
        NSString *str = [[NSString alloc] initWithData:data 
                                              encoding:NSUTF8StringEncoding];
        completed(str);
        
    }];
}
- (void)valueForKey:(NSString *)key completedData:(CompleteData)completed {
    if (key == nil) {
        if (completed) {
            completed(nil);
        }
        return;
    }
    NSData *value = nil;
    if (_cacheQueue.count>0) {
        value = [_cacheQueue objectForKey:key];
    }
    if (value == nil) {
        [_dataBaseQueue inDatabase:^(FMDatabase *db) {
            if ([db open]) {
                FMResultSet *rs = [db executeQuery:SelectSqlite,key];
                if ([rs next]) {
                    NSData *value = [rs dataForColumn:@"value"];
                    completed(value);
                    NSLog(@"----查询数据成功！-------");
                    [db close];
                    return ;
                }
                [db close];
                NSLog(@"-----查询数据失败------");
                completed(nil);
            }
        }];
    } else {
        completed(value);
  
    }
    
}
#pragma mark - 存

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([value isKindOfClass:[NSDictionary class]]||
        [value isKindOfClass:[NSArray class]]) {
        NSError *error;
        NSData *dataValue = [NSPropertyListSerialization dataWithPropertyList:value
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                                      options:NSPropertyListWriteStreamError
                                                                        error:&error];
        [self setDataValue:dataValue forKey:key];
    }

}
- (void)setDictValue:(NSDictionary *)value forKey:(NSString *)key {
    [self setValue:value forKey:key];
}
- (void)setArrayValue:(NSArray *)value forKey:(NSString *)key {
    [self setValue:value forKey:key];
}
- (void)setStringValue:(NSString *)str foeKey:(NSString *)key {
    if (str) {
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [self setDataValue:data forKey:key];
    }
}
- (void)setDataValue:(NSData*)data forKey:(NSString*)key {
    
    if (data == nil || key == nil) return;
    [_cacheQueue setObject:data forKey:key];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         [_dataBaseQueue inDatabase:^(FMDatabase *db) {
             if ([db open]) {
                 BOOL isOk =[db executeUpdate:InsertSqlite,key,data];
                 if (isOk == NO) {
                     NSLog(@"保存Model 失败! key=%@",key);
                 } else  {
                     NSLog(@"保存Model 成功！key=%@",key);
                 }
                 [db close];
             }
         }];
    });
    

}
#pragma mark - 删
- (void)deleteForKey:(NSString *)key {
    if (key.length == 0) return;
    [_cacheQueue removeObjectForKey:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_dataBaseQueue inDatabase:^(FMDatabase *db) {
            if ([db open]) {
                BOOL isOk =[db executeUpdate:DeleteSqlite,key];
                if (isOk == NO) {
                    NSLog(@"删除Model 失败! key=%@",key);
                } else {
                    NSLog(@"删除Model 成功! key=%@",key);
                }
                [db close];
            }
        }];
    });

}
- (void)clearCache {
    [_cacheQueue removeAllObjects];

}
- (void)deleteAllCache {
    
    [_cacheQueue removeAllObjects];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_dataBaseQueue inDatabase:^(FMDatabase *db) {
            if ([db open]) {
                BOOL isOk = [db executeUpdate:AllDeleteSQL];
                if (!isOk) {
                    NSLog(@"-------全部删除失败----");
                } else {
                    NSLog(@"-------全部删除成功----");
                }
                [db close];
            }
            NSLog(@"%@",[NSThread currentThread]);
        }];
    });
}

@end
