//
//  CollectionViewCell.m
//  SpringUICollectionView
//
//  Created by Gavin on 2017/6/27.
//  Copyright © 2017年 Gavin. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [CollectionViewCell randomColor];
    
    UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnCell:)];
    [self addGestureRecognizer:longPressGes];
    
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnCell:)];
    [self addGestureRecognizer:panGes];
    self.panGes = panGes;
    self.panGes.enabled = NO;

    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 切上左和上右的圆角
    self.layer.mask = nil;
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.frame = self.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(16, 0)];
    layer.path = path.CGPath;
    self.layer.mask = layer;
}

#pragma mark -
#pragma mark -- -- -- -- -- - Event Response - -- -- -- -- --
- (void)longPressOnCell:(UILongPressGestureRecognizer *)ges {
    if ([self.gestureDelagate respondsToSelector:@selector(collectionViewCell:handlerLongPressGesture:)]) {
        [self.gestureDelagate collectionViewCell:self handlerLongPressGesture:ges];
    }
}

- (void)panOnCell:(UIPanGestureRecognizer *)ges {
    if ([self.gestureDelagate respondsToSelector:@selector(collectionViewCell:handlerPanGesture:)]) {
        [self.gestureDelagate collectionViewCell:self handlerPanGesture:ges];
    }
}



+ (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}



@end
