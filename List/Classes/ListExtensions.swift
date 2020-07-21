//
//  ListExtensions.swift
//  Blank
//
//  Created by ablett on 2020/7/20.
//


extension Bundle {
    class func list() -> Bundle? {
        if let bundlePath = Bundle(for: List.self).resourcePath?.appending("/List.bundle") {
            return Bundle(path: bundlePath)
        }
        return nil
    }
}
