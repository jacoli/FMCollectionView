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
@property (nonatomic, strong) NSMutableArray *layout1;
@property (nonatomic, strong) NSArray *layout2;

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
    
    CGFloat width = CGRectGetWidth(self.collectionView.frame);
    self.layout1 = [[NSMutableArray alloc] init];
    [self.layout1 addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, width * 0.4, width * 0.4)]];
    [self.layout1 addObject:[NSValue valueWithCGRect:CGRectMake(width * 0.4 + 1, 0, width * 0.6 - 1, width * 0.2 - 0.5)]];
    [self.layout1 addObject:[NSValue valueWithCGRect:CGRectMake(width * 0.4 + 1, width * 0.2 + 0.5, width * 0.6 - 1, width * 0.2 - 0.5)]];
    
    self.layout2 = [self buildLayoutStyle2];
}

- (NSArray *)buildLayoutStyle2 {
    NSMutableArray *layout = [[NSMutableArray alloc] init];
    
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat itemWidth = (width - 6.0) / 4.0;
    CGFloat heightRatio = 0.4;
    
    [layout addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, width * 0.5 - 1, width * heightRatio)]];
    [layout addObject:[NSValue valueWithCGRect:CGRectMake(width * 0.5 + 1, 0, width * 0.5 - 1, width * heightRatio)]];
    [layout addObject:[NSValue valueWithCGRect:CGRectMake((itemWidth + 2.0) * 0, width * heightRatio + 2, (width - 6.0) / 4.0, width * heightRatio)]];
    [layout addObject:[NSValue valueWithCGRect:CGRectMake((itemWidth + 2.0) * 1, width * heightRatio + 2, (width - 6.0) / 4.0, width * heightRatio)]];
    [layout addObject:[NSValue valueWithCGRect:CGRectMake((itemWidth + 2.0) * 2, width * heightRatio + 2, (width - 6.0) / 4.0, width * heightRatio)]];
    [layout addObject:[NSValue valueWithCGRect:CGRectMake((itemWidth + 2.0) * 3, width * heightRatio + 2, (width - 6.0) / 4.0, width * heightRatio)]];
    
    return layout;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (FMSectionLayoutStyle)collectionView:(FMCollectionView *)collectionView layoutInSection:(NSInteger)section {
    return FMSectionLayoutStyleFrame;
}

- (CGRect)frameLayoutInCollectionView:(FMCollectionView *)collectionView frameOfItemInSectionAtIndexPath:(NSIndexPath *)indexPath sectionContentWidth:(CGFloat)inWidth {
    if (indexPath.section % 2 == 0) {
        return [self.layout1[indexPath.row] CGRectValue];
    } else if (indexPath.section % 2 == 1) {
        return [self.layout2[indexPath.row] CGRectValue];;
    } else {
        return CGRectZero;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return 10;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section % 2 == 0) {
        return self.layout1.count;
    } else if (section % 2 == 1) {
        return self.layout2.count;
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
