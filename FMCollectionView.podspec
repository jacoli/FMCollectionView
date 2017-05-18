Pod::Spec.new do |s|
  s.name         = "FMCollectionView"
  s.version      = "1.0.0"
  s.summary      = "Collection of items, similar to UITableView and UICollectionView, support various layout style."
  s.homepage     = "https://github.com/jacoli/FMCollectionView"
  s.license      = "MIT"
  s.authors      = { "jacoli" => "jaco.lcg@gmail.com" }
  s.source       = { :git => "https://github.com/jacoli/FMCollectionView.git", :tag => "1.0.0" }
  s.frameworks   = 'Foundation', 'UIKit'
  s.platform     = :ios, '7.0'
  s.source_files = 'Sources/*.{h,m}'
  s.requires_arc = true
end
