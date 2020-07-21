//
//  ListGlobalConf.swift
//  List
//
//  Created by ablett on 2020/7/20.
//

public class ListGlobalConf: NSObject {
    
    public class var share: ListGlobalConf {
        struct Static {
            static let instance: ListGlobalConf = ListGlobalConf()
        }
        return Static.instance
    }
    
    public var conf: ListConf?
    
    public var setupConf: (_ closure: (_ conf: ListConf) -> Void) -> Void {
        get {
            return { [weak self] (cls) in
                let conf = ListConf()
                cls(conf)
                self?.conf = conf
            }
        }
    }
}
