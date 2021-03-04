//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank
import Reachability


@objc public enum LoadStyle: Int, CustomStringConvertible {
    case nothing
    case header
    case footer
    case all
    
    public var description: String {
        switch self {
        case .nothing   : return "nothing"
        case .header    : return "load new"
        case .footer    : return "load more"
        case .all       : return "load new and load more"
        }
    }
}

@objc public enum LoadStrategy: Int, CustomStringConvertible {
    case auto
    case manual
    
    public var description: String {
        switch self {
        case .auto      : return "auto"
        case .manual    : return "manual"
        }
    }
}

@objc public enum LoadStatus: Int, CustomStringConvertible {
    case idle
    case new
    case more
    
    public var description: String {
        switch self {
        case .idle  : return "idle"
        case .new   : return "load new"
        case .more  : return "load more"
        }
    }
}

@objc public enum LoadHeaderStyle: Int, CustomStringConvertible {
    case normal
    case gif
    
    public var description: String {
        switch self {
        case .normal : return "normal"
        case .gif    : return "gif"
        }
    }
}

public class List: NSObject {
    
    public var conf: ListConf? {
        didSet {
            if let conf = conf {
                if conf.loadStyle == .nothing || conf.loadStyle == .footer {
                    if let view = listView {
                        guard view.mj_header == nil else {
                            view.mj_header = nil
                            return
                        }
                    }
                }else if conf.loadStyle == .header || conf.loadStyle == .all {
                    if let view = listView {
                        if conf.loadHeaderStyle == .normal {
                            view.mj_header = header
                        }else if conf.loadHeaderStyle == .gif {
                            view.mj_header = gifHeader
                        }
                    }
                }
            }
        }
    }
    
    public var loadStatus: LoadStatus {
        get {
            if let status = objc_getAssociatedObject(self, &kLoadStatus) as? LoadStatus {return status}
            let status: LoadStatus = .idle
            setStatus(status)
            return status
        }
    }
    
    fileprivate func setStatus(_ loadStatus: LoadStatus) {
        objc_setAssociatedObject(self, &kLoadStatus, loadStatus, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public var range: NSRange {
        get {
            if let range = objc_getAssociatedObject(self, &kRange) as? NSRange {
                return range;
            }
            let lentgh = ((conf?.loadStyle == .header || conf?.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
            let range = NSMakeRange(0, conf?.length ?? lentgh)
            setRange(range)
            return range
        }
    }
    
    fileprivate func setRange(_ range: NSRange) {
        objc_setAssociatedObject(self, &kRange, range, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
        
    public func finish(error: Error?) {
        
        if let blank = blank {if blank.isAnimating {blank.isAnimating = false}}
        listView?.reloadBlank()
        
        // 解决非控件自动触发的刷新（使用者直接调用 finish:）而导致 loadStatus 无法得到正确的状态，致使无法正确显示页面，故此处需要重设 loadStatus = ATLoadStatusNew
        if loadStatus == .idle {setStatus(.new)}
        
        if loadStatus == .new {

            listView?.mj_header?.endRefreshing()
            listView?.mj_footer?.resetNoMoreData()

            if listView?.itemsCount() == 0 {
                blankType = (error == nil) ? .noData : .fail
            }else {
                if conf?.loadStyle == .footer || conf?.loadStyle == .all {
                    if (listView?.itemsCount() ?? 0) >= conf?.length ?? dataLengthDefault {
                        listView?.mj_footer = footer
                    }else {
                        listView?.mj_footer = nil
                    }
                }
            }
        }else if loadStatus == .more {
            if ((listView?.itemsCount() ?? 0) - lastItemCount) < range.length {
                listView?.mj_footer?.endRefreshingWithNoMoreData()
            }else {
                listView?.mj_footer = footer
                listView?.mj_footer?.endRefreshing()
            }
        }
        reloadData()
        setStatus(.idle)
        lastItemCount = listView?.itemsCount() ?? 0
    }
    
    @objc public func pull_loadNewData() {
        guard loadStatus == .idle else {return}
        setStatus(.new)
        let length = ((self.conf?.loadStyle == .header || self.conf?.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
        setRange(NSMakeRange(0, self.conf?.length ?? length))
        lastItemCount = 0
        listView?.loadNewData()
    }
    
    public func loadNewData(animated: Bool? = true, length: Int? = nil) {
        if let length = length {
            conf?.length = length
        }
        guard animated == true else {
            pull_loadNewData()
            return
        }
        if conf?.loadStrategy == .manual && (conf?.loadStyle == .header || conf?.loadStyle == .all)  {
            beginning()
        }else {
            pull_loadNewData()
        }
    }
    
    @objc public func reloadData() {
        let sel: Selector = NSSelectorFromString("reloadData")
        if listView?.responds(to: sel) ?? false {
            listView?.perform(sel, with: nil)
        }else {
            listView?.setNeedsDisplay()
        }
    }
    
    public func beginning() {
        if conf?.loadHeaderStyle == .normal {
            header.beginRefreshing();
        }else if conf?.loadHeaderStyle == .gif {
            gifHeader.beginRefreshing();
        }
    }
    
    fileprivate weak var listView: UIScrollView?
    
    private lazy var header: RefreshHeader = {
        let view: RefreshHeader = RefreshHeader.init(refreshingTarget: self, refreshingAction: #selector(pull_loadNewData))
        view.setTitle("下拉刷新", for: .idle)
        view.setTitle("释放更新", for: .pulling)
        view.setTitle("加载中...", for: .refreshing)
        view.stateLabel!.font = .systemFont(ofSize: 13)
        view.lastUpdatedTimeLabel!.font = .systemFont(ofSize: 14)
        view.stateLabel!.textColor = .init(white: 0.584, alpha: 1)
        view.lastUpdatedTimeLabel!.textColor = .init(white: 0.584, alpha: 1)
        view.isAutomaticallyChangeAlpha = true
        view.lastUpdatedTimeLabel!.isHidden = true
        return view
    }()
    
    private lazy var gifHeader: RefreshGifHeader = {
        let view: RefreshGifHeader = RefreshGifHeader.init(refreshingTarget: self, refreshingAction: #selector(pull_loadNewData))
        view.stateLabel!.isHidden = true
        view.isAutomaticallyChangeAlpha = true
        view.lastUpdatedTimeLabel!.isHidden = true
        if let images = conf?.refreshingImages {
            view.refreshingImages = images
        }
        return view
    }()
    
    private lazy var footer: RefreshFotter = {
        let view: RefreshFotter = RefreshFotter.init(refreshingTarget: self, refreshingAction: #selector(loadMoreData))
        view.setTitle("上拉加载更多", for: .idle)
        view.setTitle("加载中...", for: .refreshing)
        view.setTitle("没有更多数据", for: .noMoreData)
        view.stateLabel!.font = .systemFont(ofSize: 13)
        view.stateLabel!.textColor = .init(white: 0.584, alpha: 1)
        return view
    }()
    
    private var blankType: BlankType = .fail {
        didSet {
            if self.conf?.blankData.isEmpty ?? true {
                blank = Blank.default(type: blankType)
            }else {
                let rech = Reachability.forInternetConnection()
                if let blank = conf?.blankData[blankType] {
                    if rech?.currentReachabilityStatus() == .NotReachable {
                        self.blank = conf?.blankData[.noNetwork]
                    }else {
                        self.blank = blank
                    }
                }else {
                    if rech?.currentReachabilityStatus() == .NotReachable {
                        blank = Blank.default(type: .noNetwork)
                    }else {
                        blank = Blank.default(type: blankType)
                    }
                }
            }
            
            self.blank?.tap = { [weak self] (tapGesture) in
                if self?.blank?.isAnimating == false {
                    self?.blank?.isAnimating = true
                    self?.listView?.reloadBlank()
                    self?.loadNewData()
                }
            }
            
            blank?.customBlankView = conf?.customBlankView
            listView?.setBlank(blank)
            listView?.reloadBlank()
        }
    }
    
    private var blank: Blank?
    
    private var lastItemCount: Int = 0
    
    @objc func loadMoreData() {
        if loadStatus != .idle {return}
        setStatus(.more)
        let loc: Int = Int(ceilf((Float((listView?.itemsCount() ?? 0) / (conf?.length ?? dataLengthDefault)))))
        setRange(NSMakeRange((loc > 0 ? loc : 1) * (conf?.length ?? dataLengthDefault), (conf?.length ?? dataLengthDefault)))
        listView?.loadMoreData()
    }
    
    public override init() {
        super.init()
        setStatus(.idle)
        setRange(NSMakeRange(0, (conf?.length ?? dataLengthMax)))
    }
}

private var kList = "kList"
private var kListClosure = "kListClosure"
private var kConf = "kConf"
private var kLoadStatus = "kLoadStatus"
private var kRange = "kRange"
private var kListView = "kListView"

extension UIScrollView {
    
    fileprivate var listBlock: ((_ list: List) -> Void)? {
        get {return objc_getAssociatedObject(self, &kListClosure) as? ((_ list: List) -> Void)}
        set {objc_setAssociatedObject(self, &kListClosure, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public var atList: List! {
        get {
            if let list = objc_getAssociatedObject(self, &kList) as? List {return list}
            let list = List()
            setAtList(list)
            return list
        }
    }

    private func setAtList(_ newValue: List) {
        objc_setAssociatedObject(self, &kList, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func updateListConf(_ block: ((_ conf: ListConf) -> Void)?) {
        let globalConf: ListConf = ListGlobalConf.share.conf?.copy() as! ListConf
        let conf: ListConf = self.atList.conf ?? globalConf
        if conf.length == 0 {
            let lentgh = ((conf.loadStyle == .header || conf.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
            conf.length = lentgh
        }
        self.atList.conf = conf;
        block?(conf)
    }

    public func loadListData(_ block: ((_ list: List) -> Void)?) {
        self.listBlock = block
        self.atList.listView = self
        let defaultConf: ListConf = ListGlobalConf.share.conf?.copy() as! ListConf
        self.atList.conf = self.atList.conf ?? defaultConf
        if self.atList.conf?.loadStrategy == .auto {
            if self.atList.conf?.loadStyle == .nothing || self.atList.conf?.loadStyle == .footer {
                self.atList.setStatus(.new)
                let lentgh = ((self.atList.conf?.loadStyle == .header || self.atList.conf?.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
                self.atList.setRange(NSMakeRange(0, self.atList.conf?.length ?? lentgh))
                self.listBlock?(self.atList)
            }else {
                self.atList.beginning()
            }
        }
    }

    fileprivate func loadNewData() {
        self.listBlock?(self.atList)
    }
    
    fileprivate func loadMoreData() {
        self.listBlock?(self.atList)
    }
}
