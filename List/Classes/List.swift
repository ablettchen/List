//
//  List.swift
//  List
//
//  Created by ablett on 2019/6/24.
//

import UIKit
import Blank
import Reachability


@objc public enum LoadComponent: Int {
    case nothing
    case header
    case footer
    case all
}

@objc public enum LoadMode: Int {
    case auto
    case manual
}

@objc public enum LoadStatus: Int {
    case idle
    case new
    case more
}

@objc public enum LoadHeaderStyle: Int {
    case normal
    case gif
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
    
    public internal(set) var loadStatus: LoadStatus = .idle
    public internal(set) var range: NSRange = NSMakeRange(0, dataLengthMax)
    internal weak var listView: UIScrollView?
    private var blank: Blank?
    private var lastItemCount: Int = 0
    
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
                    blank = Blank.default(blankType)
                }else {
                    if Reachability.forInternetConnection()?.currentReachabilityStatus() == .NotReachable {
                        if let b = conf.blankData[.noNetwork] {
                            blank = b
                        }else {
                            blank = Blank.default(.noNetwork)
                        }
                    }else {
                        if let b = conf.blankData[blankType] {
                            blank = b
                        }else {
                            blank = Blank.default(blankType)
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
            listView?.atBlank = blank
            listView?.reloadBlank()
        }
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
    
    @objc
    public func reloadData() {
        let sel: Selector = NSSelectorFromString("reloadData")
        if listView?.responds(to: sel) ?? false {
            listView?.perform(sel, with: nil)
        }else {
            listView?.layoutIfNeeded()
        }
    }
    
    public func finish(error: Error?, completion: (() -> Void)? = nil) {
        
        if blank?.isAnimating ?? false {
            blank?.isAnimating = false
        }
        
        listView?.reloadBlank()
        
        switch loadStatus {
        case .idle, .new :
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
        
        UIView.animate(withDuration: 0, animations: { [weak self] in
            self?.reloadData()
        }, completion: { [weak self] _ in
            self?.loadStatus = .idle
            self?.lastItemCount = self?.listView?.itemsCount() ?? 0
            completion?()
        })
    }
    
    public override init() {
        super.init()
        loadStatus = .idle
        let length: Int = conf?.length ?? dataLengthMax
        range = NSMakeRange(0, length)
    }
}

extension List {
    
    internal func beginning() {
        if conf?.loadHeaderStyle == .normal {
            header.beginRefreshing();
        }else if conf?.loadHeaderStyle == .gif {
            gifHeader.beginRefreshing();
        }
    }
    
    @objc
    private func pull_loadNewData() {
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
    
    @objc
    private func loadMoreData() {
        guard loadStatus == .idle else {
            return
        }
        loadStatus = .more
        let loc: Int = Int(ceilf((Float((listView?.itemsCount() ?? 0) / (conf?.length ?? dataLengthDefault)))))
        let length: Int = conf?.length ?? dataLengthDefault
        range = NSMakeRange((loc > 0 ? loc : 1) * length, length)
        listView?.loadMoreData()
    }
}
