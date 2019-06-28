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

private var dataLengthDefault: Int = 20
private var dataLengthMax: Int = 1000

public class ListConf: NSObject {
    
    public var loadType: LoadType!
    public var loadStrategy: LoadStrategy!
    public var length: Int!
    
    public var blankData: [BlankType:Blank]!
    
    public func reset() -> Void {
        loadType = .none
        loadStrategy = .auto
        length = 0
        
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
    
    public var conf: ListConf! {
        get {
            if let conf = objc_getAssociatedObject(self, &kConf) as? ListConf {
                return conf;
            }
            let conf = ListConf()
            objc_setAssociatedObject(self, &kConf, conf, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return conf
        }
        set {
            objc_setAssociatedObject(self, &kConf, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue.loadType == .none {
                self.listView.mj_header = RefreshHeader()
            }else {
                if newValue.loadStrategy == .auto {
                    self.listView.mj_header = self.header
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
    
    public func finish(error:Error) -> Void {
        if blank.isAnimating {blank.isAnimating = false}
        listView.reloadBlank()
        
        if conf.loadType == .none {setStatus(.new)}
        
        if status == .new {
            listView.mj_header.endRefreshing()
            listView.mj_footer.resetNoMoreData()
            
            if listView.itemsCount() == 0 {
                blankType = (error != nil) ? .fail : .noData
            }else {
                if conf.loadType == .all {
                    if listView.itemsCount() >= conf.length {
                        if conf.loadStrategy == .auto {
                            listView.mj_footer = footer
                        }
                    }else {
                        listView.mj_footer = nil
                    }
                }
            }
        }else if status == .more {
            if (listView.itemsCount() - lastItemCount) < range.length {
                listView.mj_footer.endRefreshingWithNoMoreData()
            }else {
                listView.mj_footer = footer
                listView.mj_footer.endRefreshing()
            }
        }
        
        reloadData()
        setStatus(.idle)
        lastItemCount = listView.itemsCount()
        
    }
    
    @objc public func loadNewData() -> Void {
        setStatus(.new)
        setRange(NSMakeRange(0, self.conf.length))
        lastItemCount = 0
        let sel: Selector = NSSelectorFromString("loadNewData")
        if listView.responds(to: sel) {listView.perform(sel, with: nil)}
    }
    
    @objc public func reloadData() -> Void {
        let sel: Selector = NSSelectorFromString("reloadData")
        if listView.responds(to: sel) {
            listView.perform(sel, with: nil)
        }else {
            listView.setNeedsDisplay()
        }
    }
    
    public func beginning() -> Void {
        header.beginRefreshing();
    }
    
    private var listView: UIScrollView!

    private lazy var header: RefreshHeader = {
        let view: RefreshHeader = RefreshHeader.init(refreshingTarget: self, refreshingAction: #selector(loadNewData))
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
    
    private lazy var footer: RefreshFotter = {
        let view: RefreshFotter = RefreshFotter.init(refreshingTarget: self, refreshingAction: #selector(loadMoreData))
        view.setTitle("上拉加载更多", for: .idle)
        view.setTitle("加载中...", for: .refreshing)
        view.setTitle("没有更多数据", for: .noMoreData)
        view.stateLabel.font = .systemFont(ofSize: 13)
        view.stateLabel.textColor = .init(white: 0.584, alpha: 1)
        return view
    }()
    
    private var blankType: BlankType! {
        didSet {
            if self.conf.blankData.isEmpty {
                self.blank = Blank.defaultBlank(type: blankType)
            }else {
                if let blank = self.conf.blankData[blankType] {
                    self.blank = blank
                }else {
                    self.blank = Blank.defaultBlank(type: blankType)
                }
            }
            
            self.blank?.tap = {
                (tapGesture) in
                if !self.blank.isAnimating {
                    self.blank.isAnimating = true
                    self.listView.reloadBlank()
                    self.loadNewData()
                }
            }
            
            self.listView.setBlank(self.blank)
            self.listView.reloadBlank()
        }
    }
    
    private var blank: Blank!
    
    private var lastItemCount: Int!
    
    @objc func loadMoreData() -> Void {
        if status == .new {return;}
        setStatus(.more)
        let loc: Int = Int(ceilf((Float(self.listView.itemsCount()) / Float(self.conf.length))))
        setRange(NSMakeRange(loc > 0 ? loc : 1, conf.length))
        let sel: Selector = NSSelectorFromString("loadMoreData")
        if self.listView.responds(to: sel) {self.listView.perform(sel)}
    }
    
    public override init() {
        super.init()
        conf = ListConf()
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
