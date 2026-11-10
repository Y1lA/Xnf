#import "MFEditionsViewController.h"
#import "MFEditionCell.h"
#import "MFPDFPicker.h"
#import "MFQuestionViewController.h"
#import "MFStore.h"
#import "MFTheme.h"

static NSString *const kEditionCellID = @"MFEditionCell";

@interface MFEditionsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *overallLabel;
@property (nonatomic, strong) UIView *progressTrack;
@property (nonatomic, strong) UIView *progressFill;
@property (nonatomic) CGFloat overallProgress;
@end

@implementation MFEditionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = MFBackground();
    self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;

    [self buildHeader];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12;
    layout.minimumInteritemSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(12, 16, 28, 16);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.backgroundColor = MFBackground();
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    [_collectionView registerClass:[MFEditionCell class] forCellWithReuseIdentifier:kEditionCellID];
    [self.view addSubview:_collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [_collectionView.topAnchor constraintEqualToAnchor:_progressTrack.bottomAnchor constant:12],
        [_collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UILongPressGestureRecognizer *press =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_collectionView addGestureRecognizer:press];
}

- (void)buildHeader {
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.backgroundColor = MFBackground();
    [self.view addSubview:header];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = @"المفكر";
    _titleLabel.font = MFFont(30, UIFontWeightBold);
    _titleLabel.textColor = MFText();
    _titleLabel.textAlignment = NSTextAlignmentRight;
    [header addSubview:_titleLabel];

    _overallLabel = [[UILabel alloc] init];
    _overallLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _overallLabel.font = MFFont(13, UIFontWeightMedium);
    _overallLabel.textColor = MFTextDim();
    _overallLabel.textAlignment = NSTextAlignmentRight;
    [header addSubview:_overallLabel];

    _progressTrack = [[UIView alloc] init];
    _progressTrack.translatesAutoresizingMaskIntoConstraints = NO;
    _progressTrack.backgroundColor = MFSeparator();
    _progressTrack.layer.cornerRadius = 3;
    _progressTrack.clipsToBounds = YES;
    [self.view addSubview:_progressTrack];

    _progressFill = [[UIView alloc] init];
    _progressFill.backgroundColor = MFAccent();
    _progressFill.layer.cornerRadius = 3;
    [_progressTrack addSubview:_progressFill];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [header.heightAnchor constraintEqualToConstant:62],

        [_titleLabel.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-16],

        [_overallLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:-2],
        [_overallLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16],
        [_overallLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-16],

        [_progressTrack.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:2],
        [_progressTrack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_progressTrack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_progressTrack.heightAnchor constraintEqualToConstant:6],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self refreshProgress];
    [self.collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateProgressFill];
}

- (void)refreshProgress {
    MFStore *store = [MFStore shared];
    NSInteger total = store.editionCount * store.questionsPerEdition;
    NSInteger solved = 0;
    for (MFEdition *edition in store.editions) {
        solved += [store solvedCountForEdition:edition.number];
    }
    self.overallProgress = total > 0 ? (CGFloat)solved / (CGFloat)total : 0;
    self.overallLabel.text = [NSString stringWithFormat:@"أنجزت %@ من %@ سؤال · %@ إصدار",
                                                        MFDigits(solved), MFDigits(total),
                                                        MFDigits(store.editionCount)];
    [self updateProgressFill];
}

- (void)updateProgressFill {
    CGFloat width = CGRectGetWidth(self.progressTrack.bounds);
    self.progressFill.frame = CGRectMake(0, 0, width * MAX(0, MIN(1, self.overallProgress)), CGRectGetHeight(self.progressTrack.bounds));
}

#pragma mark - Collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [MFStore shared].editionCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MFEditionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kEditionCellID
                                                                  forIndexPath:indexPath];
    MFStore *store = [MFStore shared];
    NSInteger number = indexPath.item + 1;
    [cell configureWithNumber:number
                       solved:[store solvedCountForEdition:number]
                        total:store.questionsPerEdition
                    completed:[store isCompletedEdition:number]
                       hasPDF:[store hasPDFForEdition:number]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    NSInteger columns = 3;
    if (width > 900) {
        columns = 7;
    } else if (width > 700) {
        columns = 5;
    } else if (width > 500) {
        columns = 4;
    }
    CGFloat spacing = 12;
    CGFloat horizontalInsets = 32;
    CGFloat item = floor((width - horizontalInsets - spacing * (CGFloat)(columns - 1)) / (CGFloat)columns);
    return CGSizeMake(item, item * 1.02);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self openEdition:indexPath.item + 1];
}

- (void)openEdition:(NSInteger)number {
    MFStore *store = [MFStore shared];
    MFEdition *edition = [store editionWithNumber:number];
    if (!edition) {
        return;
    }
    MFQuestionViewController *controller =
        [[MFQuestionViewController alloc] initWithEdition:edition
                                            startQuestion:[store lastQuestionForEdition:number]];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Long press

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
    [self presentEditionOptionsForNumber:indexPath.item + 1 sourceView:source];
}

- (void)presentEditionOptionsForNumber:(NSInteger)number sourceView:(UIView *)sourceView {
    MFStore *store = [MFStore shared];
    NSString *title = [NSString stringWithFormat:@"الإصدار %@", MFDigits(number)];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"فتح الإصدار"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self openEdition:number];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"استيراد ملف الإصدار (PDF)"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [MFPDFPicker presentFrom:self edition:number completion:^(BOOL imported) {
            [self.collectionView reloadData];
            if (imported) {
                [self openEdition:number];
            }
        }];
    }]];
    if ([store hasPDFForEdition:number]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"إزالة ملف الإصدار"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            [store removePDFForEdition:number];
            [self.collectionView reloadData];
        }]];
    }
    BOOL completed = [store isCompletedEdition:number];
    [sheet addAction:[UIAlertAction actionWithTitle:(completed ? @"إلغاء علامة الإنجاز" : @"تعليم الإصدار كمنجز")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [store setCompleted:!completed edition:number];
        [self.collectionView reloadData];
        [self refreshProgress];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"تصفير تقدّم الإصدار"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [store resetProgressForEdition:number];
        [self.collectionView reloadData];
        [self refreshProgress];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    MFConfigurePopover(sheet, sourceView);
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
