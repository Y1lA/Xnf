#import "MFStore.h"

@interface MFStore ()
@property (nonatomic, strong) NSMutableDictionary *state;
@property (nonatomic, copy) NSString *root;
@property (nonatomic, copy) NSString *pdfsDir;
@property (nonatomic, copy) NSString *drawingsDir;
@property (nonatomic, strong) NSArray<MFEdition *> *editions;
@end

@implementation MFStore

+ (instancetype)shared {
    static MFStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MFStore alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _editions = MFLoadEditions();
        _questionsPerEdition = MFQuestionsPerEdition();
        NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        if (docs.length == 0) {
            docs = NSTemporaryDirectory();
        }
        _root = [docs copy];
        _pdfsDir = [[_root stringByAppendingPathComponent:@"PDFs"] copy];
        _drawingsDir = [[_root stringByAppendingPathComponent:@"Drawings"] copy];
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:_pdfsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        [fm createDirectoryAtPath:_drawingsDir withIntermediateDirectories:YES attributes:nil error:NULL];
        [self loadState];
    }
    return self;
}

#pragma mark - الحالة

- (NSString *)statePath {
    return [self.root stringByAppendingPathComponent:@"state.json"];
}

- (void)loadState {
    NSData *data = [NSData dataWithContentsOfFile:[self statePath]];
    NSMutableDictionary *state = nil;
    if (data) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        if ([json isKindOfClass:[NSMutableDictionary class]]) {
            state = json;
        }
    }
    if (!state) {
        state = [NSMutableDictionary dictionary];
    }
    if (![state[@"editions"] isKindOfClass:[NSMutableDictionary class]]) {
        state[@"editions"] = [NSMutableDictionary dictionary];
    }
    self.state = state;
}

- (void)flush {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.state options:0 error:NULL];
    if (data) {
        [data writeToFile:[self statePath] atomically:YES];
    }
}

- (NSString *)keyForEdition:(NSInteger)edition {
    return [NSString stringWithFormat:@"%ld", (long)edition];
}

- (NSMutableDictionary *)dictForEdition:(NSInteger)edition create:(BOOL)create {
    NSMutableDictionary *all = self.state[@"editions"];
    if (![all isKindOfClass:[NSMutableDictionary class]]) {
        all = [NSMutableDictionary dictionary];
        self.state[@"editions"] = all;
    }
    NSString *key = [self keyForEdition:edition];
    NSMutableDictionary *dict = all[key];
    if (![dict isKindOfClass:[NSMutableDictionary class]]) {
        if (!create) {
            return nil;
        }
        dict = [NSMutableDictionary dictionary];
        all[key] = dict;
    }
    return dict;
}

#pragma mark - الإصدارات

- (NSInteger)editionCount {
    return (NSInteger)self.editions.count;
}

- (MFEdition *)editionWithNumber:(NSInteger)number {
    for (MFEdition *edition in self.editions) {
        if (edition.number == number) {
            return edition;
        }
    }
    return nil;
}

#pragma mark - آخر سؤال

- (NSInteger)lastQuestionForEdition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSInteger last = [dict[@"last"] integerValue];
    if (last < 1 || last > self.questionsPerEdition) {
        return 1;
    }
    return last;
}

- (void)setLastQuestion:(NSInteger)question edition:(NSInteger)edition {
    if (question < 1) {
        question = 1;
    }
    if (question > self.questionsPerEdition) {
        question = self.questionsPerEdition;
    }
    [self dictForEdition:edition create:YES][@"last"] = @(question);
    [self flush];
}

#pragma mark - الأسئلة المحلولة

- (BOOL)isSolved:(NSInteger)question edition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *solved = dict[@"solved"];
    if (![solved isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return [solved[[self keyForEdition:question]] boolValue];
}

- (void)setSolved:(BOOL)solved question:(NSInteger)question edition:(NSInteger)edition {
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    NSMutableDictionary *marks = dict[@"solved"];
    if (![marks isKindOfClass:[NSMutableDictionary class]]) {
        marks = [NSMutableDictionary dictionary];
        dict[@"solved"] = marks;
    }
    marks[[self keyForEdition:question]] = @(solved);
    if ([self solvedCountForEdition:edition] >= self.questionsPerEdition) {
        dict[@"completed"] = @(YES);
    }
    [self flush];
}

- (NSInteger)solvedCountForEdition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *solved = dict[@"solved"];
    if (![solved isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    NSInteger count = 0;
    for (NSNumber *value in solved.allValues) {
        if ([value boolValue]) {
            count++;
        }
    }
    return count;
}

#pragma mark - علامة الإصدار

- (BOOL)isCompletedEdition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    return [dict[@"completed"] boolValue];
}

- (void)setCompleted:(BOOL)completed edition:(NSInteger)edition {
    [self dictForEdition:edition create:YES][@"completed"] = @(completed);
    [self flush];
}

- (void)resetProgressForEdition:(NSInteger)edition {
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    [dict removeObjectForKey:@"solved"];
    [dict removeObjectForKey:@"completed"];
    dict[@"last"] = @(1);
    [self flush];
}

#pragma mark - ملف الإصدار

- (NSString *)pdfPathForEdition:(NSInteger)edition {
    NSString *path = [self.pdfsDir stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"edition-%ld.pdf", (long)edition]];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

- (BOOL)hasPDFForEdition:(NSInteger)edition {
    return [self pdfPathForEdition:edition] != nil;
}

- (BOOL)importPDFFromURL:(NSURL *)url edition:(NSInteger)edition error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSString *destination = [self.pdfsDir stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"edition-%ld.pdf", (long)edition]];
    if ([fm fileExistsAtPath:destination]) {
        [fm removeItemAtPath:destination error:NULL];
    }
    BOOL ok = [fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:destination] error:error];
    if (scoped) {
        [url stopAccessingSecurityScopedResource];
    }
    if (ok) {
        NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
        dict[@"pdf"] = @(YES);
        [self flush];
    }
    return ok;
}

- (void)removePDFForEdition:(NSInteger)edition {
    NSString *path = [self.pdfsDir stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"edition-%ld.pdf", (long)edition]];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    [dict removeObjectForKey:@"pdf"];
    [self flush];
}

#pragma mark - الصفحات

- (NSInteger)questionsPerPageForEdition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSInteger count = [dict[@"qpp"] integerValue];
    if (count < 1 || count > 6) {
        return 2;
    }
    return count;
}

- (void)setQuestionsPerPage:(NSInteger)count edition:(NSInteger)edition {
    if (count < 1) {
        count = 1;
    }
    if (count > 6) {
        count = 6;
    }
    [self dictForEdition:edition create:YES][@"qpp"] = @(count);
    [self flush];
}

- (NSInteger)firstPageForEdition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSInteger page = [dict[@"firstPage"] integerValue];
    return page >= 1 ? page : 1;
}

- (void)setFirstPage:(NSInteger)page edition:(NSInteger)edition {
    if (page < 1) {
        page = 1;
    }
    [self dictForEdition:edition create:YES][@"firstPage"] = @(page);
    [self flush];
}

- (NSInteger)pageForQuestion:(NSInteger)question edition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *pages = dict[@"pages"];
    if ([pages isKindOfClass:[NSDictionary class]]) {
        NSInteger override = [pages[[self keyForEdition:question]] integerValue];
        if (override > 0) {
            return override;
        }
    }
    NSInteger qpp = [self questionsPerPageForEdition:edition];
    NSInteger first = [self firstPageForEdition:edition];
    NSInteger index = question > 0 ? question - 1 : 0;
    return first + index / qpp;
}

- (void)setPage:(NSInteger)page forQuestion:(NSInteger)question edition:(NSInteger)edition {
    if (page < 1) {
        return;
    }
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    NSMutableDictionary *pages = dict[@"pages"];
    if (![pages isKindOfClass:[NSMutableDictionary class]]) {
        pages = [NSMutableDictionary dictionary];
        dict[@"pages"] = pages;
    }
    pages[[self keyForEdition:question]] = @(page);
    [self flush];
}

- (BOOL)hasPageOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *pages = dict[@"pages"];
    if (![pages isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return [pages[[self keyForEdition:question]] integerValue] > 0;
}

- (void)clearPageOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition {
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    NSMutableDictionary *pages = dict[@"pages"];
    [pages removeObjectForKey:[self keyForEdition:question]];
    [self flush];
}

#pragma mark - التوقيتات

- (NSInteger)timestampForQuestion:(NSInteger)question edition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *times = dict[@"times"];
    if ([times isKindOfClass:[NSDictionary class]]) {
        NSNumber *override = times[[self keyForEdition:question]];
        if (override) {
            return override.integerValue;
        }
    }
    MFEdition *info = [self editionWithNumber:edition];
    NSInteger index = question - 1;
    if (index >= 0 && index < (NSInteger)info.timestamps.count) {
        return info.timestamps[(NSUInteger)index].integerValue;
    }
    return 0;
}

- (void)setTimestamp:(NSInteger)seconds forQuestion:(NSInteger)question edition:(NSInteger)edition {
    if (seconds < 0) {
        seconds = 0;
    }
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    NSMutableDictionary *times = dict[@"times"];
    if (![times isKindOfClass:[NSMutableDictionary class]]) {
        times = [NSMutableDictionary dictionary];
        dict[@"times"] = times;
    }
    times[[self keyForEdition:question]] = @(seconds);
    [self flush];
}

- (BOOL)hasTimestampOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition {
    NSDictionary *dict = [self dictForEdition:edition create:NO];
    NSDictionary *times = dict[@"times"];
    if (![times isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return times[[self keyForEdition:question]] != nil;
}

- (void)shiftTimestampsBy:(NSInteger)delta edition:(NSInteger)edition {
    for (NSInteger q = 1; q <= self.questionsPerEdition; q++) {
        NSInteger current = [self timestampForQuestion:q edition:edition];
        NSInteger shifted = current + delta;
        if (shifted < 0) {
            shifted = 0;
        }
        [self setTimestamp:shifted forQuestion:q edition:edition];
    }
}

- (void)resetTimestampsForEdition:(NSInteger)edition {
    NSMutableDictionary *dict = [self dictForEdition:edition create:YES];
    [dict removeObjectForKey:@"times"];
    [self flush];
}

#pragma mark - رسومات القلم

- (NSString *)drawingPathForQuestion:(NSInteger)question edition:(NSInteger)edition {
    return [self.drawingsDir stringByAppendingPathComponent:
            [NSString stringWithFormat:@"edition-%ld-q%ld.pkdrawing", (long)edition, (long)question]];
}

- (NSData *)drawingDataForQuestion:(NSInteger)question edition:(NSInteger)edition {
    return [NSData dataWithContentsOfFile:[self drawingPathForQuestion:question edition:edition]];
}

- (void)saveDrawingData:(NSData *)data question:(NSInteger)question edition:(NSInteger)edition {
    if (data.length == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:[self drawingPathForQuestion:question edition:edition]
                                                  error:NULL];
        return;
    }
    [data writeToFile:[self drawingPathForQuestion:question edition:edition] atomically:YES];
}

- (BOOL)hasDrawingForQuestion:(NSInteger)question edition:(NSInteger)edition {
    return [[NSFileManager defaultManager] fileExistsAtPath:
            [self drawingPathForQuestion:question edition:edition]];
}

- (void)clearDrawingForQuestion:(NSInteger)question edition:(NSInteger)edition {
    [[NSFileManager defaultManager] removeItemAtPath:[self drawingPathForQuestion:question edition:edition]
                                              error:NULL];
}

@end
