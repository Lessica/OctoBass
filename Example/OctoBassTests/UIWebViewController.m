//
//  UIWebViewController.m
//  OctoBassTests
//

#import "UIWebViewController.h"


@interface UIWebViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *reloadItem;

@end

@implementation UIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURLRequest *req = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:req];
    
    [self.webView becomeFirstResponder];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.reloadItem setEnabled:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.reloadItem setEnabled:YES];
    NSLog(@"- [%@ webViewDidFinishLoad:%p]", NSStringFromClass([self class]), webView);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"- [%@ webView:%p shouldStartLoadWithRequest:%p navigationType:%ld]", NSStringFromClass([self class]), webView, request, navigationType);
    return YES;
}

@end

