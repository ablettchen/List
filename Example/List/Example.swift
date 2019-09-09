//
//  Example.swift
//  List_Example
//
//  Created by ablett on 2019/7/29.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import List

public class Example: NSObject {
    
    public var loadStrategy: LoadStrategy = .auto
    public var loadType: LoadType = .new
    
    public var title: NSString = "自动: 下拉刷新"
    
    public init(loadStrategy: LoadStrategy, loadType: LoadType) {
        
        super.init()
        
        self.loadStrategy = loadStrategy
        self.loadType = loadType
        
        var strategyDesc: NSString = ""
        switch loadStrategy {
        case .auto:
            strategyDesc = "自动"
        case .manual:
            strategyDesc = "手动"
        default: break
        }
        
        var typeDesc: NSString = ""
        switch loadType {
        case .nothing:
            typeDesc = "无刷新"
        case .new:
            typeDesc = "下拉刷新"
        case .more:
            typeDesc = "上拉加载"
        case .all:
            typeDesc = "下拉刷新 + 上拉加载"
        default: break
        }
        
        self.title = NSString(string: "\(strategyDesc): \(typeDesc)")
        
    }
    
}
