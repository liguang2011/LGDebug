//
//  LGDebugWindow.m
//  LGDebug
//
//  Created by lg on 2019/7/11.
//

#import "LGDebugWindow.h"

@implementation LGDebugWindow
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(locationChange:)];
        UITapGestureRecognizer *tabGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(push:)];
        
        [self addGestureRecognizer:panGesture];
        [self addGestureRecognizer:tabGesture];
        [self.debugButton setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 1.0f;
        self.rootViewController = [[UIViewController alloc] init];
        [self addSubview:self.debugButton];
    }
    return self;
}

#pragma mark - Event Response
- (void)locationChange:(UIPanGestureRecognizer *)panGesture {
    
    CGPoint windowPoint = [panGesture locationInView:[UIApplication sharedApplication].windows[0]];
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        
        self.center = windowPoint;
    }
}

-(void)push:(UITapGestureRecognizer *)panGesture{
    [[self debugButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    
}
#pragma mark - Getters & Setters
- (UIButton *)debugButton {
    if (!_debugButton) {
        _debugButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _debugButton.backgroundColor = [UIColor lightGrayColor];
        [_debugButton setTitle:@"Debug" forState:UIControlStateNormal];
        _debugButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_debugButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    _debugButton.layer.cornerRadius = _debugButton.bounds.size.width / 2.0;
    return _debugButton;
}
@end
