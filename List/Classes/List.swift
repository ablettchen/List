//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank
import Reachability


@objc public enum LoadStyle : Int, CustomStringConvertible {
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

@objc public enum LoadStrategy : Int, CustomStringConvertible {
    case auto
    case manual
    
    public var description: String {
        switch self {
        case .auto      : return "auto"
        case .manual    : return "manual"
        }
    }
}

@objc public enum LoadStatus : Int, CustomStringConvertible {
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

@objc public enum LoadHeaderStyle : Int, CustomStringConvertible {
    case normal
    case gif
    
    public var description: String {
        switch self {
        case .normal : return "normal"
        case .gif    : return "gif"
        }
    }
}

private var dataLengthDefault: Int = 20
private var dataLengthMax: Int = 1000

public class ListConf: NSObject {
    
    public var customBlankView: UIView?
    
    public var loadStyle: LoadStyle = .header
    public var loadStrategy: LoadStrategy = .auto
    public var length: Int = dataLengthMax
    
    public var blankData: [BlankType:Blank]!
    
    public var loadHeaderStyle: LoadHeaderStyle = .normal
    public var refreshingImages: [UIImage] = []
    
    public func reset() -> Void {
        customBlankView = nil
        loadStyle = .header
        loadStrategy = .auto
        length = dataLengthMax
        blankData = [.fail      : Blank.defaultBlank(type: .fail),
                     .noData    : Blank.defaultBlank(type: .noData),
                     .noNetwork : Blank.defaultBlank(type: .noNetwork)]
        
        
        var gifImages: [UIImage] = []
        for index in 1...23 {
            if let image = UIImage(named: "refreshGif_\(index)", in: List.listBundle(), compatibleWith: nil) {
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

private var kConf = "kConf"
private var kLoadStatus = "kLoadStatus"
private var kRange = "kRange"
private var kListView = "kListView"

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
    
    public var loadStatus: LoadStatus! {
        get {
            if let status = objc_getAssociatedObject(self, &kLoadStatus) as? LoadStatus {return status}
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
            let lentgh = ((conf?.loadStyle == .header || conf?.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
            let range = NSMakeRange(0, conf?.length ?? lentgh)
            setRange(range)
            return range
        }
    }
    
    fileprivate func setRange(_ range: NSRange) -> Void {
        objc_setAssociatedObject(self, &kRange, range, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate class func listBundle() -> Bundle? {
        if let bundlePath = Bundle(for: List.self).resourcePath?.appending("/List.bundle") {
            return Bundle(path: bundlePath)
        }
        return nil
    }
    
    public func finish(error: Error?) -> Void {
        
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
        lastItemCount = listView?.itemsCount()
    }
    
    @objc public func pull_loadNewData() -> Void {
        guard loadStatus == .idle else {return}
        setStatus(.new)
        let length = ((self.conf?.loadStyle == .header || self.conf?.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
        setRange(NSMakeRange(0, self.conf?.length ?? length))
        lastItemCount = 0
        listView?.loadNewData()
    }
    
    @objc public func loadNewData() -> Void {
        if conf?.loadStrategy == .manual && (conf?.loadStyle == .header || conf?.loadStyle == .all)  {
            beginning()
        }else {
            pull_loadNewData()
        }
    }
    
    @objc public func reloadData() -> Void {
        let sel: Selector = NSSelectorFromString("reloadData")
        if listView?.responds(to: sel) ?? false {
            listView?.perform(sel, with: nil)
        }else {
            listView?.setNeedsDisplay()
        }
    }
    
    public func beginning() -> Void {
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
    
    private var blankType: BlankType! {
        didSet {
            if self.conf?.blankData.isEmpty ?? true {
                blank = Blank.defaultBlank(type: blankType)
            }else {
                let rech = Reachability.forInternetConnection()
                if let b = conf?.blankData[blankType] {
                    if rech?.currentReachabilityStatus() == .NotReachable {
                        blank = conf?.blankData[.noNetwork]
                    }else {
                        blank = b
                    }
                }else {
                    if rech?.currentReachabilityStatus() == .NotReachable {
                        blank = Blank.defaultBlank(type: .noNetwork)
                    }else {
                        blank = Blank.defaultBlank(type: blankType)
                    }
                }
            }
            
            self.blank?.tap = { [weak self] (tapGesture) in
                if self?.blank.isAnimating == false {
                    self?.blank.isAnimating = true
                    self?.listView?.reloadBlank()
                    self?.loadNewData()
                }
            }
            
            blank.customBlankView = conf?.customBlankView
            listView?.setBlank(blank)
            listView?.reloadBlank()
        }
    }
    
    private var blank: Blank!
    
    private var lastItemCount: Int!
    
    @objc func loadMoreData() -> Void {
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
            return { [weak self] (cls) in
                let conf = ListConf()
                cls(conf)
                self?.conf = conf
            }
        }
    }
}

private var kList = "kList"
private var kListClosure = "kListClosure"

public typealias ListClosure = (_ list: List) -> Void
public typealias ListConfClosure = (_ conf: ListConf) -> Void

extension UIScrollView {
    
    fileprivate var listBlock: ListClosure? {
        get {return objc_getAssociatedObject(self, &kListClosure) as? ListClosure}
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

    private func setAtList(_ newValue: List) -> Void {
        objc_setAssociatedObject(self, &kList, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func updateListConf(listConfClosure: ListConfClosure?) -> Void {
        let defaultConf: ListConf = ListDefaultConf.share.conf?.copy() as! ListConf
        let conf: ListConf = self.atList.conf ?? defaultConf
        if conf.length == 0 {
            let lentgh = ((conf.loadStyle == .header || conf.loadStyle == .nothing) ? dataLengthMax : dataLengthDefault)
            conf.length = lentgh
        }
        self.atList.conf = conf;
        listConfClosure?(conf)
    }

    public func loadListData(_ listClosure: @escaping ListClosure) -> Void {
        self.listBlock = listClosure
        self.atList.listView = self
        let defaultConf: ListConf = ListDefaultConf.share.conf?.copy() as! ListConf
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

    fileprivate func loadNewData() -> Void {
        self.listBlock?(self.atList)
    }
    
    fileprivate func loadMoreData() -> Void {
        self.listBlock?(self.atList)
    }
}
