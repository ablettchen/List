# List

[![CI Status](https://img.shields.io/travis/ablett/List.svg?style=flat)](https://travis-ci.org/ablett/List)
[![Version](https://img.shields.io/cocoapods/v/List.svg?style=flat)](https://cocoapods.org/pods/List)
[![License](https://img.shields.io/cocoapods/l/List.svg?style=flat)](https://cocoapods.org/pods/List)
[![Platform](https://img.shields.io/cocoapods/p/List.svg?style=flat)](https://cocoapods.org/pods/List)

## Example

1. 通用配置(可选，如不配置，则使用默认)

```objectiveC
ListDefaultConf.share.setupConf {
            (conf) in
            conf.loadType = .all
            conf.loadStrategy = .auto
            conf.length = 20
            conf.blankData = [.fail : Blank(type: .fail,
                                            image: Blank.defaultBlankImage(type: .fail),
                                            title: .init(string: "数据请求失败☹️"),
                                            desc: .init(string: "10014"), tap: nil),
                              
                              .noData : Blank(type: .noData,
                                              image: Blank.defaultBlankImage(type: .fail),
                                              title: .init(string: "暂时没有数据🙂"),
                                              desc: .init(string: "哈哈哈~"), tap: nil),
                              
                              .noNetwork : Blank(type: .noNetwork,
                                                 image: Blank.defaultBlankImage(type: .fail),
                                                 title: .init(string: "貌似没有网络🙄"),
                                                 desc: .init(string: "请检查设置"), tap: nil)];
        }

```

2. 具体页面中使用

```objectiveC
tableView.updateListConf { (conf) in
            conf.loadType = .all
            conf.length = 20
            conf.blankData = [.fail : Blank(type: .fail,
                                            image: Blank.defaultBlankImage(type: .fail),
                                            title: .init(string: "绘本数据加载失败"),
                                            desc: .init(string: "10015"),
                                            tap: nil)];
        }
        
        tableView.loadListData { (list) in
            self.requestData(["offset" : list.range.location, "number" : list.range.length], { (error, models) in
                if list.status == .new {self.datas.removeAll()}
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
