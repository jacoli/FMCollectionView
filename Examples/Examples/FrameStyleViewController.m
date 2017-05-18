//
//  FrameStyleViewController.m
//  Examples
//
//  Created by 李传格 on 2017/5/18.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "FrameStyleViewController.h"
#import "FMCollectionView.h"

@interface FrameStyleViewController () <FMCollectionViewDelegatesAndDataSource>

@property (nonatomic, strong) FMCollectionView *collectionView;

@end

@implementation FrameStyleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.collectionView = [[FMCollectionView alloc] initWithFrame:self.view.bounds];
    self.collectionView.sectionsSpacing = 20;
    self.collectionView.itemsSpacing = 4;
    self.collectionView.delegatesAndDataSource = self;
    self.collectionView.editingMode = YES;
    [self.view addSubview:self.collectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FMSectionLayoutStyle)collectionView:(FMCollectionView *)collectionView layoutInSection:(NSInteger)section {
    return FMSectionLayoutStyleFrame;
}

- (CGRect)frameLayoutInCollectionView:(FMCollectionView *)collectionView frameOfItemInSectionAtIndexPath:(NSIndexPath *)indexPath sectionContentWidth:(CGFloat)inWidth {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return CGRectMake(0, 0, inWidth * 0.4, inWidth * 0.4);
        } else if (indexPath.row == 1) {
            return CGRectMake(inWidth * 0.4 + 1, 0, inWidth * 0.6 - 1, inWidth * 0.2 - 0.5);
        } else {
            return CGRectMake(inWidth * 0.4 + 1, inWidth * 0.2 + 0.5, inWidth * 0.6 - 1, inWidth * 0.2 - 0.5);
        }
    } else if (indexPath.section == 1) {
        return CGRectMake(inWidth * 0.1 * indexPath.row, (inWidth * 0.4 + 1) * indexPath.row, inWidth * 0.4, inWidth * 0.4);
    } else {
        return CGRectZero;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return 10;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 5;
    } else {
        return 0;
    }
}

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *item = [collectionView dequeueReusableItemWithId:@"item" atIndexPath:indexPath itemClass:UILabel.class];
    
    item.text = [NSString stringWithFormat:@"%@/%@", @(indexPath.section), @(indexPath.row)];
    item.textAlignment = NSTextAlignmentCenter;
    item.backgroundColor = [UIColor greenColor];
    
    return item;
}

@end
