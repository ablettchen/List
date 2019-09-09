//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank


@objc public enum LoadType : Int, CustomStringConvertible {
    case nothing
    case new
    case more
    case all
    
    public var description: String {
        switch self {
        case .nothing: return "nothing"
        case .new:     return "load new"
        case .more:    return "load more"
        case .all:     return "load new and load more"
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
        case .new:  return "load new"
        case .more: return "load more"
        }
    }
}

private var dataLengthDefault: Int = 20
private var dataLengthMax: Int = 1000

public class ListConf: NSObject {
    
    public var loadType: LoadType = .new
    public var loadStrategy: LoadStrategy = .auto
    public var length: Int = dataLengthMax
    
    public var blankData: [BlankType:Blank]!
    
    public func reset() -> Void {
        loadType = .new
        loadStrategy = .auto
        length = dataLengthMax
        
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
private var kListView = "kListView"

public class List: NSObject {
    
    public var conf: ListConf? {
        didSet {
            if conf?.loadType == .nothing || conf?.loadType == .more {
                if let view = listView {
                    if view.mj_header != nil {
                        view.mj_header = nil
                    }
                }
            }else if conf?.loadType == .new || conf?.loadType == .all {
                if let view = listView {
                    view.mj_header = header
                }
            }
        }
    }
    
    public var loadStatus: LoadStatus! {
        get {
            if let status = objc_getAssociatedObject(self, &kLoadStatus) as? LoadStatus {
                return status;
            }
            let status: LoadStatus = .idle
            setStatus(status)
            return status
        }
    }
    
    fileprivate func setStatus(_ loadStatus: LoadStatus) -> Void {
        objc_setAssociatedObject(self, &kLoadStatus, loadStatus, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public var range: NSRange! {
        get {
            if let range = objc_getAssociatedObject(self, &kRange) as? NSRange {
                return range;
            }
            let lentgh = ((conf?.loadType == .new || conf?.loadType == .nothing) ? dataLengthMax : dataLengthDefault)
            let range = NSMakeRange(0, conf?.length ?? lentgh)
            setRange(range)
            return range
        }
    }
    
    fileprivate func setRange(_ range: NSRange) -> Void {
        objc_setAssociatedObject(self, &kRange, range, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public func finish(error: Error?) -> Void {
        if blank != nil {
            if blank.isAnimating {blank.isAnimating = false}
        }
        listView.reloadBlank()
        
        // 解决非控件自动触发的刷新（使用者直接调用 finish:）而导致 loadStatus 无法得到正确的状态，致使无法正确显示页面，故此处需要重设 loadStatus = ATLoadStatusNew
        if loadStatus == .idle {setStatus(.new)}
        
        if loadStatus == .new {

            if (listView.mj_header != nil) {listView.mj_header.endRefreshing()}
            if (listView.mj_footer != nil) {listView.mj_footer.resetNoMoreData()}
            
            if listView.itemsCount() == 0 {
                blankType = (error != nil) ? .fail : .noData
            }else {
                if conf?.loadType == .more || conf?.loadType == .all {
                    if listView.itemsCount() >= conf?.length ?? dataLengthDefault {
                        listView.mj_footer = footer
                    }else {
                        listView.mj_footer = nil
                    }
                }
            }
        }else if loadStatus == .more {
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
    
    @objc public func pull_loadNewData() -> Void {
        if loadStatus != .idle {return}
        setStatus(.new)
        let length = ((self.conf?.loadType == .new || self.conf?.loadType == .nothing) ? dataLengthMax : dataLengthDefault)
        setRange(NSMakeRange(0, self.conf?.length ?? length))
        lastItemCount = 0
        listView.loadNewData()
    }
    
    @objc public func loadNewData() -> Void {
        if conf?.loadStrategy == .manual && (conf?.loadType == .new || conf?.loadType == .all)  {
            beginning()
        }else {
            pull_loadNewData()
        }
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
    
    fileprivate var listView: UIScrollView!
    
    private lazy var header: RefreshHeader = {
        let view: RefreshHeader = RefreshHeader.init(refreshingTarget: self, refreshingAction: #selector(pull_loadNewData))
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
            if self.conf?.blankData.isEmpty ?? true {
                blank = Blank.defaultBlank(type: blankType)
            }else {
                if let b = conf?.blankData[blankType] {
                    blank = b
                }else {
                    blank = Blank.defaultBlank(type: blankType)
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
            
            listView.setBlank(blank)
            listView.reloadBlank()
        }
    }
    
    private var blank: Blank!
    
    private var lastItemCount: Int!
    
    @objc func loadMoreData() -> Void {
        if loadStatus != .idle {return}
        setStatus(.more)
        let loc: Int = Int(ceilf((Float(listView.itemsCount() / (conf?.length ?? dataLengthDefault)))))
        setRange(NSMakeRange((loc > 0 ? loc : 1) * (conf?.length ?? dataLengthDefault), (conf?.length ?? dataLengthDefault)))
        listView.loadMoreData()
    }
    
    public override init() {
        super.init()
        //conf = ListConf()
        setStatus(.idle)
        setRange(NSMakeRange(0, (conf?.length ?? dataLengthMax)))
        lastItemCount = 0
    }
}

public class ListDefaultConf: NSObject {
    
    public class var share: ListDefaultConf {
        struct Static {
            static let instance: ListDefaultConf = ListDefaultConf()
        }
        return Static.instance
    }
    
    public var conf: ListConf?
    
    public var setupConf: (_ closure: (_ conf: ListConf)-> (Void)) -> Void {
        get {
            return { (cls) -> Void in
                let conf = ListConf()
                cls(conf)
                self.conf = conf
            }
        }
    }
}

private var kList = "kList"
private var kListClosure = "kListClosure"

public typealias ListClosure = (_ list: List) -> Void
public typealias ListConfClosure = (_ conf: ListConf) -> Void

extension UIScrollView {
    
    fileprivate var listBlock: ((List) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &kListClosure) as? ListClosure;
        }
        set {
            objc_setAssociatedObject(self, &kListClosure, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var atList: List! {
        get {
            if let list = objc_getAssociatedObject(self, &kList) as? List {
                return list
            }
            let list = List()
            setAtList(list)
            return list
        }
    }

    private func setAtList(_ newValue: List) -> Void {
        objc_setAssociatedObject(self, &kList, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func updateListConf(listConfClosure: ListConfClosure) -> Void {
        var conf: ListConf!
        if self.atList.conf != nil {
            conf = self.atList.conf
        }else {
            conf = ListConf()
        }
        if conf.length == 0 {
            let lentgh = ((conf?.loadType == .new || conf?.loadType == .nothing) ? dataLengthMax : dataLengthDefault)
            conf.length = lentgh
        }
        self.atList.conf = conf;
        listConfClosure(conf)
    }
    

    public func loadListData(_ listClosure: @escaping ListClosure) -> Void {
        self.listBlock = listClosure
        self.atList.listView = self
        self.atList.conf = (self.atList.conf != nil) ? self.atList.conf : ((ListDefaultConf.share.conf != nil) ? ListDefaultConf.share.conf : ListConf())
        if self.atList.conf?.loadStrategy == .auto {
            if self.atList.conf?.loadType == .nothing || self.atList.conf?.loadType == .more {
                self.atList.setStatus(.new)
                let lentgh = ((self.atList.conf?.loadType == .new || self.atList.conf?.loadType == .nothing) ? dataLengthMax : dataLengthDefault)
                self.atList.setRange(NSMakeRange(0, self.atList.conf?.length ?? lentgh))
                if self.listBlock != nil {
                    self.listBlock!(self.atList)
                }
            }else {
                self.atList.beginning()
            }
        }
    }

    fileprivate func loadNewData() -> Void {
        if self.listBlock != nil {
            self.listBlock!(self.atList)
        }
    }
    
    fileprivate func loadMoreData() -> Void {
        if self.listBlock != nil {
            self.listBlock!(self.atList)
        }
    }
}
