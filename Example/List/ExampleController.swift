//
//  ExampleController.swift
//  List
//
//  Created by ablett on 06/21/2019.
//  Copyright (c) 2019 ablett. All rights reserved.
//

import UIKit
import Blank
import List
import SnapKit

class ExampleController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var loadMode: LoadMode = .auto
    public var loadComponent: LoadComponent = .header
    var addData = true
    private var datas: [String] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.init(white: 0.95, alpha: 1);
        
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []
        
        if loadMode == .manual {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "手动加载", style: .plain, target: self, action: #selector(loadDatas))
        }
        
        // 具体列表配置（可选，如不设置，则取 ListGlobalConf，ListGlobalConf 未设置时取 conf）
        tableView.updateListConf { [weak self] (conf) in
            guard self != nil else {return}
            conf.loadMode = self!.loadMode
            conf.loadComponent = self!.loadComponent
            conf.length = 20
            conf.blankData = [
                .fail : Blank(
                    type: .fail,
                    image: Blank.image(type: .fail),
                    title: "绘本数据加载失败",
                    desc: "10015",
                    tap: nil
                )
            ];
        }
        
        // 加载数据
        tableView.loadListData { [weak self] (list) in
            let strongSelf = self
            self?.requestData(["offset" : list.range.location, "number" : list.range.length], { [weak strongSelf] (error, models) in
                if list.loadStatus == .new {strongSelf?.datas.removeAll()}
                if let datas = models {
                    strongSelf?.datas += datas
                }
                list.finish(error: error)
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func loadDatas() -> Void {
        tableView.atList.loadNewData()
    }
    
    private func requestData(_ parameters: [String : Int], _ finished: @escaping ((_ error: NSError?, _ datas: [String]?) -> Void)) -> Void {
        print("parameters:\(parameters)")
        var models = [String]()
        let range = NSRange.init(location: parameters["offset"]!, length: parameters["number"]!)
        
        if self.loadComponent == .nothing || self.loadComponent == .header {
            for i in 0..<range.length {
                models.append("\(range.location + i + 1)")
            }
        }else if self.loadComponent == .footer || self.loadComponent == .all {
            if range.location < 2 {
                for i in 0..<range.length {
                    models.append("\(range.location + i + 1)")
                }
            }else {
                for i in 0...1 {
                    models.append("\(range.location + i + 1)")
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.addData {
                finished(nil, models)
            }else {
                finished(NSError.init(domain: self.description, code: 405, userInfo: [NSLocalizedDescriptionKey : "fail"]), nil)
            }
            self.addData = true
        }
    }
    
    private lazy var tableView: UITableView = {
        let view = UITableView.init(frame: CGRect.init(), style: .plain)
        view.dataSource = self
        view.delegate = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.classForCoder()))
        view.separatorStyle = .none
        view.backgroundColor = .clear
        view.tableFooterView = UIView()
        view.rowHeight = 44.0
        view.estimatedRowHeight = 0.0
        view.estimatedSectionHeaderHeight = 0.0
        view.estimatedSectionFooterHeight = 0.0
        view.layer.borderWidth = 3.0
        view.layer.borderColor = UIColor.red.withAlphaComponent(0.5).cgColor
        view.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 34, right: 0)
        self.view.addSubview(view)
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return view;
    }()
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: NSStringFromClass(UITableViewCell.classForCoder()))
        cell.selectionStyle = .none
        cell.backgroundColor = ((indexPath.row % 2) == 0) ? .white : UIColor.lightGray.withAlphaComponent(0.1);
        cell.textLabel?.text = "\(datas[indexPath.row])"
        return cell
    }
    
}
