//
//  CollectionViewFlowLayout.m
//  SpringUICollectionView
//
//  Created by Gavin on 2017/6/27.
//  Copyright © 2017年 Gavin. All rights reserved.
//

#import "CollectionViewFlowLayout.h"

#define kCollectionViewWidth (self.collectionView.frame.size.width)
#define kCollectionViewHeight (self.collectionView.frame.size.height)

#define kCellHeight 200 /// cell 高度
#define kCellSpace 100 // cell0Top to cell1Top
#define kComeUpAnimationDuration 0.25
#define kBottomAutoScrollDistance 200
#define kTopAutoScrollDistance 100
#define kCanMoveDistance 30
#define kExpandBottomHeight 50 // 展开cell的bottom距离屏幕bottom的距离,称之为footer吧
#define kExpandBottomFirstCellMarginOfTop 10 // footer里面第一个cell距离顶部的距离
#define kExpandBottomCellSpace 10 // footer里面第cell的间距


#if TARGET_IPHONE_SIMULATOR
#define kAutoScrollSpeed 10
#elif TARGET_OS_IPHONE
#define kAutoScrollSpeed 4
#endif



typedef NS_ENUM(NSInteger, CollectionViewAutoScrollType){
    CollectionViewAutoScrollNone = 0,
    CollectionViewAutoScrollUp, // 向上
    CollectionViewAutoScrollDown, // 向下
};


@interface CollectionViewFlowLayout ()
@property (nonatomic, strong) UIImageView *shootImageView;

@property(assign, nonatomic) CGPoint longPressGesLastLocation;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property(assign, nonatomic) BOOL isMoveing;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property(weak, nonatomic) CollectionViewCell *currentCell;
@property(assign, nonatomic) CollectionViewAutoScrollType scrollType;
@property(assign, nonatomic) BOOL isExpand; // 是否是展开状态
@property(assign, nonatomic) CGFloat currentCellShrinkMarginLeft; // 关闭是的left
@end

@implementation CollectionViewFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
//    self.estimatedItemSize = CGSizeMake(50, 50);
    UIEdgeInsets inset = self.collectionView.contentInset;
    self.itemSize = CGSizeMake(kCollectionViewWidth - inset.right - inset.left, kCellHeight);
    self.minimumLineSpacing = kCellSpace - kCellHeight;

}

- (CGSize)collectionViewContentSize {
    UIEdgeInsets inset = self.collectionView.contentInset;
    NSInteger items = [self.collectionView numberOfItemsInSection:0];
    CGSize size = CGSizeMake(self.collectionView.frame.size.width - inset.left - inset.right, (items - 1) * kCellSpace + kCellHeight- inset.bottom);
    return size;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}


- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger rows = [self.collectionView numberOfItemsInSection:0];
    CGFloat offsetY = self.collectionView.contentOffset.y;
    UIEdgeInsets inset = self.collectionView.contentInset;
    NSMutableArray *attrs = [NSMutableArray arrayWithCapacity:0];\
    // 与rect相交的最大最小item值
    int minRow = MAX(0, floor((offsetY)  / kCellSpace));
    int maxRow = MIN(ceil((offsetY + self.collectionView.frame.size.height)  / kCellSpace), rows);
    int shrinkCellIndex = 0; // 缩起来cell的下标,0, 1, 2, 3
    for (int row = minRow; row < maxRow; row++) {
        // 顶部只留一个cell
        if (row * kCellSpace >= offsetY - kCellSpace) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
            UICollectionViewLayoutAttributes *att = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            CGRect cellRect = CGRectMake(0, MAX(offsetY, row * kCellSpace), kCollectionViewWidth - inset.right, kCellHeight);
            CGFloat left = (4 - shrinkCellIndex) * 5;
            CGFloat top = shrinkCellIndex * kExpandBottomCellSpace + kExpandBottomFirstCellMarginOfTop;
            if (self.isExpand) {
                if (indexPath.item == self.currentIndexPath.item) {
                    cellRect = CGRectMake(0, offsetY, kCollectionViewWidth - inset.right, kCollectionViewHeight - kExpandBottomHeight);
                    self.currentCellShrinkMarginLeft = left;
                } else {
                    cellRect = CGRectMake(left, offsetY + (kCollectionViewHeight - kExpandBottomHeight) + top, kCollectionViewWidth - inset.right - left * 2, kCellHeight);
                    shrinkCellIndex++;
                    shrinkCellIndex = MIN(shrinkCellIndex, 3);
                }
            } else {
                if (offsetY < -inset.top) {
                    // 0.25是相对于offsetY的偏移比例,根据需要自行调节
                    cellRect.origin.y = att.indexPath.item * kCellSpace - fabs(offsetY + inset.top) + fabs(offsetY + inset.top) * att.indexPath.item * 0.25;
                }
            }
            att.frame = cellRect;
            att.center = CGPointMake(CGRectGetMinX(cellRect) + CGRectGetWidth(cellRect) / 2, CGRectGetMinY(cellRect) + CGRectGetHeight(cellRect) / 2);
            // 因为我们的cell有重叠,必须设置zIndex,否则复用时层级会有问题
            att.zIndex = att.indexPath.item * 2;
            att.transform3D = CATransform3DMakeTranslation(0, 0, att.indexPath.item * 2);
            if (CGRectIntersectsRect(cellRect, rect) || CGRectContainsRect(cellRect, rect)) {
                [attrs addObject:att];
            }
        }
    }
    return attrs;
}

#pragma mark -
#pragma mark -- -- -- -- -- - CollectionViewCell Delegate - -- -- -- -- --
- (void)collectionViewCell:(CollectionViewCell *)cell handlerLongPressGesture:(UILongPressGestureRecognizer *)ges {
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        {
            // 对cell进行截图
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            self.currentIndexPath = indexPath;
            self.currentCell = cell;
            self.isMoveing = NO;
            if (!self.shootImageView) {
                self.shootImageView = [UIImageView new];
            }
            self.shootImageView.image = [self screenshotWithView:cell];
            self.shootImageView.frame = cell.frame;
            self.shootImageView.layer.transform = CATransform3DMakeTranslation(0, 0, indexPath.item * 2 + 1);
            [self.collectionView addSubview:self.shootImageView];
            // 让截图浮出来
            cell.hidden = YES;
            [UIView animateWithDuration:kComeUpAnimationDuration animations:^{
                CGRect frame = self.shootImageView.frame;
                frame.origin.y -= 30;
                self.shootImageView.frame = frame;
            } completion:^(BOOL finished) {
            }];
            self.longPressGesLastLocation = [ges locationInView:self.collectionView];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            // 移动view
            CGPoint location = [ges locationInView:self.collectionView];
            CGFloat translateY = location.y - self.longPressGesLastLocation.y;
            CGRect frame = self.shootImageView.frame;
            
            frame.origin.y += translateY;
            self.shootImageView.frame = frame;
            
            // 如果滑到头则进行滚动
            CGFloat bottom = frame.origin.y - self.collectionView.contentOffset.y - self.collectionView.frame.size.height;
            CGFloat top = frame.origin.y - self.collectionView.contentOffset.y;
            
            if (self.scrollType == CollectionViewAutoScrollNone) {
                // 根据第一次的手势来判断执行那种滚动
                BOOL shouldAutoScrollDown = fabs(top) < kTopAutoScrollDistance && translateY < -0.5;
                BOOL shouldAutoScrollUp = fabs(bottom) < kBottomAutoScrollDistance && translateY > 0.5;
                if (shouldAutoScrollDown) {
                    self.scrollType = CollectionViewAutoScrollDown;
                } else if(shouldAutoScrollUp) {
                    self.scrollType = CollectionViewAutoScrollUp;
                } else {
                    self.scrollType = CollectionViewAutoScrollNone;
                }
                // 处于顶部或者底部的滚动范围之内不做处理
                if (fabs(top) > kTopAutoScrollDistance && fabs(bottom) > kBottomAutoScrollDistance) {
                    [self handlerMoveItemAction];
                }
            } else {
                // 滚动中则只根据距离来判断
                BOOL shouldAutoScrollDown = fabs(top) < kTopAutoScrollDistance;
                BOOL shouldAutoScrollUp = fabs(bottom) < kBottomAutoScrollDistance;
                if (shouldAutoScrollDown) {
                    self.scrollType = CollectionViewAutoScrollDown;
                } else if(shouldAutoScrollUp) {
                    self.scrollType = CollectionViewAutoScrollUp;
                } else {
                    self.scrollType = CollectionViewAutoScrollNone;
                }
            }

            if (self.scrollType != CollectionViewAutoScrollNone) {
                if (!self.displayLink) {
                    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
                    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
                }
            } else {
                [self.displayLink invalidate];
                self.displayLink = nil;
            }
            self.longPressGesLastLocation = [ges locationInView:self.collectionView];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self.displayLink invalidate];
            self.displayLink = nil;
            self.scrollType = CollectionViewAutoScrollNone;
            [UIView animateWithDuration:kComeUpAnimationDuration animations:^{
                CGRect frame = cell.frame;
                self.shootImageView.frame = frame;
            } completion:^(BOOL finished) {
                [self.shootImageView removeFromSuperview];
                cell.hidden = NO;
            }];
        }
            break;
        default:
            break;
    }
}

- (void)collectionViewCell:(CollectionViewCell *)cell handlerPanGesture:(UIPanGestureRecognizer *)ges {
    CGFloat offsetY = self.collectionView.contentOffset.y;
    UIEdgeInsets inset = self.collectionView.contentInset;
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        {
            
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translate = [ges translationInView:cell];
            CGPoint velocity = [ges velocityInView:cell];
            if (velocity.y > 1300) {
                [ges setEnabled:NO];
                [self closeCell];
                return;
            }
            CGRect frame = cell.frame;
            CGFloat pecent = (frame.origin.y - offsetY) / (kCollectionViewHeight - kExpandBottomHeight);
            CGFloat left = pecent * self.currentCellShrinkMarginLeft;
            [cell setTransform:CGAffineTransformTranslate(cell.transform, 0, translate.y)];
            frame = CGRectMake(left, frame.origin.y + translate.y, kCollectionViewWidth - inset.right - left * 2,kCollectionViewHeight - kExpandBottomHeight );
            cell.frame = frame;
            [ges setTranslation:CGPointZero inView:cell];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            
            if (cell.frame.origin.y > kCollectionViewHeight / 2 - kExpandBottomHeight / 2) {
                // 结束
                [self closeCell];
            } else {
                // 复位
                [UIView animateWithDuration:kComeUpAnimationDuration animations:^{
                    cell.frame = CGRectMake(0, offsetY, kCollectionViewWidth - inset.right, kCollectionViewHeight - kExpandBottomHeight);
                }];
            }
        }
            break;
        default:
            break;
    }
}



#pragma mark -
#pragma mark -- -- -- -- -- - Event Response - -- -- -- -- --
- (void)displayLinkAction:(CADisplayLink *)link {
    // 滚倒底了已经
    if (self.scrollType == CollectionViewAutoScrollUp && self.collectionView.contentOffset.y + self.collectionView.frame.size.height > self.collectionView.contentSize.height) {
        return;
    }
    
    // 滚到顶了
    if (self.scrollType == CollectionViewAutoScrollDown && self.collectionView.contentOffset.y < 0) {
        return;
    }
    
    if (self.isMoveing) {
        return;
    }
    
    CGFloat increaseValue;
    
    if (self.scrollType == CollectionViewAutoScrollUp) {
        // 让collectionView刚好可以滚到底
        increaseValue = MIN(kAutoScrollSpeed, self.collectionView.contentSize.height - self.collectionView.frame.size.height - self.collectionView.contentOffset.y);
    } else {
        increaseValue = MAX(-kAutoScrollSpeed, -self.collectionView.contentOffset.y);
    }
    
    CGRect frame = self.shootImageView.frame;
    frame.origin.y += increaseValue;
    self.shootImageView.frame = frame;
    
    CGPoint point = self.longPressGesLastLocation;
    point.y += increaseValue;
    self.longPressGesLastLocation = point;

    CGPoint offset = self.collectionView.contentOffset;
    offset.y += increaseValue;
    [self.collectionView setContentOffset:offset];

    /// TODO: 优化顶部的交换
    [self handlerMoveItemAction];
}


- (void)handlerMoveItemAction {
    if (!self.isMoveing) {
        // 取到当前cell附近的cell, 判断是否可以交换
        BOOL shouldMove = NO;
        NSIndexPath *preferIndexPath;
        CollectionViewCell *preferCell;
        preferIndexPath = [NSIndexPath indexPathForItem:self.currentIndexPath.item + 1 inSection:self.currentIndexPath.section];
        preferCell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:preferIndexPath];

        // 间距小于`kCanMoveDistance`开始交换
        if (fabs(preferCell.frame.origin.y - self.shootImageView.frame.origin.y) < kCanMoveDistance) {
            shouldMove = YES;
        } else {
            preferIndexPath = [NSIndexPath indexPathForItem:self.currentIndexPath.item - 1 inSection:self.currentIndexPath.section];
            preferCell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:preferIndexPath];
            if (fabs(preferCell.frame.origin.y - self.shootImageView.frame.origin.y) < kCanMoveDistance) {
                shouldMove = YES;
            } else {
                return;
            }
        }
    
        if (shouldMove && preferCell && preferIndexPath) {
            [self.collectionView performBatchUpdates:^{
                self.isMoveing = YES;
                [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:preferIndexPath];
                
                if ([self.delagate respondsToSelector:@selector(collectionViewFlowLayout:moveItemAtIndexPath:toIndexPath:)]) {
                    [self.delagate collectionViewFlowLayout:self moveItemAtIndexPath:self.currentIndexPath toIndexPath:preferIndexPath];
                }
                // 完成之后更新transform
                self.shootImageView.layer.transform = CATransform3DMakeTranslation(0, 0, preferIndexPath.row * 2 + 1);
                // 这个地方需要重新设置层级,更改transform无用?
                if (preferIndexPath.item > self.currentIndexPath.item) {
                    [self.collectionView insertSubview:self.currentCell aboveSubview:preferCell];
                } else {
                    [self.collectionView insertSubview:preferCell aboveSubview:self.currentCell];
                }
                self.currentIndexPath = preferIndexPath;
                if (self.scrollType == CollectionViewAutoScrollDown) {
                    // 头部有很多的cell,交换太快会闪屏,需要有间隔
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.isMoveing = NO;
                    });
                } else {
                    self.isMoveing = NO;
                }
            } completion:^(BOOL finished) {

            }];
        }
    }
}

#pragma mark -
#pragma mark -- -- -- -- -- - Cell Move Animation - -- -- -- -- --
//- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
//    
//}
//
//- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
//}
//
//- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath{

//}
//
//- (void)finalizeCollectionViewUpdates {

//}


#pragma mark -
#pragma mark -- -- -- -- -- - ExpandCell - -- -- -- -- --
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.isExpand) {
        [self expandCellWithIndexPath:indexPath];
    } else {
        [self closeCellWithoutAnimation];
    }
}

- (void)expandCellWithIndexPath:(NSIndexPath *)indexPath {
    self.currentIndexPath = indexPath;
    self.currentCell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    self.currentCell.panGes.enabled = YES;
    self.isExpand = YES;
    
    [self.collectionView performBatchUpdates:^{
        [self invalidateLayout];
    } completion:^(BOOL finished) {
        self.collectionView.scrollEnabled = NO;
    }];

}

- (void)closeCellWithoutAnimation {
    self.isExpand = NO;
    self.currentCell.panGes.enabled = NO;
    [self.collectionView performBatchUpdates:^{
        [self invalidateLayout];
    } completion:^(BOOL finished) {
        self.collectionView.scrollEnabled = YES;
    }];
}

- (void)closeCell {
    // 结束
    UIEdgeInsets inset = self.collectionView.contentInset;
    [UIView animateWithDuration:kComeUpAnimationDuration animations:^{
        self.currentCell.frame = CGRectMake(self.currentCellShrinkMarginLeft, kCollectionViewHeight, kCollectionViewWidth - inset.right - self.currentCellShrinkMarginLeft * 2, kCollectionViewHeight - kExpandBottomHeight);
    }completion:^(BOOL finished) {
        [self closeCellWithoutAnimation];
    }];
}

- (UIImage *)screenshotWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
