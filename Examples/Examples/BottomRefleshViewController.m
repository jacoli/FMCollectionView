//
//  GridStyleViewController.m
//  Examples
//
//  Created by 李传格 on 2017/5/18.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "BottomRefleshViewController.h"
#import "FMCollectionView.h"

@interface BottomRefleshViewController () <FMCollectionViewDelegatesAndDataSource>

@property (nonatomic, strong) FMCollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation BottomRefleshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.dataSource = [[NSMutableArray alloc] initWithArray:@[@"", @"", @"", @"", @"", @"", @"", @""]];
    
    self.collectionView = [[FMCollectionView alloc] initWithFrame:self.view.bounds];
    self.collectionView.sectionsSpacing = 20;
    self.collectionView.itemsSpacing = 4;
    self.collectionView.delegatesAndDataSource = self;
    self.collectionView.editingMode = YES;
    
    [self.view addSubview:self.collectionView];
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView enableBottomReflesh:^BOOL{
        return weakSelf.dataSource.count < 50;
    } loadMoreCallback:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.dataSource addObjectsFromArray:@[@"", @"", @"", @"", @"", @"", @"", @""]];
            [weakSelf.collectionView reloadItemsAndEndBottomRefleshing:YES];
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
    return 2;
}

- (CGFloat)heightInSection:(NSInteger)section forGridLayoutWithItemWidth:(CGFloat)itemWidth {
    return itemWidth * 1.5;
}

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *item = [collectionView dequeueReusableItemWithId:@"item" atIndexPath:indexPath itemClass:UILabel.class];
    
    item.text = [NSString stringWithFormat:@"%@/%@", @(indexPath.section), @(indexPath.row)];
    item.textAlignment = NSTextAlignmentCenter;
    item.backgroundColor = [UIColor greenColor];
    
    return item;
}

@end
