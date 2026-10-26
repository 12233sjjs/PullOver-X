//
//  MHHandle.m
//  MessageHub
//
//  Created by Will Smillie on 1/18/19.
//

#import "POHandle.h"
#import <QuartzCore/QuartzCore.h>
#import "PullOverViewController.h"

#import "POApplicationHelper.h"

#define PO_HANDLE_DEFAULT_SIZE 34.0
#define PO_HANDLE_MINIMUM_SIZE 34.0
#define PO_HANDLE_MAXIMUM_SIZE 50.0
#define PO_HANDLE_DEFAULT_NUB_HIDDEN_PERCENTAGE 70.0
#define PO_HANDLE_MAXIMUM_NUB_HIDDEN_PERCENTAGE 100.0
#define PO_HANDLE_MINIMUM_TOUCH_SIZE 52.0

@interface POHandle () <UIGestureRecognizerDelegate> {
    UILabel *messageLabel;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UILongPressGestureRecognizer *quickSwitchLongPress;
    UIPanGestureRecognizer *_panelPanGestureRecognizer;
    CGPoint tapTouchStartPoint;
    BOOL hasTapTouchStartPoint;
    BOOL interactionOpaque;
}

-(void)applyCurrentPresentationAnimated:(BOOL)animated;
-(BOOL)usesOpaquePresentation;
-(void)setInteractionOpaque:(BOOL)opaque;

@end

@implementation POHandle

-(CGFloat)handleSize{
    id configuredValue = [POApplicationHelper settings][@"handleSize"];
    CGFloat size = configuredValue ? [configuredValue doubleValue] : PO_HANDLE_DEFAULT_SIZE;
    if (size <= 0) {
        size = PO_HANDLE_DEFAULT_SIZE;
    }
    return MIN(MAX(size, PO_HANDLE_MINIMUM_SIZE), PO_HANDLE_MAXIMUM_SIZE);
}

-(CGFloat)nubHiddenPercentage{
    id configuredValue = [POApplicationHelper settings][@"nubHiddenPercentage"];
    CGFloat percentage = configuredValue ? [configuredValue doubleValue] : PO_HANDLE_DEFAULT_NUB_HIDDEN_PERCENTAGE;
    if (!isfinite(percentage) || percentage < 0) {
        percentage = PO_HANDLE_DEFAULT_NUB_HIDDEN_PERCENTAGE;
    }
    return MIN(MAX(round(percentage), 0), PO_HANDLE_MAXIMUM_NUB_HIDDEN_PERCENTAGE);
}

-(CGFloat)handleOpacity{
    if ([self usesOpaquePresentation]) return 1.0;
    NSDictionary *settings = [POApplicationHelper settings];
    id configuredValue = self.opacityPreferenceKey ? settings[self.opacityPreferenceKey] : nil;
    if (!configuredValue) configuredValue = settings[@"handleOpacity"];
    CGFloat opacity = configuredValue ? [configuredValue doubleValue] / 100.0 : 1.0;
    return isfinite(opacity) ? MIN(MAX(opacity, 0.0), 1.0) : 1.0;
}

-(void)setOpacityPreferenceKey:(NSString *)key{
    _opacityPreferenceKey = [key copy];
    [self applyHandleOpacity];
}

-(void)applyHandleOpacity{
    CGFloat opacity = [self handleOpacity];
    self.backgroundColor = [self usesOpaquePresentation]
        ? UIColor.secondarySystemBackgroundColor
        : [UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:0.78 * opacity];
    self.layer.shadowOpacity = [self usesOpaquePresentation] ? (float)(0.32 * opacity) : 0;
    self.imageView.alpha = opacity;
}

-(BOOL)usesOpaquePresentation{
    return self.forceOpaque || interactionOpaque;
}

-(void)setInteractionOpaque:(BOOL)opaque{
    if (interactionOpaque == opaque) return;
    interactionOpaque = opaque;
    [self applyHandleOpacity];
}

-(void)setForceOpaque:(BOOL)forceOpaque{
    if (_forceOpaque == forceOpaque) return;
    _forceOpaque = forceOpaque;
    [self applyHandleOpacity];
}

-(CGFloat)fullCornerRadius{
    return CGRectGetWidth(self.bounds) * (8.0 / PO_HANDLE_DEFAULT_SIZE);
}

-(CGFloat)nubbedCornerRadius{
    return CGRectGetWidth(self.bounds) * (6.0 / PO_HANDLE_DEFAULT_SIZE);
}

-(BOOL)usesNubbedPresentation{
    return self.layoutMode == POHandleLayoutModeVerticalRail && self.isNubbed;
}

-(CGFloat)nubbedOriginX{
    CGFloat containerWidth = CGRectGetWidth(self.superview.bounds);
    if (containerWidth <= 0) {
        containerWidth = 50.0;
    }
    CGFloat visibleWidth = CGRectGetWidth(self.bounds) * (1.0 - [self nubHiddenPercentage] / 100.0);
    return containerWidth - visibleWidth;
}

-(void)applyNubbedPosition{
    CGRect frame = self.frame;
    frame.origin.x = [self nubbedOriginX];
    self.frame = frame;
}

-(void)applyHandleSize{
    CGFloat size = [self handleSize];
    CGRect frame = self.frame;
    frame.size = CGSizeMake(size, size);
    self.frame = frame;
    self.layer.cornerRadius = [self fullCornerRadius];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;

    CGFloat iconSize = MAX(0, size - 10.0);
    self.imageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - iconSize) / 2.0,
                                      (CGRectGetHeight(self.bounds) - iconSize) / 2.0,
                                      iconSize,
                                      iconSize);
}

-(instancetype)initWithController:(id)hubController{
    if (self = [super initWithFrame:CGRectMake(0, 0, PO_HANDLE_DEFAULT_SIZE, PO_HANDLE_DEFAULT_SIZE)]) {
        self.layer.cornerRadius = 8;
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowRadius:3.5];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:8].CGPath;

        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];

        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        _doubleTapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_doubleTapGestureRecognizer];
        [_tapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];

        quickSwitchLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        quickSwitchLongPress.minimumPressDuration = .3f;
        quickSwitchLongPress.delegate = self;
        quickSwitchLongPress.cancelsTouchesInView = NO;
        [self addGestureRecognizer:quickSwitchLongPress];
        [_tapGestureRecognizer requireGestureRecognizerToFail:quickSwitchLongPress];
        [_doubleTapGestureRecognizer requireGestureRecognizerToFail:quickSwitchLongPress];
        _panelPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(panelPan:)];
        _panelPanGestureRecognizer.delegate = self;
        _panelPanGestureRecognizer.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:_panelPanGestureRecognizer];
        [_panelPanGestureRecognizer requireGestureRecognizerToFail:quickSwitchLongPress];
        [_tapGestureRecognizer requireGestureRecognizerToFail:_panelPanGestureRecognizer];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.clipsToBounds = YES;
        self.imageView.tintColor = [UIColor lightGrayColor];
        [self addSubview:self.imageView];
        self.layoutMode = POHandleLayoutModeVerticalRail;
        [self applyHandleSize];
        [self applyHandleOpacity];
        
        [self setIsNubbed:[[NSUserDefaults standardUserDefaults] boolForKey:@"isNubbed"]];
    }
    return self;
}

-(void)setIsNubbed:(BOOL)isNubbed{
    _isNubbed = isNubbed;
    [[NSUserDefaults standardUserDefaults] setBool:isNubbed forKey:@"isNubbed"];
    [self applyCurrentPresentationAnimated:YES];
}

-(void)setLayoutMode:(POHandleLayoutMode)layoutMode{
    if (_layoutMode == layoutMode) {
        return;
    }
    _layoutMode = layoutMode;
    [self applyCurrentPresentationAnimated:NO];
}

-(void)applyCurrentPresentationAnimated:(BOOL)animated{
    void (^changes)(void) = ^{
        if ([self usesNubbedPresentation]) {
            [self applyNubbedPosition];
            self.layer.cornerRadius = [self nubbedCornerRadius];
        } else {
            CGRect frame = self.frame;
            frame.origin.x = self.restingOriginX;
            self.frame = frame;
            self.layer.cornerRadius = [self fullCornerRadius];
        }
        self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    };
    if (animated) {
        [UIView animateWithDuration:0.2 delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:changes completion:nil];
    } else {
        changes();
    }
}

-(void)refreshHandleSizeAnimated:(BOOL)animated{
    void (^changes)(void) = ^{
        [self applyHandleSize];
        [self applyHandleOpacity];
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:changes];
    } else {
        changes();
    }
}

-(void)refreshNubbedPositionAnimated:(BOOL)animated{
    [self applyCurrentPresentationAnimated:animated];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    if (self.layoutMode == POHandleLayoutModeLandscapeFixedBottomLeft) {
        CGFloat horizontalInset = MAX(5.0, (PO_HANDLE_MINIMUM_TOUCH_SIZE - CGRectGetWidth(self.bounds)) / 2.0);
        CGFloat verticalInset = MAX(5.0, (PO_HANDLE_MINIMUM_TOUCH_SIZE - CGRectGetHeight(self.bounds)) / 2.0);
        CGRect hitRect = CGRectInset(self.bounds, -horizontalInset, -verticalInset);
        return CGRectContainsPoint(hitRect, point);
    }

    CGFloat containerWidth = CGRectGetWidth(self.superview.bounds);
    if (containerWidth <= 0) {
        containerWidth = 50.0;
    }

    CGFloat desiredHitLeftInContainer = containerWidth - PO_HANDLE_MINIMUM_TOUCH_SIZE;
    CGFloat leadingInset = MAX(5.0, CGRectGetMinX(self.frame) - desiredHitLeftInContainer);
    CGFloat verticalInset = MAX(5.0, (PO_HANDLE_MINIMUM_TOUCH_SIZE - CGRectGetHeight(self.bounds)) / 2.0);
    CGRect hitRect = CGRectMake(-leadingInset,
                                -verticalInset,
                                CGRectGetWidth(self.bounds) + leadingInset + 5.0,
                                CGRectGetHeight(self.bounds) + verticalInset * 2.0);
    return CGRectContainsPoint(hitRect, point);
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        UIPanGestureRecognizer *railPan = ((UIScrollView *)self.superview).panGestureRecognizer;
        [railPan requireGestureRecognizerToFail:quickSwitchLongPress];
        [railPan requireGestureRecognizerToFail:_panelPanGestureRecognizer];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _tapGestureRecognizer && hasTapTouchStartPoint) {
        hasTapTouchStartPoint = NO;
        CGPoint endPoint = [gestureRecognizer locationInView:self];
        return hypot(endPoint.x - tapTouchStartPoint.x, endPoint.y - tapTouchStartPoint.y) <= 5.0;
    }
    if (gestureRecognizer == _panelPanGestureRecognizer) {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self];
        CGFloat absX = fabs(velocity.x);
        CGFloat absY = fabs(velocity.y);
        if (self.allowsVerticalMovement || self.layoutMode == POHandleLayoutModeLandscapeFixedBottomLeft) {
            return MAX(absX, absY) > 0.0 && fabs(absX - absY) > 0.01;
        }
        return absX > absY;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == _tapGestureRecognizer) {
        tapTouchStartPoint = [touch locationInView:self];
        hasTapTouchStartPoint = YES;
    }
    return YES;
}


-(void)tap:(UIGestureRecognizer *)recognizer{
    [self.delegate handle:self didReceiveTap:recognizer];
}

-(void)doubleTap:(UIGestureRecognizer *)recognizer{
    [self.delegate handle:self didReceiveDoubleTap:recognizer];
}

-(void)longPress:(UIGestureRecognizer *)recognizer{
    [self.delegate handle:self didLongPress:recognizer];
}

-(void)panelPan:(UIPanGestureRecognizer *)recognizer{
    [self.delegate handle:self didPanPanel:recognizer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self setInteractionOpaque:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self setInteractionOpaque:NO];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self setInteractionOpaque:NO];
    [super touchesCancelled:touches withEvent:event];
}


@end
