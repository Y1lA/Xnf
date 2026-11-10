#import "MFEdition.h"

@implementation MFEdition
@end

static NSArray<MFEdition *> *gEditions = nil;
static NSInteger gQuestionsPerEdition = 48;

NSInteger MFQuestionsPerEdition(void) {
    MFLoadEditions();
    return gQuestionsPerEdition;
}

NSArray<MFEdition *> *MFLoadEditions(void) {
    if (gEditions) {
        return gEditions;
    }
    NSMutableArray<MFEdition *> *list = [NSMutableArray array];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"editions" ofType:@"json"];
    NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSNumber *qpe = json[@"questionsPerEdition"];
            if ([qpe isKindOfClass:[NSNumber class]] && qpe.integerValue > 0) {
                gQuestionsPerEdition = qpe.integerValue;
            }
            NSArray *editions = json[@"editions"];
            if ([editions isKindOfClass:[NSArray class]]) {
                for (NSDictionary *raw in editions) {
                    if (![raw isKindOfClass:[NSDictionary class]]) {
                        continue;
                    }
                    MFEdition *edition = [[MFEdition alloc] init];
                    edition.number = [raw[@"number"] integerValue];
                    edition.videoID = [raw[@"videoID"] isKindOfClass:[NSString class]] ? raw[@"videoID"] : @"";
                    edition.title = [raw[@"title"] isKindOfClass:[NSString class]] ? raw[@"title"] : @"";
                    edition.duration = [raw[@"duration"] integerValue];
                    NSMutableArray<NSNumber *> *stamps = [NSMutableArray array];
                    NSArray *rawStamps = raw[@"timestamps"];
                    if ([rawStamps isKindOfClass:[NSArray class]]) {
                        for (NSNumber *value in rawStamps) {
                            [stamps addObject:@([value integerValue])];
                        }
                    }
                    while (stamps.count < (NSUInteger)gQuestionsPerEdition) {
                        [stamps addObject:@(0)];
                    }
                    edition.timestamps = stamps;
                    [list addObject:edition];
                }
            }
        }
    }
    [list sortUsingComparator:^NSComparisonResult(MFEdition *a, MFEdition *b) {
        if (a.number == b.number) {
            return NSOrderedSame;
        }
        return a.number < b.number ? NSOrderedAscending : NSOrderedDescending;
    }];
    gEditions = list;
    return list;
}
