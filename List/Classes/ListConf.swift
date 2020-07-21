//
//  ListConf.swift
//  List
//
//  Created by ablett on 2020/7/20.
//

import Foundation
import Blank

var dataLengthDefault: Int = 20
var dataLengthMax: Int = 1000

public class ListConf: NSObject {
    
    /// 自定义空白页
    public var customBlankView: UIView?
    
    /// 加载方式
    public var loadStyle: LoadStyle = .header
    
    /// 加载策略
    public var loadStrategy: LoadStrategy = .auto
    
    /// 加载长度
    public var length: Int = dataLengthMax
    
    /// 空白页描述
    public var blankData: [BlankType : Blank] = [:]
    
    /// 头部样式
    public var loadHeaderStyle: LoadHeaderStyle = .normal
    
    /// 刷新图片
    public var refreshingImages: [UIImage] = []
    
    /// 重置
    public func reset() {
        
        customBlankView = nil
        loadStyle = .header
        loadStrategy = .auto
        length = dataLengthMax
        blankData = [
            .fail      : Blank.default(type: .fail),
            .noData    : Blank.default(type: .noData),
            .noNetwork : Blank.default(type: .noNetwork)
        ]
        
        var gifImages: [UIImage] = []
        for index in 1...23 {
            if let image = UIImage(named: "refreshGif_\(index)", in: Bundle.list(), compatibleWith: nil) {
                gifImages.append(image)
            }
        }
        self.refreshingImages = gifImages
        
    }
    
    override init() {
        super.init()
        reset()
    }
}

extension ListConf: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        
        let conf = ListConf.init()
        conf.customBlankView = customBlankView
        conf.loadStyle = loadStyle
        conf.loadStrategy = loadStrategy
        conf.length = length
        conf.blankData = blankData
        conf.loadHeaderStyle = loadHeaderStyle
        conf.refreshingImages = refreshingImages
        return conf
    }
}
