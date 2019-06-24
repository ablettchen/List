//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank

@objc public enum LoadType : Int, CustomStringConvertible {
    case none
    case new
    case more
    case all
    
    public var description: String {
        switch self {
        case .none: return "none"
        case .new:  return "pull refresh"
        case .more: return "load more"
        case.all:   return "pull refresh and load more"
        }
    }
}


@objc public enum LoadStrategy : Int, CustomStringConvertible {
    case auto
    case manual
    
    public var description: String {
        switch self {
        case .auto:     return "auto"
        case .manual:   return "manual"
        }
    }
}

@objc public enum LoadStatus : Int, CustomStringConvertible {
    case idle
    case new
    case more
    
    public var description: String {
        switch self {
        case .idle: return "idle"
        case .new:  return "pull refresh"
        case .more: return "load more"
        }
    }
}

public class ListConf: NSObject {
    
    public var loadType: LoadType!
    public var loadStrategy: LoadStrategy!
    public var length: Int!
    
    public var blankData: [BlankType:Blank]!
    
    public func reset() -> Void {
        loadType = .none
        loadStrategy = .auto
        length = 20
        
        blankData = [.fail      : Blank.defaultBlank(type: .fail),
                     .noData    : Blank.defaultBlank(type: .noData),
                     .noNetwork : Blank.defaultBlank(type: .noNetwork)]
    }
    
    override init() {
        super.init()
        reset()
    }
}

public class List: NSObject {
    
    public var conf: ListConf! {
        get {
            return ListConf()
        }
    }
    
    public func setConf(conf: ListConf) -> Void {
        
    }
    
    public var loadStatus: LoadStatus! {
        get {
            return .idle
        }
    }
    
    public var range: NSRange! {
        get {
            return NSMakeRange(0, conf.length)
        }
    }
    
    func finished(error:Error) -> Void {
        
    }
    
    func loadNew() -> Void {
        
    }
    
    func beginning() -> Void {
        
    }

    public override init() {
        super.init()
    }
    
}

private var kList = "kList"

extension UIScrollView {
    
    public var list: List! {
        get {
            if let list = objc_getAssociatedObject(self, &kList) as? List {
                return list
            }
            let list = List()
            setList(list)
            return list
        }
    }

    public func setList(_ newValue: List) -> Void {
        objc_setAssociatedObject(self, &kList, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public var updateListConf: (_ closure: (_ conf:ListConf)-> (Void)) -> Void? {
        get {
            return { (cls) -> Void in
                let conf = ListConf()
                cls(conf)
            }
        }
    }
    
    public var loadListData: (_ closure: (_ list:List)-> (Void)) -> Void? {
        get {
            return { (cls) -> Void in
                cls(List())
            }
        }
    }
    
}
