#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// يفتح مستندات الجهاز ويستورد ملف الإصدار.
@interface MFPDFPicker : NSObject

+ (void)presentFrom:(UIViewController *)viewController
            edition:(NSInteger)edition
         completion:(void (^)(BOOL imported))completion;

@end

NS_ASSUME_NONNULL_END
