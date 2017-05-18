# FMCollectionView
Collection of items, similar to UITableView and UICollectionView, support various layout style.

## Features

* Similar to UITableView and UICollectionView.

* Support various layouts.

* Items reuse.

* Items prefetch.

* Section and item spacing custom.

* Some custom layout (TODO).

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

* See the examples.

## Requirements

* iOS 7.0+ 
* ARC

## License

* MIT