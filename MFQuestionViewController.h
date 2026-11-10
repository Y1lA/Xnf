#import <UIKit/UIKit.h>
#import "MFEdition.h"

NS_ASSUME_NONNULL_BEGIN

/// شاشة السؤال: صفحة الملف + قلم + زر شرح يوتيوب.
@interface MFQuestionViewController : UIViewController

- (instancetype)initWithEdition:(MFEdition *)edition startQuestion:(NSInteger)question;

@end

NS_ASSUME_NONNULL_END
