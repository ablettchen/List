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

private var kConf = "kConf"
private var kLoadStatus = "kLoadStatus"
private var kRange = "kRange"

public class List: NSObject {
    
    private var listView: UIScrollView!
    
    public var conf: ListConf! {
        get {
            if let conf = objc_getAssociatedObject(self, &kConf) as? ListConf {
                return conf;
            }
            let conf = ListConf()
            setConf(conf: conf)
            return conf
        }
    }
    
    public func setConf(conf: ListConf) -> Void {
        objc_setAssociatedObject(self, &kConf, conf, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if conf.loadType == .none {
            self.listView.mj_header = nil
        }else {
            if conf.loadStrategy == .auto {
                self.listView.mj_header = self.header
            }
        }
    }
    
    private var blank: Blank?
    
    private var blankType: BlankType! {
        didSet {
            if self.conf.blankData.isEmpty {
                self.blank = Blank.defaultBlank(type: blankType)
            }else {
                if let blank = self.conf.blankData[blankType] {
                    
                }
            }
        }
    }
    
    public var status: LoadStatus! {
        get {
            if let status = objc_getAssociatedObject(self, &kLoadStatus) as? LoadStatus {
                return status;
            }
            let status: LoadStatus = .idle
            setStatus(status)
            return status
        }
    }
    
    private func setStatus(_ loadStatus: LoadStatus) -> Void {
        objc_setAssociatedObject(self, &kLoadStatus, loadStatus, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public var range: NSRange! {
        get {
            if let range = objc_getAssociatedObject(self, &kRange) as? NSRange {
                return range;
            }
            let range = NSMakeRange(0, conf.length)
            setRange(range)
            return range
        }
    }
    
    private func setRange(_ range: NSRange) -> Void {
        objc_setAssociatedObject(self, &kRange, range, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private var lastItemCount: Int!
    
    func finished(error:Error) -> Void {
        
    }
    
    @objc func loadNew() -> Void {
        setStatus(.new)
        setRange(NSMakeRange(0, self.conf.length))
        lastItemCount = 0
        let sel: Selector = NSSelectorFromString("loadNew")
        if listView.responds(to: sel) {
            listView.perform(sel, with: nil)
        }
    }
    
    @objc func loadMore() -> Void {
        
    }
    
    func beginning() -> Void {
        
    }
    
    lazy var header: RefreshHeader = {
        let view: RefreshHeader = RefreshHeader.init(refreshingTarget: self, refreshingAction: #selector(loadNew))
        view.setTitle("下拉刷新", for: .idle)
        view.setTitle("释放更新", for: .pulling)
        view.setTitle("加载中...", for: .refreshing)
        view.stateLabel.font = .systemFont(ofSize: 13)
        view.lastUpdatedTimeLabel.font = .systemFont(ofSize: 14)
        view.stateLabel.textColor = .init(white: 0.584, alpha: 1)
        view.lastUpdatedTimeLabel.textColor = .init(white: 0.584, alpha: 1)
        view.isAutomaticallyChangeAlpha = true
        view.lastUpdatedTimeLabel.isHidden = true
        return view
    }()
    
    lazy var footer: RefreshFotter = {
        let view: RefreshFotter = RefreshFotter.init(refreshingTarget: self, refreshingAction: #selector(loadMore))
        view.setTitle("上拉加载更多", for: .idle)
        view.setTitle("加载中...", for: .refreshing)
        view.setTitle("没有更多数据", for: .noMoreData)
        view.stateLabel.font = .systemFont(ofSize: 13)
        view.stateLabel.textColor = .init(white: 0.584, alpha: 1)
        return view
    }()
    
    
    public override init() {
        super.init()
        
        setStatus(.idle)
        setRange(NSMakeRange(0, self.conf.length))
        lastItemCount = 0
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
