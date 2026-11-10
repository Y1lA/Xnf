#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFEdition : NSObject
@property (nonatomic) NSInteger number;
@property (nonatomic, copy) NSString *videoID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSInteger duration;
@property (nonatomic, copy) NSArray<NSNumber *> *timestamps;
@end

/// يقرأ Resources/editions.json من داخل التطبيق
NSArray<MFEdition *> *MFLoadEditions(void);
NSInteger MFQuestionsPerEdition(void);

NS_ASSUME_NONNULL_END
