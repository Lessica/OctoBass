//
//  WebViewController.m
//  OctoBassTests
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController ()
@property (nonatomic, weak) IBOutlet WKWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://thepaciellogroup.github.io/AT-browser-tests/test-files/video.html"]];
    [self.webView loadRequest:req];
    
    [self.webView becomeFirstResponder];
}

@end
