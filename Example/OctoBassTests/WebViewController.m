//
//  WebViewController.m
//  OctoBassTests
//
//  Created by Darwin on 5/11/20.
//  Copyright © 2020 i_82. All rights reserved.
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
