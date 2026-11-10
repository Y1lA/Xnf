#import "MFQuestionViewController.h"
#import "MFPDFPicker.h"
#import "MFQuestionListViewController.h"
#import "MFStore.h"
#import "MFTheme.h"
#import <PencilKit/PencilKit.h>
#import <math.h>

@interface MFQuestionViewController () <UIScrollViewDelegate, PKCanvasViewDelegate>
@property (nonatomic, strong) MFEdition *edition;
@property (nonatomic) NSInteger question;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *pageContainer;
@property (nonatomic, strong) UIImageView *pageView;
@property (nonatomic, strong) PKCanvasView *canvasView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) UIButton *penButton;
@property (nonatomic, strong) UIButton *solvedButton;
@property (nonatomic, strong) UIButton *previousButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIView *bottomPanel;

@property (nonatomic, strong) PKToolPicker *toolPicker;
@property (nonatomic) BOOL toolPickerAttached;

@property (nonatomic) CGSize pageSize;
@property (nonatomic) CGSize laidOutSize;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) CGPDFDocumentRef document;
@property (nonatomic) NSInteger pageCount;

@property (nonatomic) BOOL penEnabled;
@property (nonatomic) BOOL loadingDrawing;
@property (nonatomic) NSInteger saveToken;
@end

@implementation MFQuestionViewController

- (instancetype)initWithEdition:(MFEdition *)edition startQuestion:(NSInteger)question {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _edition = edition;
        _question = MAX(1, question);
        _penEnabled = YES;
        _currentPage = -1;
    }
    return self;
}

- (void)dealloc {
    if (_document) {
        CGPDFDocumentRelease(_document);
        _document = NULL;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = MFBackground();
    self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;

    [self buildHeader];
    [self buildBottomPanel];
    [self buildScrollView];
    [self openDocument];
    [self showQuestion:self.question];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self updateLabels];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateToolPicker];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self persistCurrentDrawing];
    [[MFStore shared] setLastQuestion:self.question edition:self.edition.number];
    [[MFStore shared] flush];
}

#pragma mark - البناء

- (void)buildHeader {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = MFFont(16, UIFontWeightBold);
    _titleLabel.textColor = MFText();
    _titleLabel.textAlignment = NSTextAlignmentCenter;

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = MFFont(11, UIFontWeightMedium);
    _subtitleLabel.textColor = MFTextDim();
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ _titleLabel, _subtitleLabel ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 0;
    self.navigationItem.titleView = stack;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"إعدادات"
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(showOptions:)];
    self.navigationItem.rightBarButtonItem.tintColor = MFAccent();
}

- (UIButton *)toolButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = MFFont(14, UIFontWeightSemibold);
    [button setTitleColor:MFText() forState:UIControlStateNormal];
    button.backgroundColor = MFBackground();
    button.layer.cornerRadius = 10;
    [button.heightAnchor constraintEqualToConstant:42].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildBottomPanel {
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = MFCard();
    [self.view addSubview:panel];

    UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = MFSeparator();
    [panel addSubview:line];

    _previousButton = [self toolButtonWithTitle:@"‹ السابق" action:@selector(goPrevious)];
    _nextButton = [self toolButtonWithTitle:@"التالي ›" action:@selector(goNext)];
    _counterLabel = [[UILabel alloc] init];
    _counterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _counterLabel.font = MFFont(15, UIFontWeightBold);
    _counterLabel.textColor = MFText();
    _counterLabel.textAlignment = NSTextAlignmentCenter;

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ _previousButton, _counterLabel, _nextButton ]];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentCenter;
    row.distribution = UIStackViewDistributionFill;
    [panel addSubview:row];
    [_previousButton.widthAnchor constraintEqualToConstant:86].active = YES;
    [_nextButton.widthAnchor constraintEqualToConstant:86].active = YES;

    _penButton = [self toolButtonWithTitle:@"قلم" action:@selector(togglePen)];
    UIButton *undo = [self toolButtonWithTitle:@"تراجع" action:@selector(undoDrawing)];
    _solvedButton = [self toolButtonWithTitle:@"تم" action:@selector(toggleSolved)];
    UIButton *help = [self toolButtonWithTitle:@"▶ الشرح" action:@selector(openExplanation)];
    help.backgroundColor = MFAccent();
    [help setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    UIStackView *tools = [[UIStackView alloc] initWithArrangedSubviews:@[ _penButton, undo, _solvedButton, help ]];
    tools.translatesAutoresizingMaskIntoConstraints = NO;
    tools.axis = UILayoutConstraintAxisHorizontal;
    tools.spacing = 8;
    tools.distribution = UIStackViewDistributionFillEqually;
    [panel addSubview:tools];

    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [line.topAnchor constraintEqualToAnchor:panel.topAnchor],
        [line.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [line.heightAnchor constraintEqualToConstant:1],

        [row.topAnchor constraintEqualToAnchor:panel.topAnchor constant:10],
        [row.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [row.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],

        [tools.topAnchor constraintEqualToAnchor:row.bottomAnchor constant:10],
        [tools.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [tools.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [tools.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
    ]];
    self.bottomPanel = panel;
}

- (void)buildScrollView {
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.delegate = self;
    _scrollView.backgroundColor = MFBackground();
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.bouncesZoom = YES;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.view addSubview:_scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomPanel.topAnchor],
    ]];

    _pageContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _pageContainer.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:_pageContainer];

    _pageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _pageView.backgroundColor = [UIColor whiteColor];
    _pageView.contentMode = UIViewContentModeScaleToFill;
    [_pageContainer addSubview:_pageView];

    _canvasView = [[PKCanvasView alloc] initWithFrame:CGRectZero];
    _canvasView.backgroundColor = [UIColor clearColor];
    _canvasView.opaque = NO;
    _canvasView.delegate = self;
    _canvasView.scrollEnabled = NO;
    _canvasView.alwaysBounceVertical = NO;
    _canvasView.drawingPolicy = PKCanvasViewDrawingPolicyAnyInput;
    [_pageContainer addSubview:_canvasView];
}

#pragma mark - الملف

- (void)openDocument {
    if (self.document) {
        CGPDFDocumentRelease(self.document);
        self.document = NULL;
    }
    NSString *path = [[MFStore shared] pdfPathForEdition:self.edition.number];
    self.pageCount = 0;
    if (!path) {
        return;
    }
    CGPDFDocumentRef document =
        CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]);
    if (!document) {
        return;
    }
    self.document = document;
    self.pageCount = (NSInteger)CGPDFDocumentGetNumberOfPages(document);
}

- (UIImage *)imageForPage:(NSInteger)pageNumber {
    if (!self.document || pageNumber < 1 || pageNumber > self.pageCount) {
        return nil;
    }
    CGPDFPageRef page = CGPDFDocumentGetPage(self.document, (size_t)pageNumber);
    if (!page) {
        return nil;
    }
    CGRect box = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    if (box.size.width <= 0 || box.size.height <= 0) {
        return nil;
    }
    CGFloat scale = 2.0;
    CGSize pixelSize = CGSizeMake(box.size.width * scale, box.size.height * scale);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1.0;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:pixelSize format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGContextRef ctx = context.CGContext;
        CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextFillRect(ctx, CGRectMake(0, 0, pixelSize.width, pixelSize.height));
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, 0, pixelSize.height);
        CGContextScaleCTM(ctx, scale, -scale);
        CGAffineTransform transform =
            CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, box, 0, true);
        CGContextConcatCTM(ctx, transform);
        CGContextDrawPDFPage(ctx, page);
        CGContextRestoreGState(ctx);
    }];
}

#pragma mark - عرض السؤال

- (void)showQuestion:(NSInteger)question {
    NSInteger total = [MFStore shared].questionsPerEdition;
    if (question < 1) {
        question = 1;
    }
    if (question > total) {
        question = total;
    }
    if (question != self.question) {
        [self persistCurrentDrawing];
    }
    self.question = question;
    [[MFStore shared] setLastQuestion:question edition:self.edition.number];
    [self updateLabels];
    [self refreshPage];
    [self loadDrawing];
}

- (void)updateLabels {
    MFStore *store = [MFStore shared];
    NSInteger total = store.questionsPerEdition;
    NSInteger stamp = [store timestampForQuestion:self.question edition:self.edition.number];
    self.titleLabel.text = [NSString stringWithFormat:@"الإصدار %@", MFDigits(self.edition.number)];
    self.subtitleLabel.text = [NSString stringWithFormat:@"السؤال %@ من %@ · الشرح %@",
                                                         MFDigits(self.question), MFDigits(total),
                                                         MFTimeString(stamp)];
    self.counterLabel.text = [NSString stringWithFormat:@"%@ / %@", MFDigits(self.question), MFDigits(total)];
    self.previousButton.enabled = self.question > 1;
    self.nextButton.enabled = self.question < total;
    self.previousButton.alpha = self.previousButton.enabled ? 1.0 : 0.35;
    self.nextButton.alpha = self.nextButton.enabled ? 1.0 : 0.35;

    BOOL solved = [store isSolved:self.question edition:self.edition.number];
    [self.solvedButton setTitle:(solved ? @"✓ محلول" : @"تم") forState:UIControlStateNormal];
    self.solvedButton.backgroundColor = solved ? MFSuccess() : MFBackground();
    [self.solvedButton setTitleColor:(solved ? [UIColor whiteColor] : MFText()) forState:UIControlStateNormal];
}

- (void)refreshPage {
    if (!self.document) {
        [self showEmptyState:YES];
        return;
    }
    [self showEmptyState:NO];
    NSInteger page = [[MFStore shared] pageForQuestion:self.question edition:self.edition.number];
    if (page < 1) {
        page = 1;
    }
    if (page > self.pageCount) {
        page = self.pageCount;
    }
    if (page == self.currentPage && self.pageView.image) {
        return;
    }
    UIImage *image = [self imageForPage:page];
    if (!image) {
        return;
    }
    self.currentPage = page;
    self.pageView.image = image;
    self.pageSize = image.size;
    [self layoutPageResetZoom:YES];
}

- (void)showEmptyState:(BOOL)show {
    if (show) {
        if (!self.emptyView) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.backgroundColor = MFCard();
            view.layer.cornerRadius = 16;
            [self.view insertSubview:view aboveSubview:self.scrollView];

            UILabel *title = [[UILabel alloc] init];
            title.translatesAutoresizingMaskIntoConstraints = NO;
            title.text = @"ما في ملف لهذا الإصدار";
            title.font = MFFont(18, UIFontWeightBold);
            title.textColor = MFText();
            title.textAlignment = NSTextAlignmentCenter;
            [view addSubview:title];

            UILabel *hint = [[UILabel alloc] init];
            hint.translatesAutoresizingMaskIntoConstraints = NO;
            hint.text = @"أضف ملف الإصدار (PDF) من جهازك، ونعرض لك صفحة كل سؤال ونكتب بالقلم فوقها.";
            hint.font = MFFont(13, UIFontWeightRegular);
            hint.textColor = MFTextDim();
            hint.numberOfLines = 0;
            hint.textAlignment = NSTextAlignmentCenter;
            [view addSubview:hint];

            UIButton *add = [self toolButtonWithTitle:@"أضف ملف الإصدار" action:@selector(importPDF)];
            add.backgroundColor = MFAccent();
            [add setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [view addSubview:add];

            [NSLayoutConstraint activateConstraints:@[
                [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
                [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
                [view.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

                [title.topAnchor constraintEqualToAnchor:view.topAnchor constant:24],
                [title.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
                [title.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-16],

                [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
                [hint.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
                [hint.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-16],

                [add.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:16],
                [add.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:24],
                [add.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-24],
                [add.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-24],
            ]];
            self.emptyView = view;
        }
        self.emptyView.hidden = NO;
        self.scrollView.hidden = YES;
    } else {
        self.emptyView.hidden = YES;
        self.scrollView.hidden = NO;
    }
}

- (void)layoutPageResetZoom:(BOOL)reset {
    CGSize size = self.pageSize;
    if (size.width <= 1 || size.height <= 1) {
        return;
    }
    if (!CGSizeEqualToSize(self.laidOutSize, size)) {
        self.pageContainer.frame = CGRectMake(0, 0, size.width, size.height);
        self.pageView.frame = self.pageContainer.bounds;
        self.canvasView.frame = self.pageContainer.bounds;
        self.laidOutSize = size;
    }
    CGSize viewport = self.scrollView.bounds.size;
    if (viewport.width <= 1 || viewport.height <= 1) {
        return;
    }
    CGFloat fit = MIN(viewport.width / size.width, viewport.height / size.height);
    self.scrollView.contentSize = size;
    self.scrollView.minimumZoomScale = fit * 0.8;
    self.scrollView.maximumZoomScale = fit * 6.0;
    if (reset || self.scrollView.zoomScale <= 0.01) {
        [self.scrollView setZoomScale:fit animated:NO];
    } else {
        CGFloat current = self.scrollView.zoomScale;
        if (current < self.scrollView.minimumZoomScale) {
            [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
        } else if (current > self.scrollView.maximumZoomScale) {
            [self.scrollView setZoomScale:self.scrollView.maximumZoomScale animated:NO];
        }
    }
    [self centerPage];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPageResetZoom:NO];
}

- (void)centerPage {
    CGFloat pageWidth = CGRectGetWidth(self.pageContainer.frame);
    CGFloat pageHeight = CGRectGetHeight(self.pageContainer.frame);
    CGFloat viewWidth = self.scrollView.bounds.size.width;
    CGFloat viewHeight = self.scrollView.bounds.size.height;
    CGFloat insetX = MAX(0, (viewWidth - pageWidth) / 2.0);
    CGFloat insetY = MAX(0, (viewHeight - pageHeight) / 2.0);
    self.scrollView.contentInset = UIEdgeInsetsMake(insetY, insetX, insetY, insetX);
}

#pragma mark - القلم

- (void)loadDrawing {
    self.loadingDrawing = YES;
    NSData *data = [[MFStore shared] drawingDataForQuestion:self.question edition:self.edition.number];
    PKDrawing *drawing = nil;
    if (data.length > 0) {
        NSError *error = nil;
        drawing = [[PKDrawing alloc] initWithData:data error:&error];
    }
    self.canvasView.drawing = drawing ?: [[PKDrawing alloc] init];
    self.canvasView.userInteractionEnabled = self.penEnabled;
    self.loadingDrawing = NO;
}

- (void)persistCurrentDrawing {
    if (self.loadingDrawing) {
        return;
    }
    NSData *data = self.canvasView.drawing.dataRepresentation;
    [[MFStore shared] saveDrawingData:data question:self.question edition:self.edition.number];
}

- (void)canvasViewDrawingDidChange:(PKCanvasView *)canvasView {
    if (self.loadingDrawing) {
        return;
    }
    self.saveToken += 1;
    NSInteger token = self.saveToken;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.saveToken != token) {
            return;
        }
        [strongSelf persistCurrentDrawing];
    });
}

- (void)togglePen {
    self.penEnabled = !self.penEnabled;
    self.canvasView.userInteractionEnabled = self.penEnabled;
    [self updateToolPicker];
    [self updatePenButton];
}

- (void)updatePenButton {
    [self.penButton setTitle:(self.penEnabled ? @"قلم ✍︎" : @"تحريك ✋") forState:UIControlStateNormal];
    self.penButton.backgroundColor = self.penEnabled ? MFAccent() : MFBackground();
    [self.penButton setTitleColor:(self.penEnabled ? [UIColor whiteColor] : MFText())
                         forState:UIControlStateNormal];
}

- (void)updateToolPicker {
    if (!self.penEnabled) {
        if (self.toolPicker) {
            [self.toolPicker setVisible:NO forFirstResponder:self.canvasView];
        }
        [self.canvasView resignFirstResponder];
        [self updatePenButton];
        return;
    }
    if (!self.toolPicker && self.view.window) {
        self.toolPicker = [PKToolPicker sharedToolPickerForWindow:self.view.window];
    }
    if (self.toolPicker && !self.toolPickerAttached) {
        [self.toolPicker addObserver:self.canvasView];
        self.toolPickerAttached = YES;
    }
    [self.canvasView becomeFirstResponder];
    if (self.toolPicker) {
        [self.toolPicker setVisible:YES forFirstResponder:self.canvasView];
    }
    [self updatePenButton];
}

- (void)undoDrawing {
    [self.canvasView.undoManager undo];
    [self performSelector:@selector(persistCurrentDrawing) withObject:nil afterDelay:0.3];
}

#pragma mark - التنقل

- (void)goPrevious {
    [self showQuestion:self.question - 1];
}

- (void)goNext {
    [self showQuestion:self.question + 1];
}

- (void)toggleSolved {
    MFStore *store = [MFStore shared];
    BOOL solved = [store isSolved:self.question edition:self.edition.number];
    [store setSolved:!solved question:self.question edition:self.edition.number];
    [self updateLabels];
}

- (void)openExplanation {
    [self persistCurrentDrawing];
    NSInteger stamp = [[MFStore shared] timestampForQuestion:self.question edition:self.edition.number];
    NSString *urlString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@&t=%lds",
                                                     self.edition.videoID, (long)stamp];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)presentQuestionList {
    __weak typeof(self) weakSelf = self;
    MFQuestionListViewController *list =
        [[MFQuestionListViewController alloc] initWithEdition:self.edition
                                                      current:self.question
                                                     onSelect:^(NSInteger question) {
        [weakSelf showQuestion:question];
    }
                                                     onChange:^{
        [weakSelf updateLabels];
        [weakSelf refreshPage];
        [weakSelf loadDrawing];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        sheet.detents = @[ [UISheetPresentationControllerDetent mediumDetent],
                           [UISheetPresentationControllerDetent largeDetent] ];
        sheet.prefersGrabberVisible = YES;
    }
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - الإعدادات

- (void)importPDF {
    __weak typeof(self) weakSelf = self;
    [MFPDFPicker presentFrom:self edition:self.edition.number completion:^(BOOL imported) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !imported) {
            return;
        }
        [strongSelf openDocument];
        strongSelf.currentPage = -1;
        [strongSelf refreshPage];
        [strongSelf loadDrawing];
    }];
}

- (void)showOptions:(id)sender {
    MFStore *store = [MFStore shared];
    NSInteger edition = self.edition.number;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"قائمة الأسئلة" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentQuestionList];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:([store hasPDFForEdition:edition] ? @"استبدال ملف الإصدار"
                                                                                     : @"استيراد ملف الإصدار (PDF)")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self importPDF];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"عدد الأسئلة في الصفحة: %@",
                                                       MFDigits([store questionsPerPageForEdition:edition])]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self promptTitle:@"عدد الأسئلة في كل صفحة"
                  message:@"مثلاً ٢ يعني كل صفحة فيها سؤالين"
                    value:[NSString stringWithFormat:@"%ld", (long)[store questionsPerPageForEdition:edition]]
                  handler:^(NSString *text) {
            [store setQuestionsPerPage:text.integerValue edition:edition];
            [self reloadPages];
        }];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"أول صفحة فيها الأسئلة: %@",
                                                       MFDigits([store firstPageForEdition:edition])]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self promptTitle:@"أول صفحة فيها الأسئلة"
                  message:@"رقم الصفحة اللي يبدأ فيها السؤال الأول"
                    value:[NSString stringWithFormat:@"%ld", (long)[store firstPageForEdition:edition]]
                  handler:^(NSString *text) {
            [store setFirstPage:text.integerValue edition:edition];
            [self reloadPages];
        }];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"إزاحة كل التوقيتات (ثواني)"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self promptTitle:@"إزاحة التوقيتات"
                  message:@"اكتب مثلاً 30 أو -30 بالثواني"
                    value:@"30"
                  handler:^(NSString *text) {
            [store shiftTimestampsBy:text.integerValue edition:edition];
            [self updateLabels];
        }];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"إعادة التوقيتات التقديرية"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [store resetTimestampsForEdition:edition];
        [self updateLabels];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"مسح رسم هذا السؤال"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [store clearDrawingForQuestion:self.question edition:edition];
        [self loadDrawing];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    MFConfigurePopover(sheet, self.view);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)reloadPages {
    [self persistCurrentDrawing];
    self.currentPage = -1;
    [self refreshPage];
    [self loadDrawing];
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

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.pageContainer;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerPage];
}

@end
