#
# Be sure to run `pod lib lint List.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    
    s.name             = 'List'
    s.version          = '0.4.1'
    s.summary          = 'Quick configuration pull-down refresh, pull-up loading, blank page, for UITableView, UICollectionView, UIScrollView.'
    s.homepage         = 'https://github.com/ablettchen/List'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'ablett' => 'ablettchen@gmail.com' }
    s.source           = { :git => 'https://github.com/ablettchen/List.git', :tag => s.version.to_s }
    s.source_files     = 'List/Classes/**/*'
    s.resource_bundles = {
        'List' => ['List/Assets/*.xcassets']
    }
    s.platform         = :ios, "10.0"
    s.swift_version    = '5.2'
    
    s.dependency 'Blank'
    s.dependency 'MJRefresh'
    s.dependency 'Reachability'
    
end
