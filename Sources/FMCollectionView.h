//
//  FMCollectionView.h
//  tableviewdemo
//
//  Created by 李传格 on 2017/4/27.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FMCollectionView;

#pragma mark - Layouts

// Layout style of items in section
typedef NS_ENUM(NSInteger, FMSectionLayoutStyle) {
    FMSectionLayoutStyleRow = 0,
    FMSectionLayoutStyleColumnFlow,
    FMSectionLayoutStyleGrid,
    FMSectionLayoutStyleFrame
};

@protocol FMSectionRowLayout <NSObject>

@optional

- (CGFloat)heightAtIndexPath:(NSIndexPath *)indexPath forRowLayoutWithItemWidth:(CGFloat)itemWidth;

@end

@protocol FMSectionColumnFlowLayout <NSObject>

@optional

- (NSInteger)numberOfColumnsForColumnFlowLayoutInSection:(NSInteger)section;

- (CGFloat)heightAtIndexPath:(NSIndexPath *)indexPath forColumnFlowLayoutWithItemWidth:(CGFloat)itemWidth;

@end

@protocol FMSectionGridLayout <NSObject>

@optional

- (NSInteger)numberOfColumnsForGridLayoutInSection:(NSInteger)section;

- (CGFloat)heightInSection:(NSInteger)section forGridLayoutWithItemWidth:(CGFloat)itemWidth;

@end

@protocol FMSectionFrameLayout <NSObject>

@optional

- (CGRect)frameLayoutInCollectionView:(FMCollectionView *)collectionView frameOfItemInSectionAtIndexPath:(NSIndexPath *)indexPath sectionContentWidth:(CGFloat)inWidth;

@end

#pragma mark - Editing

typedef NS_ENUM(NSInteger, FMEditingControlsStyle) {
    FMEditingControlsStyleDelete = 0, // Default control style
    FMEditingControlsStyleCustom,
    FMEditingControlsStyleNone
};

@protocol FMCollectionViewEditingDelegate <NSObject>

@optional

- (FMEditingControlsStyle)collectionView:(FMCollectionView *)collectionView editingControlsStyleAtIndexPath:(NSIndexPath *)indexPath;

- (UIView *)collectionView:(FMCollectionView *)collectionView editingControlsAtIndexPath:(NSIndexPath *)indexPath containInSize:(CGSize)maxSize;

- (void)collectionView:(FMCollectionView *)collectionView didCommitEdit:(FMEditingControlsStyle)editType atIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark - DataSource

@protocol FMCollectionViewDataSource <NSObject>

@required

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView;

- (FMSectionLayoutStyle)collectionView:(FMCollectionView *)collectionView layoutInSection:(NSInteger)section;

- (UIEdgeInsets)collectionView:(FMCollectionView *)collectionView edgeInsetsOfSection:(NSInteger)section;

- (CGFloat)collectionView:(FMCollectionView *)collectionView itemsSpacingInSection:(NSInteger)section;

@end

@protocol FMCollectionViewDelegate <NSObject>

@optional

- (void)collectionView:(FMCollectionView *)collectionView didSelectAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark - Collection View

@protocol FMCollectionViewDelegatesAndDataSource
<FMCollectionViewDelegate,
FMCollectionViewDataSource,
FMSectionRowLayout,
FMSectionColumnFlowLayout,
FMSectionGridLayout,
FMSectionFrameLayout,
FMCollectionViewEditingDelegate>
@end

/**
 Collection of items, similar to UITableView and UICollectionView, support various layout style.
 */
@interface FMCollectionView : UIView

/**
 Delegates and datasources.
 */
@property (nonatomic, weak) id<FMCollectionViewDelegatesAndDataSource> delegatesAndDataSource;

/**
 Real container of items, must not change contentSize or frame of scroll view outside, others at will.
 */
@property (nonatomic, strong, readonly) UIScrollView *scrollView;

/**
 Spacing between sections, default is zero.
 */
@property (nonatomic, assign) CGFloat sectionsSpacing;

/**
 Edge insets of section, default is zero.
 */
@property (nonatomic, assign) UIEdgeInsets sectionEdgeInsets;

/**
 Spacing between items, default is zero.
 */
@property (nonatomic, assign) CGFloat itemsSpacing;

/**
 Height of items, default is 48pt.
 */
@property (nonatomic, assign) CGFloat itemHeight;

/**
 Decorations.
 */
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;

/**
 Items editing mode, default is NO. Protocol `FMCollectionViewEditingDelegate` will called if `editingMode` set YES.
 */
@property (nonatomic, assign) BOOL editingMode;

/**
 Prefetch items beyond visible rect, default is 128pt.
 */
@property (nonatomic, assign) CGFloat prefetchInsets;

/**
 Return a reusable item, or a created with `itemClass`.
 */
- (__kindof UIView *)dequeueReusableItemWithId:(NSString *)reuseId atIndexPath:(NSIndexPath *)indexPath itemClass:(Class)itemClass;
- (__kindof UIView *)dequeueReusableItemWithId:(NSString *)reuseId itemClass:(Class)itemClass;

/**
 Invalidate and reload all items.
 */
- (void)reloadItems;

// TODO not implemented
- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

// TODO not implemented
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

/**
 Return count of items.
 */
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

@end
