//
//  BaseNavigationC.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-13.
//

import UIKit

public class BaseNavigationC: UINavigationController {
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count > 0 {
            // 如果不是 rootVC，且是 tab bar 的子控制器，则设置隐藏 tabBar
            viewController.hidesBottomBarWhenPushed = true
        }
        
        super.pushViewController(viewController, animated: animated)
        
    }

}
