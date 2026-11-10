#import "MFEditionCell.h"
#import "MFTheme.h"

@interface MFEditionCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIView *barBackground;
@property (nonatomic, strong) UIView *barFill;
@property (nonatomic, strong) UILabel *checkLabel;
@property (nonatomic, strong) UILabel *pdfLabel;
@property (nonatomic) CGFloat progress;
@end

@implementation MFEditionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = MFCard();
        self.contentView.layer.cornerRadius = 16;
        self.contentView.layer.borderWidth = 1;
        self.contentView.layer.borderColor = MFSeparator().CGColor;
        self.contentView.clipsToBounds = YES;

        _numberLabel = [[UILabel alloc] init];
        _numberLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _numberLabel.font = MFFont(30, UIFontWeightBold);
        _numberLabel.textColor = MFText();
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_numberLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = MFFont(12, UIFontWeightSemibold);
        _titleLabel.textColor = MFTextDim();
        _titleLabel.text = @"الإصدار";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_titleLabel];

        _progressLabel = [[UILabel alloc] init];
        _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _progressLabel.font = MFFont(11, UIFontWeightMedium);
        _progressLabel.textColor = MFTextDim();
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_progressLabel];

        _barBackground = [[UIView alloc] init];
        _barBackground.backgroundColor = MFSeparator();
        _barBackground.layer.cornerRadius = 2;
        [self.contentView addSubview:_barBackground];

        _barFill = [[UIView alloc] init];
        _barFill.backgroundColor = MFAccent();
        _barFill.layer.cornerRadius = 2;
        [_barBackground addSubview:_barFill];

        _checkLabel = [[UILabel alloc] init];
        _checkLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _checkLabel.font = MFFont(13, UIFontWeightBold);
        _checkLabel.textColor = [UIColor whiteColor];
        _checkLabel.textAlignment = NSTextAlignmentCenter;
        _checkLabel.backgroundColor = MFSuccess();
        _checkLabel.layer.cornerRadius = 11;
        _checkLabel.clipsToBounds = YES;
        _checkLabel.text = @"✓";
        [self.contentView addSubview:_checkLabel];

        _pdfLabel = [[UILabel alloc] init];
        _pdfLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _pdfLabel.font = MFFont(9, UIFontWeightBold);
        _pdfLabel.textColor = MFAccent();
        _pdfLabel.textAlignment = NSTextAlignmentCenter;
        _pdfLabel.text = @"PDF";
        [self.contentView addSubview:_pdfLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_numberLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_numberLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:18],
            [_titleLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_titleLabel.topAnchor constraintEqualToAnchor:_numberLabel.bottomAnchor constant:-4],
            [_progressLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_progressLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
            [_checkLabel.widthAnchor constraintEqualToConstant:22],
            [_checkLabel.heightAnchor constraintEqualToConstant:22],
            [_checkLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
            [_checkLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
            [_pdfLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
            [_pdfLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-10],
        ]];
    }
    return self;
}

- (void)configureWithNumber:(NSInteger)number
                     solved:(NSInteger)solved
                      total:(NSInteger)total
                  completed:(BOOL)completed
                     hasPDF:(BOOL)hasPDF {
    self.numberLabel.text = MFDigits(number);
    self.progressLabel.text = [NSString stringWithFormat:@"%@ / %@", MFDigits(solved), MFDigits(total)];
    self.progress = total > 0 ? (CGFloat)solved / (CGFloat)total : 0;
    self.checkLabel.hidden = !completed;
    self.pdfLabel.hidden = !hasPDF;
    self.contentView.layer.borderColor = completed ? MFSuccess().CGColor : MFSeparator().CGColor;
    self.contentView.layer.borderWidth = completed ? 2 : 1;
    self.barFill.backgroundColor = completed ? MFSuccess() : MFAccent();
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.contentView.bounds) - 28;
    CGFloat barY = CGRectGetHeight(self.contentView.bounds) - 12;
    self.barBackground.frame = CGRectMake(14, barY, width, 4);
    CGFloat fill = width * MAX(0, MIN(1, self.progress));
    self.barFill.frame = CGRectMake(0, 0, fill, 4);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.numberLabel.text = nil;
    self.progressLabel.text = nil;
    self.checkLabel.hidden = YES;
    self.pdfLabel.hidden = YES;
    self.progress = 0;
}
@end
