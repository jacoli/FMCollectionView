//
//  DefaultCollectionViewController.m
//  Examples
//
//  Created by 李传格 on 2017/8/4.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "DefaultCollectionViewController.h"

@interface DefaultCollectionViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation DefaultCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 5;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 5;
}

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    [collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:kind withReuseIdentifier:@"view"];
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"view" forIndexPath:indexPath];
    [view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UILabel *l = [[UILabel alloc] initWithFrame:view.bounds];
    l.text = [NSString stringWithFormat:@"%ld/%ld", indexPath.section, indexPath.row];
    l.textAlignment = NSTextAlignmentCenter;
    [view addSubview:l];
    view.backgroundColor = [UIColor greenColor];
    
    return view;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor grayColor];
    [cell.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UILabel *l = [[UILabel alloc] initWithFrame:cell.bounds];
    l.text = [NSString stringWithFormat:@"%ld/%ld", indexPath.section, indexPath.row];
    l.textAlignment = NSTextAlignmentCenter;
    [cell addSubview:l];
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(40, 10, 40, 10);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return 50;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(50, 20);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(50, 40);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - 100, 72);
    } else {
        if (indexPath.row % 3 == 0) {
            return CGSizeMake(100, 200);
        } else if (indexPath.row % 3 == 1) {
             return CGSizeMake(CGRectGetWidth(collectionView.frame) - 100, 72);
        } else {
            return CGSizeMake(150, 150);
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
