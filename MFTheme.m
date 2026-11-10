#import "MFTheme.h"

static UIColor *MFColor(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0];
}

UIColor *MFBackground(void) { return MFColor(244, 246, 248); }
UIColor *MFCard(void) { return [UIColor whiteColor]; }
UIColor *MFAccent(void) { return MFColor(26, 122, 107); }
UIColor *MFText(void) { return MFColor(24, 32, 42); }
UIColor *MFTextDim(void) { return MFColor(107, 118, 132); }
UIColor *MFSuccess(void) { return MFColor(34, 160, 107); }
UIColor *MFWarn(void) { return MFColor(214, 122, 32); }
UIColor *MFSeparator(void) { return MFColor(226, 231, 236); }

UIFont *MFFont(CGFloat size, UIFontWeight weight) {
    UIFont *font = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *desc = [font.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    if (desc) {
        UIFont *rounded = [UIFont fontWithDescriptor:desc size:size];
        if (rounded) {
            return rounded;
        }
    }
    return font;
}

NSString *MFDigits(NSInteger value) { return MFDigitsString([NSString stringWithFormat:@"%ld", (long)value]); }

NSString *MFDigitsString(NSString *value) {
    if (value.length == 0) {
        return @"";
    }
    NSMutableString *out = [NSMutableString stringWithCapacity:value.length];
    for (NSUInteger i = 0; i < value.length; i++) {
        unichar c = [value characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            [out appendFormat:@"%C", (unichar)(0x0660 + (c - '0'))];
        } else {
            [out appendFormat:@"%C", c];
        }
    }
    return out;
}

NSInteger MFParseTimeString(NSString *text) {
    NSMutableString *ascii = [NSMutableString stringWithCapacity:text.length];
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c >= 0x0660 && c <= 0x0669) {
            [ascii appendFormat:@"%C", (unichar)('0' + (c - 0x0660))];
        } else if (c >= 0x06F0 && c <= 0x06F9) {
            [ascii appendFormat:@"%C", (unichar)('0' + (c - 0x06F0))];
        } else {
            [ascii appendFormat:@"%C", c];
        }
    }
    NSInteger total = 0;
    for (NSString *part in [ascii componentsSeparatedByString:@":"]) {
        total = total * 60 + part.integerValue;
    }
    return total;
}

void MFConfigurePopover(UIAlertController *sheet, UIView *source) {
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = source;
        sheet.popoverPresentationController.sourceRect = source.bounds;
    }
}

NSString *MFTimeString(NSInteger seconds) {
    if (seconds < 0) {
        seconds = 0;
    }
    NSInteger h = seconds / 3600;
    NSInteger m = (seconds % 3600) / 60;
    NSInteger s = seconds % 60;
    NSString *plain = h > 0 ? [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)h, (long)m, (long)s]
                            : [NSString stringWithFormat:@"%ld:%02ld", (long)m, (long)s];
    return MFDigitsString(plain);
}
