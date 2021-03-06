//
//  AppDelegate.swift
//  List
//
//  Created by ablett on 06/21/2019.
//  Copyright (c) 2019 ablett. All rights reserved.
//

import UIKit
import List
import Blank

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 列表配置（可选，如不设置，取默认）
        ListGlobalConf.share.setupConf { (conf) in
            conf.loadComponent = .all
            conf.loadMode = .auto
            conf.length = 20
            conf.blankData = [
                .fail : Blank(
                    type: .fail,
                    image: Blank.image(.fail),
                    title: "请求失败",
                    desc: "10010",
                    tap: nil
                ),
                .noData : Blank(
                    type: .noData,
                    image: Blank.image(.fail),
                    title: "没有数据",
                    desc: "10011",
                    tap: nil
                ),
                .noNetwork : Blank(
                    type: .noNetwork,
                    image: Blank.image(.fail),
                    title: "没有网络",
                    desc: "10012",
                    tap: nil)
            ];
            conf.loadHeaderStyle = .gif
        }
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        let navigationController = UINavigationController.init(rootViewController: ExampleListController())
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

