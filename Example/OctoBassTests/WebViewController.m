//
//  WebViewController.m
//  OctoBassTests
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController () <WKNavigationDelegate>
@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *reloadItem;
@property (nonatomic, assign) NSUInteger loadCount;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup navigation delegate.
    self.webView.navigationDelegate = self;
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://thepaciellogroup.github.io/AT-browser-tests/test-files/video.html"]];
    [self.webView loadRequest:req];
    
    [self.webView becomeFirstResponder];
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.loadCount++;
    [self.reloadItem setEnabled:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.loadCount--;
    if (self.loadCount == 0) {
        [self.reloadItem setEnabled:YES];
    }
}

@end
