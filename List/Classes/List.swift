//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank
import Reachability


@objc public enum LoadComponent: Int, CustomStringConvertible {
    
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

@objc public enum LoadMode: Int, CustomStringConvertible {
    
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
            guard let conf = conf else {
                return
            }
            switch conf.loadComponent {
            case .nothing, .footer:
                listView?.mj_header = nil
            case .header, .all:
                switch conf.loadHeaderStyle {
                case .normal:
                    listView?.mj_header = header
                case .gif:
                    listView?.mj_header = gifHeader
                }
            }
        }
    }
    
    public fileprivate(set) var loadStatus: LoadStatus = .idle
    
    public fileprivate(set) var range: NSRange = NSMakeRange(0, dataLengthMax)
    
    public func finish(error: Error?) {
        
        if blank?.isAnimating ?? false {
            blank?.isAnimating = false
        }
        
        listView?.reloadBlank()
        
        switch loadStatus {
        case .idle:
            listView?.mj_header?.endRefreshing()
            listView?.mj_footer?.resetNoMoreData()
            listView?.mj_footer?.endRefreshing()
        case .new:
            listView?.mj_header?.endRefreshing()
            listView?.mj_footer?.resetNoMoreData()
            if listView?.itemsCount() == 0 {
                blankType = (error == nil) ? .noData : .fail
            }else {
                switch conf?.loadComponent {
                case .footer, .all:
                    if (listView?.itemsCount() ?? 0) >= (conf?.length ?? dataLengthDefault) {
                        listView?.mj_footer = footer
                    }else {
                        listView?.mj_footer = nil
                    }
                default: break
                }
            }
        case .more:
            if ((listView?.itemsCount() ?? 0) - lastItemCount) < range.length {
                listView?.mj_footer?.endRefreshingWithNoMoreData()
            }else {
                listView?.mj_footer = footer
                listView?.mj_footer?.endRefreshing()
            }
        default:
            break
        }
        
        reloadData()
        loadStatus = .idle
        lastItemCount = listView?.itemsCount() ?? 0
    }
    
    @objc public func pull_loadNewData() {
        guard loadStatus == .idle else {
            return
        }
        loadStatus = .new
        let isPaging = conf?.loadComponent == .footer || conf?.loadComponent == .all
        let length = isPaging ? dataLengthDefault : dataLengthMax
        range = NSMakeRange(0, conf?.length ?? length)
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
        let isHaveHeader = conf?.loadComponent == .header || conf?.loadComponent == .all
        if conf?.loadMode == .manual && isHaveHeader  {
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
        view.stateLabel?.isHidden = true
        view.isAutomaticallyChangeAlpha = true
        view.lastUpdatedTimeLabel?.isHidden = true
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
            if let conf = conf {
                if conf.blankData.isEmpty {
                    blank = Blank.default(type: blankType)
                }else {
                    let rech = Reachability.forInternetConnection()
                    if rech?.currentReachabilityStatus() == .NotReachable {
                        if let b = conf.blankData[.noNetwork] {
                            blank = b
                        }else {
                            blank = Blank.default(type: .noNetwork)
                        }
                    }else {
                        if let b = conf.blankData[blankType] {
                            blank = b
                        }else {
                            blank = Blank.default(type: blankType)
                        }
                    }
                }
            }
            blank?.tap = { [weak self] (tapGesture) in
                if self?.blank?.isAnimating == false {
                    self?.blank?.isAnimating = true
                    self?.listView?.reloadBlank()
                    self?.loadNewData(animated: false)
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
        guard loadStatus == .idle else {
            return
        }
        loadStatus = .more
        let loc: Int = Int(ceilf((Float((listView?.itemsCount() ?? 0) / (conf?.length ?? dataLengthDefault)))))
        let length: Int = conf?.length ?? dataLengthDefault
        range = NSMakeRange((loc > 0 ? loc : 1) * length, length)
        listView?.loadMoreData()
    }
    
    public override init() {
        super.init()
        loadStatus = .idle
        let length: Int = conf?.length ?? dataLengthMax
        range = NSMakeRange(0, length)
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
        let conf: ListConf = atList.conf ?? globalConf
        if conf.length == 0 {
            let lentgh = ((conf.loadComponent == .header || conf.loadComponent == .nothing) ? dataLengthMax : dataLengthDefault)
            conf.length = lentgh
        }
        atList.conf = conf;
        block?(conf)
    }
    
    public func loadListData(_ block: ((_ list: List) -> Void)?) {
        listBlock = block
        atList.listView = self
        let defaultConf: ListConf = ListGlobalConf.share.conf?.copy() as! ListConf
        atList.conf = atList.conf ?? defaultConf
        if atList.conf?.loadMode == .auto {
            if atList.conf?.loadComponent == .nothing || atList.conf?.loadComponent == .footer {
                atList.loadStatus = .new
                let lentgh = ((atList.conf?.loadComponent == .header || atList.conf?.loadComponent == .nothing) ? dataLengthMax : dataLengthDefault)
                atList.range = NSMakeRange(0, atList.conf?.length ?? lentgh)
                listBlock?(atList)
            }else {
                atList.beginning()
            }
        }
    }
    
    fileprivate func loadNewData() {
        listBlock?(atList)
    }
    
    fileprivate func loadMoreData() {
        listBlock?(atList)
    }
}
