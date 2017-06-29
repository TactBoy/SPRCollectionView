//
//  ViewController.m
//  SpringUICollectionView
//
//  Created by Gavin on 2017/6/27.
//  Copyright © 2017年 Gavin. All rights reserved.
//

#import "ViewController.h"
#import "CollectionViewFlowLayout.h"
#import "CollectionViewCell.h"

static NSString * const cellIden = @"CollectionViewCell";

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CollectionViewFlowLayoutDelagate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view addSubview:self.collectionView];
    
    self.dataSource = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < 20; i++) {
        [self.dataSource addObject:[NSString stringWithFormat:@"%d", i]];
    }
}

#pragma mark -
#pragma mark -- -- -- -- -- - UICollectView Delegate & DataSource - -- -- -- -- --
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 20;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIden forIndexPath:indexPath];
    cell.gestureDelagate = self.flowLayout;
    cell.textLabel.text = [NSString stringWithFormat:@"Cell Index: %@", self.dataSource[indexPath.row]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self.flowLayout collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark -- -- -- -- -- - CollectionViewFlowLayout Delegate - -- -- -- -- --
- (void)collectionViewFlowLayout:(CollectionViewFlowLayout *)flowLayout moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    [self.dataSource exchangeObjectAtIndex:indexPath.item withObjectAtIndex:newIndexPath.item];
}

#pragma mark -
#pragma mark -- -- -- -- -- - Get & Set - -- -- -- -- --
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        self.flowLayout = [CollectionViewFlowLayout new];
        self.flowLayout.delagate = self;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.contentInset = UIEdgeInsetsMake(44, 10, 10, 20);
        [_collectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:cellIden];
    }
    return _collectionView;
}

@end
