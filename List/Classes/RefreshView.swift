//
//  RefreshView.swift
//  Blank
//
//  Created by ablett on 2019/6/25.
//

import Foundation
import UIKit
import MJRefresh


public class RefreshHeader: MJRefreshStateHeader {
    lazy var arrowView: UIImageView = {
        let view = UIImageView(image: Bundle.mj_arrowImage())
        self.addSubview(view)
        return view
    }()
    
    public var activityIndicatorViewStyle: UIActivityIndicatorView.Style! {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        self.addSubview(view)
        return view
    }()
    

    public override var state: MJRefreshState {
        didSet {
            if oldValue == state {return}
            super.state = self.state
            if self.state == .idle {
                if oldValue == .refreshing {
                    UIView.animate(withDuration: TimeInterval(MJRefreshSlowAnimationDuration), animations: {
                        self.loadingView.alpha == 0.0
                    }) { (finished) in
                        if self.state != .idle {return}
                        self.loadingView.alpha == 1.0
                        self.loadingView.stopAnimating()
                        self.loadingView.isHidden = false
                    }
                }else {
                    self.loadingView.stopAnimating()
                    self.arrowView.isHidden = false
                    UIView.animate(withDuration: TimeInterval(MJRefreshSlowAnimationDuration)) {
                        self.arrowView.transform = .identity
                    }
                }
            }else if self.state == .pulling {
                self.loadingView.stopAnimating()
                self.arrowView.isHidden = false
                UIView.animate(withDuration: TimeInterval(MJRefreshSlowAnimationDuration)) {
                    self.arrowView.transform = .init(rotationAngle: CGFloat(0.000001 - M_PI))
                }
            }else if self.state == .refreshing {
                self.loadingView.alpha = 1.0
                self.loadingView.startAnimating()
                self.arrowView.isHidden = true
            }
        }
    }
    
    
    public override func prepare() {
        super.prepare()
        self.activityIndicatorViewStyle = .gray
    }
    
    public override func placeSubviews() {
        super.placeSubviews()
        var arrowCenterX: Float = Float(self.mj_w * 0.5)
        if !self.stateLabel.isHidden {
            var stateWidth: Float = Float(self.stateLabel.mj_textWith())
            var timeWidth: Float = 0.0
            if !self.lastUpdatedTimeLabel.isHidden {
                timeWidth = Float(self.lastUpdatedTimeLabel.mj_textWith())
            }
            var textWidth: Float = max(stateWidth, timeWidth)
            arrowCenterX = arrowCenterX - (textWidth / 2 + Float(self.labelLeftInset))
        }
        var arrowCenterY: Float = Float(self.mj_h * 0.5)
        var arrowCenter: CGPoint  = CGPoint.init(x: CGFloat(arrowCenterX), y: CGFloat(arrowCenterY))
        
        if self.arrowView.constraints.count == 0 {
            self.arrowView.mj_size = self.arrowView.image?.size ?? CGSize()
            self.arrowView.center = arrowCenter;
        }
        
        if self.loadingView.constraints.count == 0 {
            self.loadingView.center = arrowCenter;
        }
        
        self.arrowView.tintColor = self.stateLabel.textColor;
    }
}


public class RefreshFotter: MJRefreshAutoStateFooter {
    lazy var arrowView: UIImageView = {
        let view = UIImageView(image: Bundle.mj_arrowImage())
        self.addSubview(view)
        return view
    }()
    
    public var activityIndicatorViewStyle: UIActivityIndicatorView.Style! {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        self.addSubview(view)
        return view
    }()
    
    public override var state: MJRefreshState {
        didSet {
            if oldValue == state {return}
            super.state = self.state
            
            if self.state == .idle || self.state == .noMoreData {
                self.loadingView.stopAnimating()
            }else {
                self.loadingView.startAnimating()
            }
        }
    }
    
    public override func prepare() {
        super.prepare()
        self.activityIndicatorViewStyle = .gray
    }
    
    public override func placeSubviews() {
        super.placeSubviews()
        
        if self.constraints.count == 0 {return}
        var loadingCenterX: Float = Float(self.mj_w * 0.5)
        if !self.isRefreshingTitleHidden {
            loadingCenterX = loadingCenterX - Float((self.stateLabel.mj_textWith() * 0.5 + self.labelLeftInset))
        }
        var loadingCenterY: Float = Float(self.mj_h * 0.5)
        self.loadingView.center = CGPoint.init(x: CGFloat(loadingCenterX), y: CGFloat(loadingCenterY))
    }
}
