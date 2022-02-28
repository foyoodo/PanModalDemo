//
//  ViewController.m
//  PanModelDemo
//
//  Created by foyoodo on 2022/2/27.
//

#import "ViewController.h"
#import "PanModalViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) PanModalViewController *panModalVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor darkGrayColor];

    [self.view addSubview:self.button];
}

- (UIButton *)button {
    if (!_button) {
        _button = [[UIButton alloc] initWithFrame:CGRectMake(140, 100, 140, 50)];
        _button.backgroundColor = [UIColor systemBlueColor];
        _button.layer.cornerRadius = 25;
        [_button setTitle:@"Present Modal" forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(didClickButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

- (void)didClickButton {
    [self presentViewController:self.panModalVC animated:NO completion:nil];
}

- (PanModalViewController *)panModalVC {
    if (!_panModalVC) {
        _panModalVC = [[PanModalViewController alloc] init];
        _panModalVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return _panModalVC;
}

@end
