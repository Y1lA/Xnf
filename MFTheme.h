#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIColor *MFBackground(void);
UIColor *MFCard(void);
UIColor *MFAccent(void);
UIColor *MFText(void);
UIColor *MFTextDim(void);
UIColor *MFSuccess(void);
UIColor *MFWarn(void);
UIColor *MFSeparator(void);

UIFont *MFFont(CGFloat size, UIFontWeight weight);

/// يحوّل الأرقام لعربية-هندية (٠١٢٣٤٥٦٧٨٩)
NSString *MFDigits(NSInteger value);
NSString *MFDigitsString(NSString *value);

/// توقيت بالشكل ٤٤:٣٦ أو ١:٠٢:١٠
NSString *MFTimeString(NSInteger seconds);

/// يقرأ "٤٤:٣٦" أو "1:02:10" أو "90" ويرجّع ثواني
NSInteger MFParseTimeString(NSString *text);

/// يضبط مكان ظهور الـ action sheet على الآيباد
void MFConfigurePopover(UIAlertController *sheet, UIView *source);

NS_ASSUME_NONNULL_END
