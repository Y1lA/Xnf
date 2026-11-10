#import <UIKit/UIKit.h>
#import "MFEdition.h"

NS_ASSUME_NONNULL_BEGIN

/// قائمة أرقام الأسئلة ١–٤٨ مع حالة كل سؤال.
@interface MFQuestionListViewController : UIViewController

- (instancetype)initWithEdition:(MFEdition *)edition
                       current:(NSInteger)question
                      onSelect:(void (^)(NSInteger question))onSelect
                      onChange:(void (^)(void))onChange;

@end

NS_ASSUME_NONNULL_END
