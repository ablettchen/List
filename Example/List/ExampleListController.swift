//
//  ExampleListController.swift
//  List
//
//  Created by ablett on 06/21/2019.
//  Copyright (c) 2019 ablett. All rights reserved.
//

import UIKit

class ExampleListController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var datas: [Example] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.init(white: 0.95, alpha: 1);
        
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []
        navigationItem.title = "Example"
        
        addDatas()
        
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
    
    func addDatas() -> Void {
        datas.removeAll()
        datas.append(Example(loadStrategy: .auto, loadType: .none_))
        datas.append(Example(loadStrategy: .auto, loadType: .new))
        datas.append(Example(loadStrategy: .auto, loadType: .more))
        datas.append(Example(loadStrategy: .auto, loadType: .all))
        
        datas.append(Example(loadStrategy: .manual, loadType: .none_))
        datas.append(Example(loadStrategy: .manual, loadType: .new))
        datas.append(Example(loadStrategy: .manual, loadType: .more))
        datas.append(Example(loadStrategy: .manual, loadType: .all))
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: NSStringFromClass(UITableViewCell.classForCoder()))
        cell.backgroundColor = ((indexPath.row % 2) == 0) ? .white : UIColor.lightGray.withAlphaComponent(0.1);
        cell.textLabel?.text = "\(datas[indexPath.row].title)"
        cell.textLabel?.textColor = UIColor.init(white: 0, alpha: 0.8)
        cell.textLabel?.font = .systemFont(ofSize: 14)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let example = datas[indexPath.row]
        let exampleController = ExampleController.init()
        
        exampleController.loadStrategy = example.loadStrategy
        exampleController.loadType = example.loadType
        exampleController.navigationItem.title = example.title as String
        
        navigationController?.pushViewController(exampleController, animated: true)
    }

}
