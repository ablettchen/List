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
    
    public var loadMode: LoadMode = .auto
    public var loadComponent: LoadComponent = .header
    
    public var title: NSString = "自动: 下拉刷新"
    
    public init(loadMode: LoadMode, loadComponent: LoadComponent) {
        
        super.init()
        
        self.loadMode = loadMode
        self.loadComponent = loadComponent
        
        var strategyDesc: NSString = ""
        switch loadMode {
        case .auto:
            strategyDesc = "自动"
        case .manual:
            strategyDesc = "手动"
        default: break
        }
        
        var typeDesc: NSString = ""
        switch loadComponent {
        case .nothing:
            typeDesc = "无刷新"
        case .header:
            typeDesc = "下拉刷新"
        case .footer:
            typeDesc = "上拉加载"
        case .all:
            typeDesc = "下拉刷新 + 上拉加载"
        default: break
        }
        
        self.title = NSString(string: "\(strategyDesc): \(typeDesc)")
        
    }
    
}
