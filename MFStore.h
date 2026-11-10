#import <Foundation/Foundation.h>
#import "MFEdition.h"

NS_ASSUME_NONNULL_BEGIN

/// كل حالة المستخدم: آخر سؤال، المحلول، الصفحات، التوقيتات، ملفات PDF، ورسومات القلم.
@interface MFStore : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSArray<MFEdition *> *editions;
@property (nonatomic, readonly) NSInteger questionsPerEdition;

- (nullable MFEdition *)editionWithNumber:(NSInteger)number;
- (NSInteger)editionCount;

// آخر سؤال وصل له المستخدم
- (NSInteger)lastQuestionForEdition:(NSInteger)edition;
- (void)setLastQuestion:(NSInteger)question edition:(NSInteger)edition;

// حالة كل سؤال
- (BOOL)isSolved:(NSInteger)question edition:(NSInteger)edition;
- (void)setSolved:(BOOL)solved question:(NSInteger)question edition:(NSInteger)edition;
- (NSInteger)solvedCountForEdition:(NSInteger)edition;

// علامة الصح على مستوى الإصدار
- (BOOL)isCompletedEdition:(NSInteger)edition;
- (void)setCompleted:(BOOL)completed edition:(NSInteger)edition;
- (void)resetProgressForEdition:(NSInteger)edition;

// ملف الإصدار
- (BOOL)hasPDFForEdition:(NSInteger)edition;
- (nullable NSString *)pdfPathForEdition:(NSInteger)edition;
- (BOOL)importPDFFromURL:(NSURL *)url edition:(NSInteger)edition error:(NSError **)error;
- (void)removePDFForEdition:(NSInteger)edition;

// الصفحات داخل الملف
- (NSInteger)questionsPerPageForEdition:(NSInteger)edition;
- (void)setQuestionsPerPage:(NSInteger)count edition:(NSInteger)edition;
- (NSInteger)firstPageForEdition:(NSInteger)edition;
- (void)setFirstPage:(NSInteger)page edition:(NSInteger)edition;
- (NSInteger)pageForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)setPage:(NSInteger)page forQuestion:(NSInteger)question edition:(NSInteger)edition;
- (BOOL)hasPageOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)clearPageOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition;

// توقيت السؤال في فيديو الشرح
- (NSInteger)timestampForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)setTimestamp:(NSInteger)seconds forQuestion:(NSInteger)question edition:(NSInteger)edition;
- (BOOL)hasTimestampOverrideForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)shiftTimestampsBy:(NSInteger)delta edition:(NSInteger)edition;
- (void)resetTimestampsForEdition:(NSInteger)edition;

// رسومات القلم (PencilKit)
- (nullable NSData *)drawingDataForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)saveDrawingData:(NSData *)data question:(NSInteger)question edition:(NSInteger)edition;
- (BOOL)hasDrawingForQuestion:(NSInteger)question edition:(NSInteger)edition;
- (void)clearDrawingForQuestion:(NSInteger)question edition:(NSInteger)edition;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
