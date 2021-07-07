//
//  ListExtensions.swift
//  Blank
//
//  Created by ablett on 2020/7/20.
//


extension Bundle {
    
    static var list: Bundle? {
        if let bundlePath = Bundle(for: List.self).resourcePath?.appending("/List.bundle") {
            return Bundle(path: bundlePath)
        }
        return nil
    }
}

extension UIScrollView {
    
    public private(set) var atList: List! {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.list, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let list = objc_getAssociatedObject(self, &AssociatedKeys.list) as? List else {
                let alist = List()
                objc_setAssociatedObject(self, &AssociatedKeys.list, alist, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return alist
            }
            return list
        }
    }
    
    public func loadListData(_ block: ((_ list: List) -> Void)?) {
        loadBlock = block
        atList.listView = self
        let defaultConf: ListConf = ListGlobalConf.share.conf?.copy() as! ListConf
        atList.conf = atList.conf ?? defaultConf
        if atList.conf?.loadMode == .auto {
            if atList.conf?.loadComponent == .nothing || atList.conf?.loadComponent == .footer {
                atList.loadStatus = .new
                let lentgh = ((atList.conf?.loadComponent == .header || atList.conf?.loadComponent == .nothing) ? dataLengthMax : dataLengthDefault)
                atList.range = NSMakeRange(0, atList.conf?.length ?? lentgh)
                loadBlock?(atList)
            }else {
                atList.beginning()
            }
        }
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
}

extension UIScrollView {
    
    internal func loadNewData() {
        loadBlock?(atList)
    }
    
    internal func loadMoreData() {
        loadBlock?(atList)
    }
    
    private var loadBlock: ((_ list: List) -> Void)? {
        get {return objc_getAssociatedObject(self, &AssociatedKeys.loadBlock) as? ((_ list: List) -> Void)}
        set {objc_setAssociatedObject(self, &AssociatedKeys.loadBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    private struct AssociatedKeys {
        static var list = "list"
        static var loadBlock = "loadBlock"
    }
}
