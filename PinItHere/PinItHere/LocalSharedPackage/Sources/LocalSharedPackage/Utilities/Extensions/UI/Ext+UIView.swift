//
//  Ext+UIView.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-02.
//

import Foundation
import UIKit

// MARK: - Data
extension UIView {
    static var safeAreaTopInset: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 20
    }
    
    static var safeAreaBottomInset: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
    }
    
}

// MARK: - Nib
extension UIView {
    class func fromNib(nibName: String? = nil) -> Self {
        return self.fromNib(nibName: nibName, type: self)
    }

    class func fromNib<T: UIView>(nibName: String? = nil, type: T.Type) -> T {
        return self.fromNib(nibName: nibName, type: T.self)!
    }

    class func fromNib<T: UIView>(nibName: String? = nil, type: T.Type) -> T? {
        var view: T?
        var name: String

        if let nibName = nibName {
            name = nibName
        } else {
            name = self.nibName
        }

        if let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil) {
            for nibView in nibViews {
                if let tog = nibView as? T {
                    view = tog
                }
            }
        }
        return view
    }

    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }

    class var nibName: String {
        return "\(self)".components(separatedBy: ".").first ?? ""
    }

    class var nib: UINib? {
        if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }

    class func loadFromNibNamed(nibNamed: String, bundle: Bundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }
}

extension UITableView {
    func registerCellFromNib(nibName: String) {
        self.register(UINib(nibName: nibName, bundle:nil), forCellReuseIdentifier: nibName)
    }
    
    func reloadDataWithoutScrolling(anchorIndexPath: IndexPath?) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation { [weak self] in
                guard let self = self else { return }
                
                // 一. 刷新前 anchorCell 的相对位置（如果存在）
                var offsetToAnchor: CGFloat = 0
                if let indexPath = anchorIndexPath,
                   let anchorCell = self.cellForRow(at: indexPath) {
                    offsetToAnchor = anchorCell.frame.origin.y - self.contentOffset.y
                }
                
                self.reloadData()
                self.layoutIfNeeded()
                
                // 二. 刷新后重新获取 anchorCell
                if let indexPath = anchorIndexPath,
                   let newAnchorCell = self.cellForRow(at: indexPath) {
                    
                    let newAnchorOrigin = newAnchorCell.frame.origin.y
                    let newOffsetY = newAnchorOrigin - offsetToAnchor
                    self.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: false)
                    
                }
            }
        }
        
    }
}


extension UICollectionView {
    func registerCellFromNib(nibName: String) {
        self.register(UINib(nibName: nibName, bundle:nil), forCellWithReuseIdentifier: nibName)
    }
}

// MARK: - Animation
extension UIView {
    public static let AnimationDuration = 0.15
    
    public func addHeartbeat(completion: (() -> Void)?) {
        UIView.animate(withDuration: UIView.AnimationDuration,
                       animations: { [weak self] in
            guard let `self` = self else { return }
            
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
        }, completion: { _ in
            UIView.animate(withDuration: UIView.AnimationDuration) { [weak self] in
                guard let `self` = self else { return }
                
                transform = .identity
                completion?()
            }
        })
    }
    
    static func performWithAnimation(_ animations: () -> Void, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        animations()
        CATransaction.commit()
    }
    
}


