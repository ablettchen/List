//
//  ListConf.swift
//  List
//
//  Created by ablett on 2020/7/20.
//

import Foundation
import Blank

internal var dataLengthDefault: Int = 20
internal var dataLengthMax: Int = 1000

public class ListConf: NSObject {
    
    /// 自定义空白页
    public var customBlankView: UIView?
    
    /// 加载组成部分
    public var loadComponent: LoadComponent = .header
    
    /// 加载模式
    public var loadMode: LoadMode = .auto
    
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
        loadComponent = .header
        loadMode = .auto
        length = dataLengthMax
        blankData = [
            .fail      : Blank.default(.fail),
            .noData    : Blank.default(.noData),
            .noNetwork : Blank.default(.noNetwork)
        ]
        
        var gifImages: [UIImage] = []
        for index in 1...23 {
            if let image = UIImage(named: "refreshGif_\(index)", in: Bundle.list, compatibleWith: nil) {
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
        conf.loadComponent = loadComponent
        conf.loadMode = loadMode
        conf.length = length
        conf.blankData = blankData
        conf.loadHeaderStyle = loadHeaderStyle
        conf.refreshingImages = refreshingImages
        return conf
    }
}

public class ListGlobalConf: NSObject {
    
    public class var share: ListGlobalConf {
        struct Static {
            static let instance: ListGlobalConf = ListGlobalConf()
        }
        return Static.instance
    }
    
    public private(set) var conf: ListConf?
    
    public var setupConf: (_ block: (_ conf: ListConf) -> Void) -> Void {
        get {
            return { (block) in
                let conf = ListConf()
                block(conf)
                ListGlobalConf.share.conf = conf
            }
        }
    }
}
