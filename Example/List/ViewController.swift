//
//  ViewController.swift
//  List
//
//  Created by ablett on 06/21/2019.
//  Copyright (c) 2019 ablett. All rights reserved.
//

import UIKit
import List
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /// add scrollView
        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        scrollView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        scrollView.updateListConf {
            (conf) in
//            conf.loadType = .all
//            conf.loadStrategy = .auto
//            conf.length = 40
        }
        
        scrollView.loadListData {
            (list) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

