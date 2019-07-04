//
//  ViewController.swift
//  List
//
//  Created by ablett on 06/21/2019.
//  Copyright (c) 2019 ablett. All rights reserved.
//

import UIKit
import Blank
import List
import SnapKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.extendedLayoutIncludesOpaqueBars = false
        self.edgesForExtendedLayout = []
        self.navigationItem.title = "List"
        
        tableView.updateListConf { (conf) in
            conf.loadType = .all
            conf.length = 20
            conf.blankData = [.fail : Blank(type: .fail,
                                            image: Blank.defaultBlankImage(type: .fail),
                                            title: .init(string: "绘本数据加载失败"),
                                            desc: .init(string: "10015"),
                                            tap: nil)];
        }
        
        tableView.loadListData { (list) in
            self.requestData(["offset" : list.range.location, "number" : list.range.length], { (error, models) in
                if list.status == .new {self.datas.removeAll()}
                if models != nil {self.datas += models!}
                list.finish(error: error)
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            // 若 conf.loadStrategy = .manual, 则需要手动调用 loadNewData()
            //self.tableView.atList.loadNewData();
        };
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var addData = false
    private var datas: [String] = [];
    
    private func requestData(_ parameters: [String : Int], _ finished: @escaping ((_ error: NSError?, _ datas: [String]?) -> Void)) -> Void {
        print("parameters:\(parameters)")
        var models = [String]()
        let range = NSRange.init(location: parameters["offset"]!, length: parameters["number"]!)
        if range.location < 2 {
            for i in 0..<range.length {
                models.append("\(range.location + i + 1)")
            }
        }else {
            for i in 0...1 {
                models.append("\(range.location + i + 1)")
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
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
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.backgroundColor = .clear
        view.tableFooterView = UIView.init()
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
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        cell.backgroundColor = ((indexPath.row % 2) == 0) ? .white:
            UIColor.lightGray.withAlphaComponent(0.1);
        cell.textLabel?.text = "\(datas[indexPath.row])"
        return cell
    }
    
}
