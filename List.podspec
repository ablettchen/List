#
# Be sure to run `pod lib lint List.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'List'
  s.version          = '0.1.0'
  s.summary          = 'Quick configuration pull-down refresh, pull-up loading, blank page, for UITableView, UICollectionView, UIScrollView.'

  s.homepage         = 'https://github.com/ablettchen/List'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ablett' => 'ablettchen@gmail.com' }
  s.source           = { :git => 'https://github.com/ablettchen/List.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ablettchen'

  s.ios.deployment_target = '8.0'
#  s.ios.swift.version = '4.0'
  
  s.source_files = 'List/Classes/**/*'
  
  # s.resource_bundles = {
  #   'List' => ['List/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Blank'
  
end
