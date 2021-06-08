#import <Foundation/Foundation.h>

@interface DRYLocalization : NSObject

@property (nonatomic, copy) NSString * language;
@property (nonatomic, retain) NSMutableDictionary *translations;

+ (DRYLocalization *)sharedInstance;
+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)stringForKey:(NSString *)key withInt:(int)num;
+ (NSString *)stringForKey:(NSString *)key withLong:(long)num;

@end
