//
//  UIWebViewController.m
//  OctoBassTests
//

#import "UIWebViewController.h"

@interface UIWebViewController ()
@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation UIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://tuna.moe/"]];
    [self.webView loadRequest:req];
}

@end
