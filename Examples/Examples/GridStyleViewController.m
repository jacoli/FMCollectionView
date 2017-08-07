//
//  GridStyleViewController.m
//  Examples
//
//  Created by 李传格 on 2017/5/18.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "GridStyleViewController.h"
#import "FMCollectionView.h"

@interface GridStyleViewController () <FMCollectionViewDelegatesAndDataSource>

@property (nonatomic, strong) FMCollectionView *collectionView;

@end

@implementation GridStyleViewController

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
    
    [self.collectionView enableBottomReflesh:^BOOL{
        return YES;
    } loadMoreCallback:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView endBottomRefleshing:NO];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FMSectionLayoutStyle)collectionView:(FMCollectionView *)collectionView layoutInSection:(NSInteger)section {
    return FMSectionLayoutStyleGrid;
}

- (NSInteger)numberOfColumnsForGridLayoutInSection:(NSInteger)section {
    if (section % 4 == 0) {
        return 5;
    } else if (section % 4 == 1) {
        return 4;
    } else if (section % 4 == 2) {
        return 3;
    } else {
        return 2;
    }
}

- (CGFloat)heightInSection:(NSInteger)section forGridLayoutWithItemWidth:(CGFloat)itemWidth {
    if (section % 4 == 0) {
        return itemWidth * 0.6;
    } else if (section % 4 == 1) {
        return itemWidth;
    } else if (section % 4 == 2) {
        return itemWidth * 1.2;
    } else {
        return itemWidth * 1.5;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return 10;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
}

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *item = [collectionView dequeueReusableItemWithId:@"item" atIndexPath:indexPath itemClass:UILabel.class];
    
    item.text = [NSString stringWithFormat:@"%@/%@", @(indexPath.section), @(indexPath.row)];
    item.textAlignment = NSTextAlignmentCenter;
    item.backgroundColor = [UIColor greenColor];
    
    return item;
}

@end
