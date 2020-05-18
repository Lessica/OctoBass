//
//  ViewController.m
//  OctoBassTests
//

#import "ViewController.h"
#import "WebViewController.h"
#import "UIWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.clearsSelectionOnViewWillAppear = YES;
}

- (IBAction)myUnwindAction:(UIStoryboardSegue *)unwindSegue {
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WebViewController class]] ||
        [segue.destinationViewController isKindOfClass:[UIWebViewController class]]
        )
    {
        NSURL *url = nil;
        if ([segue.identifier isEqualToString:@"video"]) {
            url = [NSURL URLWithString:@"https://thepaciellogroup.github.io/AT-browser-tests/test-files/video.html"];
        }
        else if ([segue.identifier isEqualToString:@"iframe"]) {
            url = [NSURL URLWithString:@"https://assets-iframe.ggwebcast.com/JLRGeneva2018/01/example/"];
        }
        else if ([segue.identifier isEqualToString:@"no-iframe"]) {
            url = [NSURL URLWithString:@"https://www.html5tutorial.info/html5-audio.php"];
        }
        if (url) {
            if ([segue.destinationViewController isKindOfClass:[WebViewController class]]) {
                ((WebViewController *)segue.destinationViewController).url = url;
            }
            else if ([segue.destinationViewController isKindOfClass:[UIWebViewController class]]) {
                ((UIWebViewController *)segue.destinationViewController).url = url;
            }
        }
    }
}

@end
