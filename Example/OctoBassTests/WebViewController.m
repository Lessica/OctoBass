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
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://tuna.moe/"]];
    [self.webView loadRequest:req];
}

@end
