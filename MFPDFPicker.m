#import "MFPDFPicker.h"
#import "MFStore.h"

@interface MFPDFPicker () <UIDocumentPickerDelegate>
@property (nonatomic) NSInteger edition;
@property (nonatomic, copy) void (^completion)(BOOL imported);
@end

static NSMutableSet<MFPDFPicker *> *gActivePickers = nil;

@implementation MFPDFPicker

+ (void)presentFrom:(UIViewController *)viewController
            edition:(NSInteger)edition
         completion:(void (^)(BOOL))completion {
    MFPDFPicker *picker = [[MFPDFPicker alloc] init];
    picker.edition = edition;
    picker.completion = completion;
    if (!gActivePickers) {
        gActivePickers = [NSMutableSet set];
    }
    [gActivePickers addObject:picker];

    UIDocumentPickerViewController *controller =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ @"com.adobe.pdf" ]
                                                              inMode:UIDocumentPickerModeImport];
    controller.delegate = picker;
    controller.allowsMultipleSelection = NO;
    [viewController presentViewController:controller animated:YES completion:nil];
}

- (void)finish:(BOOL)imported {
    void (^completion)(BOOL) = self.completion;
    self.completion = nil;
    [gActivePickers removeObject:self];
    if (completion) {
        completion(imported);
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    BOOL ok = NO;
    if (url) {
        NSError *error = nil;
        ok = [[MFStore shared] importPDFFromURL:url edition:self.edition error:&error];
    }
    [controller dismissViewControllerAnimated:YES completion:^{
        [self finish:ok];
    }];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self finish:NO];
    }];
}

@end
