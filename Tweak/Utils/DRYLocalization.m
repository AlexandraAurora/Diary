// made by https://twitter.com/tomt000

#import "DRYLocalization.h"
#define kBundlePath @"/Library/PreferenceBundles/DiaryPreferences.bundle/localization/"

@interface DRYLocalization ()
@end

@implementation DRYLocalization

+ (DRYLocalization *)sharedInstance
{
    __strong static id _sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.translations = [[NSMutableDictionary alloc] init];

        [self loadTranslations:@"en"];

        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        if(!language) return self;
        NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
        if(!languageDic) return self;
        NSString *languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"];
        if(!languageCode) return self;
        NSString *languageCodeLocal = [[NSString stringWithFormat:@"%@-%@", languageCode, [languageDic objectForKey:@"kCFLocaleScriptCodeKey"]] lowercaseString];

        if(![languageCode isEqualToString:@"en"]) [self loadTranslations:languageCode];
        if(![languageCode isEqualToString:@"en"]) [self loadTranslations:languageCodeLocal];
    }
    return self;
}

-(void)loadTranslations:(NSString*)language {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
    NSData * JSONData = [NSData dataWithContentsOfURL:[bundle URLForResource:language withExtension:@"json"]];
    if(!JSONData) return;
    self.language = language;
    [self overwriteTranslations: [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil]];
}

-(void)overwriteTranslations:(NSDictionary*)newTranslation{
    for (NSString* key in newTranslation)
      [self.translations setObject:newTranslation[key] forKey:key];
}

- (NSString *)stringForKey:(NSString *)key {
    NSString *trad = [self.translations objectForKey:key];
    if (trad) return trad;
    return @"Transl. Err";
}

- (NSString *)getLanguage {
    return self.language;
}

+ (NSString *)stringForKey:(NSString *)key
{
    return [[DRYLocalization sharedInstance] stringForKey:key];
}

+ (NSString *)stringForKey:(NSString *)key withInt:(int)num
{
    NSString *str = [[[DRYLocalization sharedInstance] stringForKey:key] stringByReplacingOccurrencesOfString:@"*" withString:[NSString stringWithFormat:@"%d",num]];

    if([[[DRYLocalization sharedInstance] getLanguage] isEqualToString:@"ar"]){
      NSDictionary *numbersDictionary = @{@"0" : @"٠", @"1" : @"١", @"2" : @"٢", @"3" : @"٣", @"4" : @"٤", @"5" : @"٥", @"6" : @"٦", @"7" : @"٧", @"8" : @"٨", @"9" : @"٩"};
      for (NSString *key in numbersDictionary) {
        str = [str stringByReplacingOccurrencesOfString:key withString:numbersDictionary[key]];
      }
    }
    return str;
}

+ (NSString *)stringForKey:(NSString *)key withLong:(long)num
{
    NSString *str = [[[DRYLocalization sharedInstance] stringForKey:key] stringByReplacingOccurrencesOfString:@"*" withString:[NSString stringWithFormat:@"%ld",num]];

    if([[[DRYLocalization sharedInstance] getLanguage] isEqualToString:@"ar"]){
      NSDictionary *numbersDictionary = @{@"0" : @"٠", @"1" : @"١", @"2" : @"٢", @"3" : @"٣", @"4" : @"٤", @"5" : @"٥", @"6" : @"٦", @"7" : @"٧", @"8" : @"٨", @"9" : @"٩"};
      for (NSString *key in numbersDictionary) {
        str = [str stringByReplacingOccurrencesOfString:key withString:numbersDictionary[key]];
      }
    }
    return str;
}

@end
