//
//  UIWebViewController.m
//  OctoBassTests
//

#import "UIWebViewController.h"


@interface UIWebViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation UIWebViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://thepaciellogroup.github.io/AT-browser-tests/test-files/video.html"]];
    [self.webView loadRequest:req];
    
    [self.webView becomeFirstResponder];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"- [%@ webViewDidFinishLoad:%p]", NSStringFromClass([self class]), webView);
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"- [%@ webView:%p shouldStartLoadWithRequest:%p navigationType:%ld]", NSStringFromClass([self class]), webView, request, navigationType);
    return YES;
}


@end

