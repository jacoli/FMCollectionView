//
//  FMCollectionView.m
//  tableviewdemo
//
//  Created by 李传格 on 2017/4/27.
//  Copyright © 2017年 fanmei. All rights reserved.
//

#import "FMCollectionView.h"
#import <objc/runtime.h>

#define FMCollectionViewDebug (0)

typedef NS_ENUM(NSInteger, FMBottomRefleshStatus) {
    FMBottomRefleshStatusNone = 0,
    FMBottomRefleshStatusLoading,
    FMBottomRefleshStatusLoadFailed,
    FMBottomRefleshStatusEnd
};

#define SectionHeaderIndex (-1)

@interface FMCollectionItemModel : NSObject

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) NSIndexPath *indexPath; // indexPath.row == SectionHeaderIndex means header item

+ (instancetype)itemModelWithFrame:(CGRect)frame atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FMCollectionItemModel

+ (instancetype)itemModelWithFrame:(CGRect)frame atIndexPath:(NSIndexPath *)indexPath {
    FMCollectionItemModel *model = [[FMCollectionItemModel alloc] init];
    model.frame = frame;
    model.indexPath = indexPath;
    return model;
}

@end

@interface UIView (FMCollectionView)

@property (nonatomic, strong) NSString *fmc_reuseId;
@property (nonatomic, strong) NSIndexPath *fmc_indexPath;
@property (nonatomic, assign) CGRect fmc_itemOriginalFrame;

@end

@implementation UIView (FMCollectionView)

static int kfmc_reuseId;
- (void)setFmc_reuseId:(NSString *)fmc_reuseId {
    objc_setAssociatedObject(self, &kfmc_reuseId, fmc_reuseId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fmc_reuseId {
    return objc_getAssociatedObject(self, &kfmc_reuseId);
}

static int kfmc_indexPath;
- (void)setFmc_indexPath:(NSIndexPath *)fmc_indexPath {
    objc_setAssociatedObject(self, &kfmc_indexPath, fmc_indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)fmc_indexPath {
    return objc_getAssociatedObject(self, &kfmc_indexPath);
}

static int kfmc_itemOriginalFrame;
- (CGRect)fmc_itemOriginalFrame {
    NSValue *value = objc_getAssociatedObject(self, &kfmc_itemOriginalFrame);
    return value ? [value CGRectValue] : CGRectZero;
}

- (void)setFmc_itemOriginalFrame:(CGRect)fmc_itemOriginalFrame {
    objc_setAssociatedObject(self, &kfmc_itemOriginalFrame, [NSValue valueWithCGRect:fmc_itemOriginalFrame], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface FMCollectionView () <UIGestureRecognizerDelegate>

// containers
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableDictionary *reusableItems; // Key is reused id, value is array of items.
@property (nonatomic, strong) NSMutableArray *visibleItems;

// layouts
@property (nonatomic, assign) CGRect headerRect;
@property (nonatomic, assign) CGRect contentRect;
@property (nonatomic, assign) CGRect footerRect;
@property (nonatomic, strong) NSMutableArray *itemLayouts;

// edit
@property (nonatomic, strong) UIPanGestureRecognizer *editingGesture;
@property (nonatomic, strong) UIView *editingItem;
@property (nonatomic, strong) UIView *editingControls;

// bottom reflesh
@property (nonatomic, assign) BOOL bottomRefleshEnabled;
@property (nonatomic, copy) void(^loadMoreCallback)(void);
@property (nonatomic, copy) BOOL(^hasMoreCallback)(void);
@property (nonatomic, assign) NSInteger bottomRefleshingPreloadThreshold;
@property (nonatomic, assign) FMBottomRefleshStatus bottomRefleshStatus;
@property (nonatomic, assign) CGFloat bottomInsetCustom;
@property (nonatomic, assign) CGFloat bottomRefleshViewDefaultHeight;

@end

@implementation FMCollectionView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupDefaults];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults {
    self.reusableItems = [[NSMutableDictionary alloc] init];
    self.visibleItems = [[NSMutableArray alloc] init];
    self.itemLayouts = [[NSMutableArray alloc] init];
    
    self.prefetchInsets = 128;
    self.itemHeight = 48;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    
    UITapGestureRecognizer *selectionTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
    [self addGestureRecognizer:selectionTapGR];
    
    self.bottomRefleshingPreloadThreshold = 2;
    self.bottomRefleshStatus = FMBottomRefleshStatusNone;
    self.bottomRefleshViewDefaultHeight = 100.f;
}

- (void)dealloc {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)didMoveToSuperview {
    [self reloadItems];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.backgroundView.frame)) {
        self.backgroundView.frame = self.bounds;
    }
    
    if (CGRectEqualToRect(self.bounds, self.scrollView.frame)) {
        [self layout];
    } else {
        self.scrollView.frame = self.bounds;
        [self reloadItems];
    }
}

#pragma mark - Selection

- (UIView *)findVisibleItemContainsPoint:(CGPoint)pt {
    for (UIView *v in self.visibleItems) {
        if (CGRectContainsPoint(v.frame, pt)) {
            return v;
        }
    }
    return nil;
}

- (void)onTapGesture:(UITapGestureRecognizer *)gesture {
    CGPoint pt = [gesture locationInView:self.scrollView];
    
#if FMCollectionViewDebug
    NSLog(@"{FMCollectionView} : onTapGesture pt = {%f, %f}", pt.x, pt.y);
#endif
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        {
            UIView *item = [self findVisibleItemContainsPoint:pt];
            if (item) {
                [self onSelected:item];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

- (void)onSelected:(UIView *)item {
    if (item && item.fmc_indexPath.row != SectionHeaderIndex) {
#if FMCollectionViewDebug
        NSLog(@"{FMCollectionView} : item(%@/%@) did selected", @(item.fmc_indexPath.section), @(item.fmc_indexPath.row));
#endif
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:didSelectAtIndexPath:)]) {
            [self.delegatesAndDataSource collectionView:self didSelectAtIndexPath:item.fmc_indexPath];
        }
    }
}

#pragma mark - Editing

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.editingGesture]) {
        if (self.editingItem) {
            return YES;
        } else {
            CGFloat movedX = [self.editingGesture translationInView:self].x;
            BOOL isMovingDirectionToRight = movedX > 0;
            return !isMovingDirectionToRight;
        }
    }
    
    return YES;
}

- (void)enableEditing {
    if (!self.editingGesture) {
        self.editingGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
        self.editingGesture.delegate = self;
        [self addGestureRecognizer:self.editingGesture];
    }
}

- (void)disableEditing {
    if (self.editingGesture) {
        [self removeGestureRecognizer:self.editingGesture];
        self.editingGesture = nil;
        [self cleanEditingItemAndControlsAnimated:NO];
    }
}

- (void)cleanEditingItemAndControlsAnimated:(BOOL)animated {
    if (self.editingItem) {
        if (animated) {
            UIView *editingItem = self.editingItem;
            UIView *editingControls = self.editingControls;
            self.editingItem = nil;
            self.editingControls = nil;
            [UIView animateWithDuration:0.3 animations:^{
                editingItem.frame = editingItem.fmc_itemOriginalFrame;
            } completion:^(BOOL finished) {
                [editingControls removeFromSuperview];
            }];
        } else {
            self.editingItem.frame = self.editingItem.fmc_itemOriginalFrame;
            [self.editingControls removeFromSuperview];
            self.editingItem = nil;
            self.editingControls = nil;
        }
    }
}

- (BOOL)canEditForItem:(UIView *)item {
    if (item && item.fmc_indexPath.row != SectionHeaderIndex) {
        FMEditingControlsStyle style = FMEditingControlsStyleDelete;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:editingControlsStyleAtIndexPath:)]) {
            style = [self.delegatesAndDataSource collectionView:self editingControlsStyleAtIndexPath:item.fmc_indexPath];
        }
        return style != FMEditingControlsStyleNone;
    }
    return NO;
}

- (void)onDefaultDeleteEdit:(UIButton *)btn {
    if (self.editingItem) {
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:didCommitEdit:atIndexPath:)]) {
            [self.delegatesAndDataSource collectionView:self didCommitEdit:FMEditingControlsStyleDelete atIndexPath:self.editingItem.fmc_indexPath];
        }
    }
}

- (void)prepareEditingControlsForEditingItem {
    if (!self.editingItem) {
        return;
    }
    UIView *item = self.editingItem;
    
    [self.editingControls removeFromSuperview];
    self.editingControls = nil;
    
    FMEditingControlsStyle style = FMEditingControlsStyleDelete;
    if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:editingControlsStyleAtIndexPath:)]) {
        style = [self.delegatesAndDataSource collectionView:self editingControlsStyleAtIndexPath:self.editingItem.fmc_indexPath];
    }
    
    if (style == FMEditingControlsStyleDelete) {
        CGFloat deleteBtnWidth = 66;
        UIButton *defaultDeleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        defaultDeleteBtn.frame = CGRectMake(0, 0, deleteBtnWidth, CGRectGetHeight(item.frame));
        defaultDeleteBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [defaultDeleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [defaultDeleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [defaultDeleteBtn setBackgroundColor:[UIColor redColor]];
        [defaultDeleteBtn addTarget:self action:@selector(onDefaultDeleteEdit:) forControlEvents:UIControlEventTouchUpInside];
        self.editingControls = defaultDeleteBtn;
    } else if (style == FMEditingControlsStyleCustom) {
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:editingControlsAtIndexPath:containInSize:)]) {
            self.editingControls = [self.delegatesAndDataSource collectionView:self editingControlsAtIndexPath:item.fmc_indexPath containInSize:item.frame.size];
        }
    }
    
    if (self.editingControls) {
        self.editingControls.frame = CGRectMake(CGRectGetMaxX(item.frame) - CGRectGetWidth(self.editingControls.frame), CGRectGetMinY(item.frame), CGRectGetWidth(self.editingControls.frame), CGRectGetHeight(self.editingControls.frame));
        [self.scrollView insertSubview:self.editingControls belowSubview:item];
    }
}

- (void)layoutItemToEdtingStateAnimated {
    if (self.editingItem && self.editingControls) {
        CGRect rect = self.editingItem.fmc_itemOriginalFrame;
        rect.origin.x -= CGRectGetWidth(self.editingControls.frame);
        [UIView animateWithDuration:0.3 animations:^{
            self.editingItem.frame = rect;
        } completion:nil];
    }
}

- (void)onPanGesture:(UIPanGestureRecognizer *)gesture {
    CGFloat movedX = [gesture translationInView:self].x;

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint pt = [gesture locationInView:self.scrollView];
            UIView *item = [self findVisibleItemContainsPoint:pt];
            if (item && [self canEditForItem:item]) {
                if (self.editingItem) {
                    [self cleanEditingItemAndControlsAnimated:YES];
                } else {
                    self.editingItem = item;
                    self.editingItem.fmc_itemOriginalFrame = self.editingItem.frame;
                    [self prepareEditingControlsForEditingItem];
                }
            } else {
                 [self cleanEditingItemAndControlsAnimated:YES];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
            if (self.editingItem) {
                CGRect rect = self.editingItem.fmc_itemOriginalFrame;
                rect.origin.x += MIN(movedX, 0);
                self.editingItem.frame = rect;
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if (self.editingItem) {
                if (self.editingControls) {
                    CGFloat percent = movedX / CGRectGetWidth(self.editingControls.bounds);
                    
                    if (percent < -0.7) {
                        [self layoutItemToEdtingStateAnimated];
                    }
                    else if (percent > -0.3) {
                        [self cleanEditingItemAndControlsAnimated:YES];
                    }
                    else {
                        CGFloat velocity = [gesture velocityInView:self].x;
                        
                        CGFloat velocityThreshold = 100;
                        if (velocity < -velocityThreshold) {
                            [self layoutItemToEdtingStateAnimated];
                        }
                        else {
                            [self cleanEditingItemAndControlsAnimated:YES];
                        }
                    }
                } else {
                    [self cleanEditingItemAndControlsAnimated:YES];
                }
            }
            break;
        default:
            break;
    }
}

#pragma mark - Layouts

- (void)layoutHeader:(CGRect)visibleRect {
    if (self.headerView) {
        if (CGRectIntersectsRect(self.headerRect, visibleRect)) {
            if (!self.headerView.superview) {
                self.headerView.frame = self.headerRect;
                [self.scrollView insertSubview:self.headerView atIndex:0];
            }
        } else {
            if (self.headerView.superview) {
                [self.headerView removeFromSuperview];
            }
        }
    }
}

- (void)layoutFooter:(CGRect)visibleRect {
    if (self.footerView) {
        if (CGRectIntersectsRect(self.footerRect, visibleRect)) {
            if (!self.footerView.superview) {
                self.footerView.frame = self.footerRect;
                [self.scrollView insertSubview:self.footerView atIndex:0];
            }
        } else {
            if (self.footerView.superview) {
                [self.footerView removeFromSuperview];
            }
        }
    }
}

- (void)removeItem:(UIView *)item ifOutOfRect:(CGRect)visibleRect {
    if (item) {
        if (!CGRectIntersectsRect(visibleRect, item.frame)) {
#if FMCollectionViewDebug
            NSLog(@"{FMCollectionView} : item(%@/%@) will dismiss", @(item.fmc_indexPath.section), @(item.fmc_indexPath.row));
#endif
            [item removeFromSuperview];
            [self.visibleItems removeObject:item];
            [self __enqueueItemForReuse:item];
            
            if ([item isEqual:self.editingItem]) {
                [self cleanEditingItemAndControlsAnimated:NO];
            }
        }
    }
}

- (void)addItem:(UIView *)item ofModel:(FMCollectionItemModel *)model {
    if (item) {
        item.frame = model.frame;
        item.fmc_indexPath = model.indexPath;
        [self.scrollView insertSubview:item atIndex:0];
        [self.visibleItems addObject:item];
        
#if FMCollectionViewDebug
        NSLog(@"{FMCollectionView} : item(%@/%@) will show", @(model.indexPath.section), @(model.indexPath.row));
#endif
    }
}

- (BOOL)isVisibleWithModel:(FMCollectionItemModel *)model {
    BOOL isShowed = NO;
    for (UIView *v in self.visibleItems) {
        if ([v.fmc_indexPath isEqual:model.indexPath]) {
            isShowed = YES;
            break;
        }
    }
    return isShowed;
}

- (UIView *)fetchViewFromDataSourceWithModel:(FMCollectionItemModel *)model {
    if (model.indexPath.row == SectionHeaderIndex) {
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:headerAtSection:)]) {
            return [self.delegatesAndDataSource collectionView:self headerAtSection:model.indexPath.section];
        } else {
            return nil;
        }
    } else {
        [self triggerBottomRefleshingIfNeed:model.indexPath];
        return [self.delegatesAndDataSource collectionView:self itemAtIndexPath:model.indexPath];
    }
}

- (void)layoutItems:(CGRect)visibleRect {
    if (self.visibleItems.count == 0) {
        for (FMCollectionItemModel *model in self.itemLayouts) {
            if (CGRectIntersectsRect(visibleRect, model.frame)) {
                [self addItem:[self fetchViewFromDataSourceWithModel:model] ofModel:model];
            }
        }
    } else {
        [self removeItem:self.visibleItems.firstObject ifOutOfRect:visibleRect];
        [self removeItem:self.visibleItems.lastObject ifOutOfRect:visibleRect];
        for (FMCollectionItemModel *model in self.itemLayouts) {
            if (CGRectIntersectsRect(visibleRect, model.frame) && ![self isVisibleWithModel:model]) {
                [self addItem:[self fetchViewFromDataSourceWithModel:model] ofModel:model];
            }
        }
    }
}

- (void)layout {
    CGRect visibleRect = CGRectMake(self.scrollView.contentOffset.x,
                                    self.scrollView.contentOffset.y - self.prefetchInsets,
                                    CGRectGetWidth(self.scrollView.frame),
                                    CGRectGetHeight(self.scrollView.frame) + self.prefetchInsets * 2);
    
    [self layoutHeader:visibleRect];
    [self layoutItems:visibleRect];
    [self layoutFooter:visibleRect];
    
    // scroll view content size
    CGFloat contentHeight = CGRectGetHeight(self.headerRect) + CGRectGetHeight(self.contentRect) + CGRectGetHeight(self.footerRect);
    CGSize scrollViewContentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), contentHeight);
    if (!CGSizeEqualToSize(scrollViewContentSize, self.scrollView.contentSize)) {
        self.scrollView.contentSize = scrollViewContentSize;
    }
}

- (void)cleanItems {
    for (UIView *item in self.visibleItems) {
#if FMCollectionViewDebug
        NSLog(@"{FMCollectionView} : item(%@/%@) will dismiss", @(item.fmc_indexPath.section), @(item.fmc_indexPath.row));
#endif
        [self __enqueueItemForReuse:item];
    }
    
    [self.visibleItems makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleItems removeAllObjects];
    
    [self cleanEditingItemAndControlsAnimated:NO];
}

- (void)cleanItemsAndLayout {
    [self cleanItems];
    [self layout];
}

#pragma mark - Measure

- (CGFloat)measureSectionHeaderInSection:(NSInteger)section
                               yBaseline:(CGFloat)yBaseline
                   andAddResultToLayouts:(inout NSMutableArray *)layouts {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:headerHeightAtSection:)]) {
        CGFloat headerHeight = [self.delegatesAndDataSource collectionView:self headerHeightAtSection:section];
        if (headerHeight > 0) {
            CGRect absFrame = CGRectMake(0, yBaseline, CGRectGetWidth(self.scrollView.frame), headerHeight);
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SectionHeaderIndex inSection:section];
            [layouts addObject:[FMCollectionItemModel itemModelWithFrame:absFrame atIndexPath:indexPath]];
            return yBaseline + headerHeight;
        }
    }
    
    return yBaseline;
}

- (CGFloat)measureRowLayoutInSection:(NSInteger)section
                   withSectionInsets:(UIEdgeInsets)sectionInsets
                        itemsSpacing:(CGFloat)itemsSpacing
                           yBaseline:(CGFloat)yBaseline
               andAddResultToLayouts:(inout NSMutableArray *)layouts {
    NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    
    CGFloat itemWidth = CGRectGetWidth(self.scrollView.frame) - sectionInsets.left - sectionInsets.right;
    CGPoint offset = CGPointMake(sectionInsets.left, yBaseline + sectionInsets.top);
    
    for (NSInteger index = 0; index < numberOfItemsInSection; ++index) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
        CGFloat itemHeight = self.itemHeight;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(heightAtIndexPath:forRowLayoutWithItemWidth:)]) {
            itemHeight = [self.delegatesAndDataSource heightAtIndexPath:indexPath forRowLayoutWithItemWidth:itemWidth];
        }
        CGRect absFrame = CGRectMake(offset.x, offset.y, itemWidth, itemHeight);
        [layouts addObject:[FMCollectionItemModel itemModelWithFrame:absFrame atIndexPath:indexPath]];
        offset.y = CGRectGetMaxY(absFrame);
        
        BOOL isLastItem = (index == numberOfItemsInSection - 1);
        if (!isLastItem) {
            offset.y += itemsSpacing;
        }
    }
    
    return offset.y + sectionInsets.bottom;
}

- (CGFloat)measureColumnFlowLayoutInSection:(NSInteger)section
                          withSectionInsets:(UIEdgeInsets)sectionInsets
                               itemsSpacing:(CGFloat)itemsSpacing
                                  yBaseline:(CGFloat)yBaseline
                      andAddResultToLayouts:(inout NSMutableArray *)layouts {
    NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    
    NSInteger numberOfColumns = 2;
    if ([self.delegatesAndDataSource respondsToSelector:@selector(numberOfColumnsForColumnFlowLayoutInSection:)]) {
        numberOfColumns = [self.delegatesAndDataSource numberOfColumnsForColumnFlowLayoutInSection:section];
    }
    
    if (numberOfColumns <= 0) {
        return yBaseline;
    }
    
    CGFloat sectionWidth = (CGRectGetWidth(self.scrollView.frame) - sectionInsets.left - sectionInsets.right);
    CGFloat itemWidth = (sectionWidth - itemsSpacing * (numberOfColumns - 1)) / numberOfColumns;
    
    NSMutableArray *columnBaseOffsets = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
    for (NSInteger idx = 0; idx < numberOfColumns; ++idx) {
        CGPoint offset = CGPointMake(sectionInsets.left + (itemWidth + itemsSpacing) * idx, yBaseline + sectionInsets.top);
        [columnBaseOffsets addObject:[NSValue valueWithCGPoint:offset]];
    }
    
    for (NSInteger itemIndex = 0; itemIndex < numberOfItemsInSection; ++itemIndex) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:itemIndex inSection:section];
        CGFloat height = self.itemHeight;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(heightAtIndexPath:forColumnFlowLayoutWithItemWidth:)]) {
            height = [self.delegatesAndDataSource heightAtIndexPath:indexPath forColumnFlowLayoutWithItemWidth:itemWidth];
        }
        
        BOOL isLastItem = (itemIndex == numberOfItemsInSection - 1);
        
        NSInteger minBaseOffsetIndex = 0;
        CGPoint minBaseOffset = [columnBaseOffsets[minBaseOffsetIndex] CGPointValue];
        for (NSInteger idx = 1; idx < columnBaseOffsets.count; ++idx) {
            CGPoint temp = [columnBaseOffsets[idx] CGPointValue];
            if (temp.y < minBaseOffset.y) {
                minBaseOffset = temp;
                minBaseOffsetIndex = idx;
            }
        }
        
        CGRect absFrame = CGRectMake(minBaseOffset.x, minBaseOffset.y, itemWidth, height);
        CGFloat newBaseLine = CGRectGetMaxY(absFrame) + (isLastItem ? 0 : itemsSpacing);
        columnBaseOffsets[minBaseOffsetIndex] = [NSValue valueWithCGPoint:CGPointMake(minBaseOffset.x, newBaseLine)];
        
        [layouts addObject:[FMCollectionItemModel itemModelWithFrame:absFrame atIndexPath:indexPath]];
    }
    
    CGFloat maxY = [columnBaseOffsets[0] CGPointValue].y;
    for (NSInteger idx = 1; idx < columnBaseOffsets.count; ++idx) {
        CGFloat temp = [columnBaseOffsets[idx] CGPointValue].y;
        maxY = MAX(temp, maxY);
    }
    
    return maxY + sectionInsets.bottom;
}

- (CGFloat)measureGirdLayoutInSection:(NSInteger)section
                    withSectionInsets:(UIEdgeInsets)sectionInsets
                         itemsSpacing:(CGFloat)itemsSpacing
                            yBaseline:(CGFloat)yBaseline
                andAddResultToLayouts:(inout NSMutableArray *)layouts {
    NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    
    NSInteger numberOfColumns = 2;
    if ([self.delegatesAndDataSource respondsToSelector:@selector(numberOfColumnsForGridLayoutInSection:)]) {
        numberOfColumns = [self.delegatesAndDataSource numberOfColumnsForGridLayoutInSection:section];
    }
    
    if (numberOfColumns <= 0) {
        return yBaseline;
    }
    
    CGFloat sectionWidth = (CGRectGetWidth(self.scrollView.frame) - sectionInsets.left - sectionInsets.right);
    CGFloat itemWidth = (sectionWidth - itemsSpacing * (numberOfColumns - 1)) / numberOfColumns;
    CGFloat itemHeight = self.itemHeight;
    if ([self.delegatesAndDataSource respondsToSelector:@selector(heightInSection:forGridLayoutWithItemWidth:)]) {
        itemHeight = [self.delegatesAndDataSource heightInSection:section forGridLayoutWithItemWidth:itemWidth];
    }
    CGPoint offset = CGPointMake(sectionInsets.left, yBaseline + sectionInsets.top);
    CGFloat yBottomLine = offset.y;
    
    for (NSInteger index = 0; index < numberOfItemsInSection; ++index) {
        NSInteger column = index % numberOfColumns;
        NSInteger row = floor((double)index / (double)numberOfColumns);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
        CGRect absFrame = CGRectMake(offset.x + column * (itemWidth + itemsSpacing),
                                     offset.y + row * (itemHeight + itemsSpacing),
                                     itemWidth,
                                     itemHeight);
        [layouts addObject:[FMCollectionItemModel itemModelWithFrame:absFrame atIndexPath:indexPath]];
        yBottomLine = MAX(yBottomLine, CGRectGetMaxY(absFrame));
    }
    
    return yBottomLine + sectionInsets.bottom;
}

- (CGFloat)measureFrameLayoutInSection:(NSInteger)section
                     withSectionInsets:(UIEdgeInsets)sectionInsets
                          itemsSpacing:(CGFloat)itemsSpacing
                             yBaseline:(CGFloat)yBaseline
                 andAddResultToLayouts:(inout NSMutableArray *)layouts {
    NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    
    CGFloat sectionWidth = (CGRectGetWidth(self.scrollView.frame) - sectionInsets.left - sectionInsets.right);
    CGPoint offset = CGPointMake(sectionInsets.left, yBaseline + sectionInsets.top);
    CGFloat yBottomLine = offset.y;
    
    for (NSInteger rowIndex = 0; rowIndex < numberOfItemsInSection; ++rowIndex) {
        if ([self.delegatesAndDataSource respondsToSelector:@selector(frameLayoutInCollectionView:frameOfItemInSectionAtIndexPath:sectionContentWidth:)]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:section];
            CGRect frame = [self.delegatesAndDataSource frameLayoutInCollectionView:self frameOfItemInSectionAtIndexPath:indexPath sectionContentWidth:sectionWidth];
            CGRect absFrame = CGRectMake(offset.x + frame.origin.x,
                                         offset.y + frame.origin.y,
                                         frame.size.width,
                                         frame.size.height);
            [layouts addObject:[FMCollectionItemModel itemModelWithFrame:absFrame atIndexPath:indexPath]];
            yBottomLine = MAX(yBottomLine, CGRectGetMaxY(absFrame));
        }
    }
    
    return yBottomLine + sectionInsets.bottom;
}

- (CGFloat)measureItemsInLineForFlowLayout:(NSArray *)itemsInLine
                                    offset:(CGPoint)offset
                              sectionWidth:(CGFloat)sectionWidth
                     andAddResultToLayouts:(inout NSMutableArray *)layouts {
    if (itemsInLine.count == 1) {
        FMCollectionItemModel *model = itemsInLine[0];
        model.frame = CGRectMake(offset.x + (sectionWidth - CGRectGetWidth(model.frame)) / 2,
                                 offset.y,
                                 CGRectGetWidth(model.frame),
                                 CGRectGetHeight(model.frame));
        [layouts addObject:model];
        return offset.y + CGRectGetHeight(model.frame);
    }
    else if (itemsInLine.count > 1) {
        CGFloat maxHeight = 0;
        CGFloat itemTotalWidth = 0;
        for (FMCollectionItemModel *model in itemsInLine) {
            maxHeight = MAX(maxHeight, CGRectGetHeight(model.frame));
            itemTotalWidth += CGRectGetWidth(model.frame);
        }
        CGFloat margin = (sectionWidth - itemTotalWidth) / (itemsInLine.count - 1);
        
        for (NSInteger i = 0; i < itemsInLine.count; ++i) {
            FMCollectionItemModel *model = itemsInLine[i];
            model.frame = CGRectMake(offset.x,
                                     offset.y + (maxHeight - CGRectGetHeight(model.frame)) / 2,
                                     CGRectGetWidth(model.frame),
                                     CGRectGetHeight(model.frame));
            [layouts addObject:model];
            offset.x = CGRectGetMaxX(model.frame) + margin;
        }
        return offset.y + maxHeight;
    } else {
        return offset.y;
    }
}

- (CGFloat)measureFlowLayoutInSection:(NSInteger)section
                    withSectionInsets:(UIEdgeInsets)sectionInsets
                         itemsSpacing:(CGFloat)itemsSpacing
                            yBaseline:(CGFloat)yBaseline
                andAddResultToLayouts:(inout NSMutableArray *)layouts {
    NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    
    CGFloat sectionWidth = (CGRectGetWidth(self.scrollView.frame) - sectionInsets.left - sectionInsets.right);
    CGFloat yBottomLine = yBaseline + sectionInsets.top;
    
    NSMutableArray *itemsInLine = [[NSMutableArray alloc] init];
    CGFloat offset = 0;
    for (NSInteger rowIndex = 0; rowIndex < numberOfItemsInSection; ++rowIndex) {
        CGSize itemSize = CGSizeMake(self.itemHeight, self.itemHeight);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:section];
        if ([self.delegatesAndDataSource respondsToSelector:@selector(sizeAtIndexPath:forFlowLayoutWithSectionWidth:)]) {
            itemSize = [self.delegatesAndDataSource sizeAtIndexPath:indexPath forFlowLayoutWithSectionWidth:sectionWidth];
        }
        
        if (offset + itemSize.width > sectionWidth) {
            // last line
            yBottomLine = [self measureItemsInLineForFlowLayout:itemsInLine offset:CGPointMake(sectionInsets.left, yBottomLine) sectionWidth:sectionWidth andAddResultToLayouts:layouts];
            yBottomLine += itemsSpacing;
            [itemsInLine removeAllObjects];
            
            // new line
            offset = itemSize.width + itemsSpacing;
        } else {
            // next item
            offset += itemSize.width + itemsSpacing;
        }
        
        [itemsInLine addObject:[FMCollectionItemModel itemModelWithFrame:CGRectMake(0, 0, itemSize.width, itemSize.height) atIndexPath:indexPath]];
    }
    
    yBottomLine = [self measureItemsInLineForFlowLayout:itemsInLine offset:CGPointMake(sectionInsets.left, yBottomLine) sectionWidth:sectionWidth andAddResultToLayouts:layouts];
    
    return yBottomLine + sectionInsets.bottom;
}

- (void)measureContentWithHeaderRect:(CGRect)headerRect {
    NSMutableArray *itemLayouts = [[NSMutableArray alloc] init];
    
    NSInteger numberOfSections = 1;
    if ([self.delegatesAndDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        numberOfSections = [self.delegatesAndDataSource numberOfSectionsInCollectionView:self];
    }
    
    CGFloat contentMaxY = CGRectGetMaxY(headerRect);
    
    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex) {
        // FIX: If number of items is zero, fast return, don't show this section.
        NSInteger numberOfItemsInSection = [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:sectionIndex];
        if (numberOfItemsInSection <= 0) {
            continue;
        }
        
        contentMaxY = [self measureSectionHeaderInSection:sectionIndex yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        
        CGFloat sectionsSpacing = self.sectionsSpacing;
        UIEdgeInsets sectionInsets = self.sectionEdgeInsets;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:edgeInsetsOfSection:)]) {
            sectionInsets = [self.delegatesAndDataSource collectionView:self edgeInsetsOfSection:sectionIndex];
        }
        CGFloat itemsSpacing = self.itemsSpacing;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:itemsSpacingInSection:)]) {
            itemsSpacing = [self.delegatesAndDataSource collectionView:self itemsSpacingInSection:sectionIndex];
        }
        FMSectionLayoutStyle sectionLayout = FMSectionLayoutStyleRow;
        if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:layoutInSection:)]) {
            sectionLayout = [self.delegatesAndDataSource collectionView:self layoutInSection:sectionIndex];
        }
        
        if (sectionLayout == FMSectionLayoutStyleColumnFlow) {
            contentMaxY = [self measureColumnFlowLayoutInSection:sectionIndex withSectionInsets:sectionInsets itemsSpacing:itemsSpacing yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        } else if (sectionLayout == FMSectionLayoutStyleGrid) {
            contentMaxY = [self measureGirdLayoutInSection:sectionIndex withSectionInsets:sectionInsets itemsSpacing:itemsSpacing yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        } else if (sectionLayout == FMSectionLayoutStyleFrame) {
            contentMaxY = [self measureFrameLayoutInSection:sectionIndex withSectionInsets:sectionInsets itemsSpacing:itemsSpacing yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        } else if (sectionLayout == FMSectionLayoutStyleFlow) {
            contentMaxY = [self measureFlowLayoutInSection:sectionIndex withSectionInsets:sectionInsets itemsSpacing:itemsSpacing yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        } else {
            contentMaxY = [self measureRowLayoutInSection:sectionIndex withSectionInsets:sectionInsets itemsSpacing:itemsSpacing yBaseline:contentMaxY andAddResultToLayouts:itemLayouts];
        }
        
        BOOL isLastSection = (sectionIndex == numberOfSections - 1);
        if (!isLastSection) {
            contentMaxY += sectionsSpacing;
        }
    }
    
    self.itemLayouts = itemLayouts;
    self.contentRect = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), contentMaxY);
}

- (void)measureHeader {
    if (self.headerView) {
        self.headerRect = CGRectMake(CGRectGetMidX(self.scrollView.bounds) - CGRectGetMidX(self.headerView.bounds),
                                     0,
                                     CGRectGetWidth(self.headerView.frame),
                                     CGRectGetHeight(self.headerView.frame));
    } else {
        self.headerRect = CGRectZero;
    }
}

- (void)measureFooterWithContentRect:(CGRect)contentRect {
    if (self.footerView) {
        self.footerRect = CGRectMake(CGRectGetMidX(self.scrollView.bounds) - CGRectGetMidX(self.footerView.bounds),
                                       CGRectGetMaxY(contentRect),
                                       CGRectGetWidth(self.footerView.frame),
                                       CGRectGetHeight(self.footerView.frame));
    } else {
        self.footerRect = CGRectZero;
    }
}

- (void)measure {
    [self measureHeader];
    [self measureContentWithHeaderRect:self.headerRect];
    [self measureFooterWithContentRect:self.contentRect];
}

#pragma mark - Reuse

- (void)__enqueueItemForReuse:(UIView *)item {
    if (item.fmc_reuseId.length > 0) {
        NSMutableArray *reusableItems = self.reusableItems[item.fmc_reuseId];
        if (!reusableItems) {
            reusableItems = [[NSMutableArray alloc] init];
            self.reusableItems[item.fmc_reuseId] = reusableItems;
        }
        [reusableItems addObject:item];
    }
}

- (__kindof UIView *)__dequeueReusableItemWithId:(NSString *)reuseId atIndexPath:(NSIndexPath *)indexPath itemClass:(Class)itemClass {
    if (reuseId.length > 0) {
        NSMutableArray *reusableItems = self.reusableItems[reuseId];
        if (reusableItems.count > 0) {
            if (indexPath) {
                for (UIView *reusableItem in reusableItems) {
                    if ([reusableItem.fmc_indexPath isEqual:indexPath]) {
                        UIView *item = reusableItem;
                        [reusableItems removeObject:reusableItem];
                        return item;
                    }
                }
            }
            
            UIView *item = [reusableItems lastObject];
            [reusableItems removeLastObject];
            return item;
        }
    }
    
    if (itemClass) {
        UIView *item = [[itemClass alloc] init];
        if ([item isKindOfClass:UIView.class]) {
            item.fmc_reuseId = reuseId;
            item.fmc_indexPath = indexPath;
        }
        return item;
    }
    
    return nil;
}

#pragma mark - Public methods

- (void)setEditingMode:(BOOL)editingMode {
    if (editingMode) {
        [self enableEditing];
    } else {
        [self disableEditing];
    }
    _editingMode = editingMode;
}

- (__kindof UIView *)dequeueReusableItemWithId:(NSString *)reuseId atIndexPath:(NSIndexPath *)indexPath itemClass:(Class)itemClass {
    return [self __dequeueReusableItemWithId:reuseId atIndexPath:indexPath itemClass:itemClass];
}

- (__kindof UIView *)dequeueReusableItemWithId:(NSString *)reuseId itemClass:(Class)itemClass {
    return [self __dequeueReusableItemWithId:reuseId atIndexPath:nil itemClass:itemClass];
}

- (void)reloadItems {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.delegatesAndDataSource) {
            [weakSelf endBottomRefleshing:YES];
            [weakSelf measure];
            [weakSelf cleanItemsAndLayout];
        }
    });
}

// TODO not implemented
- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {}

// TODO not implemented
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {}

- (void)setBackgroundView:(UIView *)backgroundView {
    if (_backgroundView.superview) {
        [_backgroundView removeFromSuperview];
    }
    _backgroundView = backgroundView;
    
    if (backgroundView) {
        [self.scrollView insertSubview:backgroundView atIndex:0];
    }
    
    [self setNeedsLayout];
}

- (void)setHeaderView:(UIView *)headerView {
    if (_headerView.superview) {
        [_headerView removeFromSuperview];
    }
    _headerView = headerView;
    [self measure];
    [self setNeedsLayout];
}

- (void)setFooterView:(UIView *)footerView {
    if (_footerView.superview) {
        [_footerView removeFromSuperview];
    }
    _footerView = footerView;
    [self measureFooterWithContentRect:self.contentRect];
    [self setNeedsLayout];
}

- (NSInteger)numberOfSections {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        return [self.delegatesAndDataSource numberOfSectionsInCollectionView:self];
    } else {
        return 1;
    }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
        return [self.delegatesAndDataSource collectionView:self numberOfItemsInSection:section];
    } else {
        return 0;
    }
}

#pragma mark - Bottom Reflesh

- (UIView *)bottomRefleshView {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(bottomRefleshingViewOfCollectionView:)]) {
        return [self.delegatesAndDataSource bottomRefleshingViewOfCollectionView:self];
    } else {
        UIView *bottomRefleshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), self.bottomRefleshViewDefaultHeight)];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.frame = CGRectMake((CGRectGetWidth(bottomRefleshView.frame) - CGRectGetWidth(indicatorView.frame)) / 2, (CGRectGetHeight(bottomRefleshView.frame) - CGRectGetHeight(indicatorView.frame)) / 2, CGRectGetWidth(indicatorView.frame), CGRectGetHeight(indicatorView.frame));
        [indicatorView startAnimating];
        [bottomRefleshView addSubview:indicatorView];
        
        return bottomRefleshView;
    }
}

- (UIView *)bottomNoMoreView {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(bottomEndViewOfCollectionView:)]) {
        return [self.delegatesAndDataSource bottomEndViewOfCollectionView:self];
    } else {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), self.bottomRefleshViewDefaultHeight)];
        l.text = @"- End -";
        l.textAlignment = NSTextAlignmentCenter;
        return l;
    }
}

- (UIView *)bottomRetryView {
    if ([self.delegatesAndDataSource respondsToSelector:@selector(bottomRetryViewOfCollectionView:)]) {
        UIView *retryView = [self.delegatesAndDataSource bottomRetryViewOfCollectionView:self];
        if (retryView) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(0, 0, CGRectGetWidth(retryView.frame), CGRectGetHeight(retryView.frame));
            [btn addTarget:self action:@selector(bottomRefleshRetryTriggered) forControlEvents:UIControlEventTouchUpInside];
            retryView.frame = btn.bounds;
            [btn addSubview:retryView];
            return btn;
        } else {
            return nil;
        }
    } else {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:@"点击重新加载" forState:UIControlStateNormal];
        btn.frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), self.bottomRefleshViewDefaultHeight);
        [btn addTarget:self action:@selector(bottomRefleshRetryTriggered) forControlEvents:UIControlEventTouchUpInside];
        return btn;
    }
}

- (void)enableBottomReflesh:(BOOL(^)(void))hasMore loadMoreCallback:(void(^)(void))loadMoreCallback {
    self.bottomRefleshEnabled = YES;
    self.hasMoreCallback = hasMore;
    self.loadMoreCallback = loadMoreCallback;
    [self setNoneFooterView];
}

- (void)setContentInsetWithCustomBottomInset:(CGFloat)customBottomInset {
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom -= self.bottomInsetCustom;
    self.bottomInsetCustom = customBottomInset;
    insets.bottom += self.bottomInsetCustom;
    self.scrollView.contentInset = insets;
}

- (void)setNoMoreFooterView {
    UIView *endView = self.bottomNoMoreView;
    if (endView) {
        [self setContentInsetWithCustomBottomInset:-CGRectGetHeight(endView.frame)];
        self.footerView = endView;
    } else {
        [self setContentInsetWithCustomBottomInset:0];
        self.footerView = nil;
    }
}

- (void)setRefleshingFooterView {
    [self setContentInsetWithCustomBottomInset:0];
    self.footerView = self.bottomRefleshView;
}

- (void)setNoneFooterView {
    [self setContentInsetWithCustomBottomInset:0];
    self.footerView = nil;
}

- (void)setRetryFooterView {
    [self setContentInsetWithCustomBottomInset:0];
    self.footerView = self.bottomRetryView;
}

- (void)setBottomRefleshStatus:(FMBottomRefleshStatus)bottomRefleshStatus {
    if (_bottomRefleshStatus != bottomRefleshStatus) {
        _bottomRefleshStatus = bottomRefleshStatus;
        
        switch (bottomRefleshStatus) {
            case FMBottomRefleshStatusNone:
                [self setNoneFooterView];
                break;
            case FMBottomRefleshStatusLoading:
                [self setRefleshingFooterView];
                break;
            case FMBottomRefleshStatusLoadFailed:
                [self setRetryFooterView];
                break;
            case FMBottomRefleshStatusEnd:
                [self setNoMoreFooterView];
                break;
            default:
                break;
        }
    }
}

- (void)triggerBottomRefleshingIfNeed:(NSIndexPath *)indexPath {
    if (!self.bottomRefleshEnabled) {
        return;
    }
    
    if (self.bottomRefleshStatus == FMBottomRefleshStatusLoading
        || self.bottomRefleshStatus == FMBottomRefleshStatusLoadFailed) {
        return;
    }
    
    NSInteger sections = [self numberOfSections];
    if (indexPath.section < sections - 1) return;
    
    NSInteger rows = [self numberOfItemsInSection:indexPath.section];
    if (indexPath.row < rows - 1 - self.bottomRefleshingPreloadThreshold) return;
    
    if (self.hasMoreCallback && self.hasMoreCallback()) {
        if (self.loadMoreCallback) {
            self.loadMoreCallback();
            self.bottomRefleshStatus = FMBottomRefleshStatusLoading;
        } else {
            self.bottomRefleshStatus = FMBottomRefleshStatusNone;
        }
    } else {
        self.bottomRefleshStatus = FMBottomRefleshStatusEnd;
    }
}

- (void)endBottomRefleshing:(BOOL)isSuccess {
    if (!self.bottomRefleshEnabled) {
        return;
    }
    
    if (self.bottomRefleshStatus != FMBottomRefleshStatusLoading) {
        return;
    }
    
    if (self.hasMoreCallback && self.hasMoreCallback()) {
        if (isSuccess) {
            self.bottomRefleshStatus = FMBottomRefleshStatusNone;
        } else {
            self.bottomRefleshStatus = FMBottomRefleshStatusLoadFailed;
        }
    } else {
        self.bottomRefleshStatus = FMBottomRefleshStatusEnd;
    }
}

- (void)bottomRefleshRetryTriggered {
    if (!self.bottomRefleshEnabled) {
        return;
    }
    
    if (self.bottomRefleshStatus != FMBottomRefleshStatusLoadFailed) {
        return;
    }
    
    if (self.hasMoreCallback && self.hasMoreCallback()) {
        if (self.loadMoreCallback) {
            self.loadMoreCallback();
            self.bottomRefleshStatus = FMBottomRefleshStatusLoading;
        } else {
            self.bottomRefleshStatus = FMBottomRefleshStatusNone;
        }
    } else {
        self.bottomRefleshStatus = FMBottomRefleshStatusEnd;
    }
}

@end
