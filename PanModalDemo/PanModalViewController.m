//
//  PanModalViewController.m
//  PanModelDemo
//
//  Created by foyoodo on 2022/2/27.
//
//  Reference: https://github.com/HeathWang/HWPanModal

#import "PanModalViewController.h"
#import "Masonry/Masonry.h"

static const NSTimeInterval kAnimationDuration = 0.15;

@interface PanModalViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) MASConstraint *containerViewVerticalConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, assign) CGPoint scrollViewContentOffset;

@property (nonatomic, assign) BOOL containerViewAnchored;

@end

@implementation PanModalViewController

#pragma mark - Life Cycle

- (void)dealloc {
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

- (instancetype)init {
    if (self = [super init]) {
        self.containerViewAnchored = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addGestureRecognizer:self.tapGestureRecognizer];

    [self.view addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.containerViewVerticalConstraint = make.top.equalTo(self.view.mas_bottom);
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.6);
    }];

    [self.containerView addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(20);
        make.left.right.bottom.equalTo(self.containerView);
    }];

    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        [self.containerViewVerticalConstraint uninstall];
        self.containerViewVerticalConstraint = make.bottom.equalTo(self.view);
    }];

    [UIView animateWithDuration:kAnimationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"id"];
    }
    cell.textLabel.text = self.array[indexPath.row];
    return cell;
}

#pragma mark - Private Methods

- (void)dismissAction {
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        [self.containerViewVerticalConstraint uninstall];
        self.containerViewVerticalConstraint = make.top.equalTo(self.view.mas_bottom);
    }];

    [UIView animateWithDuration:kAnimationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
                [self.containerViewVerticalConstraint uninstall];
                self.containerViewVerticalConstraint = make.bottom.equalTo(self.view.mas_bottom);
            }];
            [self.view layoutIfNeeded];
        }
    }];
}

- (void)didPan:(UIPanGestureRecognizer *)pan {
    if ([self shouldFailPanGestureRecognizer:pan]) {
        [pan setTranslation:CGPointZero inView:self.containerView];
        return;
    }

    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            [pan setTranslation:CGPointZero inView:self.containerView];

            self.panStartPoint = [pan translationInView:self.containerView];
            self.originalCenter = self.containerView.center;

            self.containerViewAnchored = YES;
        } break;

        case UIGestureRecognizerStateChanged: {
            CGPoint point = [pan translationInView:self.containerView];
            CGFloat dy = point.y - self.panStartPoint.y;

            CGPoint center = self.containerView.center;

            if (dy > 0 || center.y > self.originalCenter.y) {
                center.y += dy;
            }

            center.y = MAX(center.y, self.originalCenter.y);

            if (!CGPointEqualToPoint(self.containerView.center, self.originalCenter)) {
                self.containerViewAnchored = NO;
            } else {
                self.containerViewAnchored = YES;
            }

            self.containerView.center = center;

            [pan setTranslation:CGPointZero inView:self.containerView];
        } break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            if (self.containerView.center.y > self.originalCenter.y + 100) {
                [self dismissAction];
            } else {
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    self.containerView.center = self.originalCenter;
                } completion:^(BOOL finished) {
                    self.containerViewAnchored = YES;
                }];
            }
        } break;

        default:
            break;
    }
}

- (BOOL)shouldFailPanGestureRecognizer:(UIPanGestureRecognizer *)pan {
    BOOL shouldFail = NO;

    shouldFail = self.tableView.contentOffset.y > -MAX(self.tableView.contentInset.top, 0);

    return shouldFail;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.tableView && [keyPath isEqualToString:@"contentOffset"]) {
        if (!self.containerViewAnchored && self.tableView.contentOffset.y > 0) {
            [self haltScrolling:self.tableView];
        } else if ((self.tableView.isDragging && !self.tableView.isDecelerating) || self.tableView.isTracking) {
            if (self.containerViewAnchored) {
                [self trackScrolling:self.tableView];
            } else {
                [self haltScrolling:self.tableView];
            }
        } else {
            [self trackScrolling:self.tableView];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)haltScrolling:(UIScrollView *)scrollView {
    [scrollView setContentOffset:self.scrollViewContentOffset animated:NO];
//    scrollView.showsVerticalScrollIndicator = NO;
}

- (void)trackScrolling:(UIScrollView *)scrollView {
    CGPoint contentOffset = scrollView.contentOffset;
    contentOffset.y = MAX(scrollView.contentOffset.y, -(MAX(scrollView.contentInset.top, 0)));
    self.scrollViewContentOffset = contentOffset;
//    scrollView.showsVerticalScrollIndicator = YES;
}

#pragma mark - Lazy Load

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor blackColor];
        _containerView.layer.cornerRadius = 15;
        _containerView.layer.masksToBounds = YES;

        [_containerView addGestureRecognizer:self.panGestureRecognizer];
    }
    return _containerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)array {
    if (!_array) {
        _array = [NSMutableArray arrayWithCapacity:20];

        for (NSInteger i = 0; i < 20; ++i) {
            [_array addObject:[NSString stringWithFormat:@"row%zd", i]];
        }
    }
    return _array;
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissAction)];
    }
    return _tapGestureRecognizer;
}

- (UIPanGestureRecognizer *)panGestureRecognizer {
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
        _panGestureRecognizer.delegate = self;
    }
    return _panGestureRecognizer;
}

@end
