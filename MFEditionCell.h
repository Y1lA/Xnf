#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFEditionCell : UICollectionViewCell
- (void)configureWithNumber:(NSInteger)number
                     solved:(NSInteger)solved
                      total:(NSInteger)total
                  completed:(BOOL)completed
                     hasPDF:(BOOL)hasPDF;
@end

NS_ASSUME_NONNULL_END
