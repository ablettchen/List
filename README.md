# List

[![CI Status](https://img.shields.io/travis/ablett/List.svg?style=flat)](https://travis-ci.org/ablett/List)
[![Version](https://img.shields.io/cocoapods/v/List.svg?style=flat)](https://cocoapods.org/pods/List)
[![License](https://img.shields.io/cocoapods/l/List.svg?style=flat)](https://cocoapods.org/pods/List)
[![Platform](https://img.shields.io/cocoapods/p/List.svg?style=flat)](https://cocoapods.org/pods/List)

## Example

`Objective-C` 版本在这里 [ATList](https://github.com/ablettchen/ATList)

1. 通用配置(可选，如不配置，则使用默认)

```swift
        // 列表配置（可选，如不设置，取默认）
        ListGlobalConf.share.setupConf { (conf) in
            conf.loadComponent = .all
            conf.loadMode = .auto
            conf.length = 20
            conf.blankData = [
                .fail : Blank(
                    type: .fail,
                    image: Blank.image(.fail),
                    title: "请求失败",
                    desc: "10010",
                    tap: nil
                ),
                .noData : Blank(
                    type: .noData,
                    image: Blank.image(.fail),
                    title: "没有数据",
                    desc: "10011",
                    tap: nil
                ),
                .noNetwork : Blank(
                    type: .noNetwork,
                    image: Blank.image(.fail),
                    title: "没有网络",
                    desc: "10012",
                    tap: nil)
            ];
            conf.loadHeaderStyle = .gif
        }

```

2. 具体页面中使用

```swift
        // 具体列表配置（可选，如不设置，则取 ListGlobalConf，ListGlobalConf 未设置时取 conf）
        tableView.updateListConf { (conf) in
            conf.loadMode = self.loadMode
            conf.loadComponent = self.loadComponent
            conf.length = 20
            conf.blankData = [
                .fail : Blank(
                    type: .fail,
                    image: Blank.image(.fail),
                    title: "绘本数据加载失败",
                    desc: "10015",
                    tap: nil
                )
            ];
        }
        
        // 加载数据
        tableView.loadListData { (list) in
            self.requestData(["offset" : list.range.location, "number" : list.range.length], { (error, models) in
                if list.loadStatus == .new {self.datas.removeAll()}
                if models != nil {self.datas += models!}
                list.finish(error: error)
            })
        }
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

List is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'List'
```

## Author

ablett, ablettchen@gmail.com

## License

List is available under the MIT license. See the LICENSE file for more info.
