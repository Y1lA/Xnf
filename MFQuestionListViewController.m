#import "MFQuestionListViewController.h"
#import "MFStore.h"
#import "MFTheme.h"

@interface MFQuestionCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIView *dot;
@end

@implementation MFQuestionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 10;
        self.contentView.layer.borderWidth = 1;
        self.contentView.layer.borderColor = MFSeparator().CGColor;
        self.contentView.backgroundColor = MFCard();

        _numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _numberLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _numberLabel.font = MFFont(15, UIFontWeightSemibold);
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.textColor = MFText();
        [self.contentView addSubview:_numberLabel];

        _dot = [[UIView alloc] initWithFrame:CGRectZero];
        _dot.translatesAutoresizingMaskIntoConstraints = NO;
        _dot.backgroundColor = MFAccent();
        _dot.layer.cornerRadius = 3;
        [self.contentView addSubview:_dot];

        [NSLayoutConstraint activateConstraints:@[
            [_numberLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_numberLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_dot.widthAnchor constraintEqualToConstant:6],
            [_dot.heightAnchor constraintEqualToConstant:6],
            [_dot.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_dot.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
        ]];
    }
    return self;
}

- (void)configureNumber:(NSInteger)number
                 solved:(BOOL)solved
               hasSketch:(BOOL)hasSketch
                isCurrent:(BOOL)isCurrent {
    self.numberLabel.text = MFDigits(number);
    self.dot.hidden = !hasSketch;
    self.contentView.backgroundColor = solved ? MFSuccess() : MFCard();
    self.numberLabel.textColor = solved ? [UIColor whiteColor] : MFText();
    self.contentView.layer.borderWidth = isCurrent ? 2 : 1;
    self.contentView.layer.borderColor = isCurrent ? MFAccent().CGColor : MFSeparator().CGColor;
}

@end

@interface MFQuestionListViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) MFEdition *edition;
@property (nonatomic) NSInteger question;
@property (nonatomic, copy) void (^onSelect)(NSInteger);
@property (nonatomic, copy) void (^onChange)(void);
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation MFQuestionListViewController

- (instancetype)initWithEdition:(MFEdition *)edition
                       current:(NSInteger)question
                      onSelect:(void (^)(NSInteger))onSelect
                      onChange:(void (^)(void))onChange {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _edition = edition;
        _question = question;
        _onSelect = [onSelect copy];
        _onChange = [onChange copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = MFBackground();
    self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;

    self.title = [NSString stringWithFormat:@"أسئلة الإصدار %@", MFDigits(self.edition.number)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"تم" style:UIBarButtonItemStyleDone target:self action:@selector(close)];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 8;
    layout.minimumInteritemSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(12, 16, 24, 16);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.backgroundColor = MFBackground();
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    [_collectionView registerClass:[MFQuestionCell class] forCellWithReuseIdentifier:@"q"];
    [self.view addSubview:_collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [_collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UILongPressGestureRecognizer *press =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_collectionView addGestureRecognizer:press];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [MFStore shared].questionsPerEdition;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MFQuestionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"q" forIndexPath:indexPath];
    MFStore *store = [MFStore shared];
    NSInteger number = indexPath.item + 1;
    [cell configureNumber:number
                   solved:[store isSolved:number edition:self.edition.number]
                 hasSketch:[store hasDrawingForQuestion:number edition:self.edition.number]
                  isCurrent:(number == self.question)];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds) - 32 - 4 * 8;
    return CGSizeMake(floor(width / 5.0), 52);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger number = indexPath.item + 1;
    self.question = number;
    [collectionView reloadData];
    if (self.onSelect) {
        self.onSelect(number);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (!indexPath) {
        return;
    }
    UIView *source = [self.collectionView cellForItemAtIndexPath:indexPath] ?: self.collectionView;
    [self presentOptionsForQuestion:indexPath.item + 1 sourceView:source];
}

- (void)presentOptionsForQuestion:(NSInteger)number sourceView:(UIView *)sourceView {
    MFStore *store = [MFStore shared];
    NSInteger edition = self.edition.number;
    NSString *title = [NSString stringWithFormat:@"السؤال %@", MFDigits(number)];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    BOOL solved = [store isSolved:number edition:edition];
    [sheet addAction:[UIAlertAction actionWithTitle:(solved ? @"إلغاء علامة الحل" : @"تعليم كمحلول")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [store setSolved:!solved question:number edition:edition];
        [self reloadAndNotify];
    }]];

    NSInteger stamp = [store timestampForQuestion:number edition:edition];
    [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"تعديل توقيت الشرح (%@)", MFTimeString(stamp)]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self promptTitle:@"توقيت السؤال في الفيديو"
                  message:@"اكتب التوقيت مثل ١٢:٣٤"
                    value:MFTimeString(stamp)
                  handler:^(NSString *text) {
            [store setTimestamp:MFParseTimeString(text) forQuestion:number edition:edition];
            [self reloadAndNotify];
        }];
    }]];

    if ([store hasTimestampOverrideForQuestion:number edition:edition]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"رجّع التوقيت التقديري"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            NSInteger index = number - 1;
            NSInteger estimated = (index >= 0 && index < (NSInteger)self.edition.timestamps.count)
                                      ? self.edition.timestamps[(NSUInteger)index].integerValue
                                      : 0;
            [store setTimestamp:estimated forQuestion:number edition:edition];
            [self reloadAndNotify];
        }]];
    }

    NSInteger page = [store pageForQuestion:number edition:edition];
    [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"تعيين صفحة السؤال (حالياً %@)", MFDigits(page)]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self promptTitle:@"صفحة السؤال داخل الملف"
                  message:@"رقم الصفحة"
                    value:[NSString stringWithFormat:@"%ld", (long)page]
                  handler:^(NSString *text) {
            [store setPage:text.integerValue forQuestion:number edition:edition];
            [self reloadAndNotify];
        }];
    }]];

    if ([store hasDrawingForQuestion:number edition:edition]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"مسح رسم هذا السؤال"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            [store clearDrawingForQuestion:number edition:edition];
            [self reloadAndNotify];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    MFConfigurePopover(sheet, sourceView);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)promptTitle:(NSString *)title
            message:(NSString *)message
              value:(NSString *)value
            handler:(void (^)(NSString *text))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = value;
        textField.textAlignment = NSTextAlignmentCenter;
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"تم" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        handler(textField.text ?: @"");
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadAndNotify {
    [self.collectionView reloadData];
    if (self.onChange) {
        self.onChange();
    }
}

@end
