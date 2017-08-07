//
//  FlowStyleViewController.m
//  Examples
//
//  Created by 李传格 on 2017/5/18.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "FlowStyleViewController.h"
#import "FMCollectionView.h"

@interface FlowStyleViewController () <FMCollectionViewDelegatesAndDataSource>

@property (nonatomic, strong) FMCollectionView *collectionView;

@end

@implementation FlowStyleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.collectionView = [[FMCollectionView alloc] initWithFrame:self.view.bounds];
    self.collectionView.sectionsSpacing = 20;
    self.collectionView.itemsSpacing = 4;
    self.collectionView.sectionEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20);
    self.collectionView.delegatesAndDataSource = self;
    self.collectionView.editingMode = YES;
    [self.view addSubview:self.collectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FMSectionLayoutStyle)collectionView:(FMCollectionView *)collectionView layoutInSection:(NSInteger)section {
    return FMSectionLayoutStyleFlow;
}

- (CGSize)sizeAtIndexPath:(NSIndexPath *)indexPath forFlowLayoutWithSectionWidth:(CGFloat)sectionWidth {
    if (indexPath.section == 0) {
        return CGSizeMake(CGRectGetWidth(self.collectionView.frame) - 100, 72);
    } else {
        if (indexPath.row % 3 == 0) {
            return CGSizeMake(100, 200);
        } else if (indexPath.row % 3 == 1) {
            return CGSizeMake(CGRectGetWidth(self.collectionView.frame) - 100, 72);
        } else {
            return CGSizeMake(150, 150);
        }
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return 5;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 5;
}

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *item = [collectionView dequeueReusableItemWithId:@"item" atIndexPath:indexPath itemClass:UILabel.class];
    
    item.text = [NSString stringWithFormat:@"%@/%@", @(indexPath.section), @(indexPath.row)];
    item.textAlignment = NSTextAlignmentCenter;
    item.backgroundColor = [UIColor greenColor];
    
    return item;
}

@end
