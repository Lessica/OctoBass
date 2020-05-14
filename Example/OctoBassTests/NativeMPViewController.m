//
//  NativeMPViewController.m
//  OctoBassTests
//

#import "NativeMPViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface NativeMPViewController ()
@property (nonatomic, strong) MPMoviePlayerViewController *movieController;
@property (nonatomic, weak) IBOutlet UILabel *extraHint;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *extraItem;

@end

@implementation NativeMPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        [self.extraHint setHidden:NO];
        [self.extraItem setEnabled:NO];
    }
}

- (IBAction)showInController:(UIBarButtonItem *)sender {
    NSURL *movieURL = [NSURL URLWithString:@"https://www.w3schools.com/html/mov_bbb.mp4"];
    self.movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
    [self presentMoviePlayerViewControllerAnimated:self.movieController];
    [self.movieController.moviePlayer play];
}

@end
