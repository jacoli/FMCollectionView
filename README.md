# FMCollectionView

集合视图，类似UITableView或UICollectionView，在布局能力做了增强，支持多种布局方式，并且在同个视图上可以使用多种布局方式，可替代UITableView或UICollectionView使用。

## Features

* 可以同时使用多种布局方式

* 类似UITableView或UICollectionView

* 支持多种布局方式，Row、Grid、WaterFlow、Flow等

* 自定义布局

* 元素复用、预加载.

* 支持下拉刷新、支持上拉刷新

## Installation

With [CocoaPods](http://cocoapods.org/), add this line to your `Podfile`.

```
pod 'FMCollectionView'
```

and run `pod install`, then you're all done!

Or copy `*.h *.m` files in `Sources` folder to your project.

## How to use

* Add collection view to container.

eg.

```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView = [[FMCollectionView alloc] initWithFrame:self.view.bounds];
    self.collectionView.sectionsSpacing = 20;
    self.collectionView.itemsSpacing = 4;
    self.collectionView.delegatesAndDataSource = self;
    [self.view addSubview:self.collectionView];
}
```

* Implement `FMCollectionViewDelegatesAndDataSource`, only two methods in `FMCollectionViewDataSource` is required, others is optional.

```
- (NSInteger)numberOfSectionsInCollectionView:(FMCollectionView *)collectionView {
    return HomeSectionsTotalCount;
}

- (NSInteger)collectionView:(FMCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == HomeSectionsBanners) {
        return self.presenter.banners.count > 0 ? 1 : 0;
    } else if (section == HomeSectionsCategories) {
        return self.presenter.categories.count;
    } else if (section == HomeSectionsProducts){
        return [self.presenter itemsCount];
    } else if (section == HomeSectionsProductsLoadFailed){
        return self.presenter.isFetchProductsFailed ? 1 : 0;
    }
    return 0;
}

- (UIView *)collectionView:(FMCollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView beginBottomRefleshingIfNeed:indexPath];
    
    if (indexPath.section == HomeSectionsBanners) {
        return self.bannersComponent.componentView;
    } else if (indexPath.section == HomeSectionsCategories) {
        FMBannerModel *model = self.presenter.categories[indexPath.row];
        HomeCategoryCell *cell = [collectionView dequeueReusableItemWithId:@"categories_cell" atIndexPath:indexPath itemClass:HomeCategoryCell.class];
        [cell setImgUrl:model.onlyPic.picUrl];
        return cell;
    } else if (indexPath.section == HomeSectionsProducts) {
        ProductListModel *data = [self.presenter itemAtIndex:indexPath.row];
        HomeProductCell *cell = [collectionView dequeueReusableItemWithId:@"products_cell" atIndexPath:indexPath itemClass:HomeProductCell.class];
        [cell.imgView setImgUrl:data.picUrl];
        cell.titleLabel.text = data.productShortTitle;
        cell.priceLabel.text = [FMBizUtils stringFromPriceInCent:data.minPriceCent];
        return cell;
    } else if (indexPath.section == HomeSectionsProductsLoadFailed) {
        WeakSelf()
        FMNoResultBGViewItem *item = [[FMNoResultBGViewItem alloc] init];
        item.style = kNoResultBGViewStyleImgTitle;
        item.clicked = ^{
            [weakSelf.presenter loadAllKindsData];
        };
        return [[FMNoResultBGView alloc] initWithFrame:collectionView.bounds andItem:item];
    } else {
        return nil;
    }
}
```

* See the examples.

## Requirements

* iOS 7.0+ 
* ARC

## License

* MIT