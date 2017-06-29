//
//  CollectionViewCell.h
//  SpringUICollectionView
//
//  Created by Gavin on 2017/6/27.
//  Copyright © 2017年 Gavin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CollectionViewCell;

@protocol CollectionViewCellGestureDelegate <NSObject>
- (void)collectionViewCell:(CollectionViewCell *)cell handlerLongPressGesture:(UILongPressGestureRecognizer *)ges;
- (void)collectionViewCell:(CollectionViewCell *)cell handlerPanGesture:(UIPanGestureRecognizer *)ges;


@end

@interface CollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *panGes;

@property(weak, nonatomic) id<CollectionViewCellGestureDelegate> gestureDelagate;
@end
