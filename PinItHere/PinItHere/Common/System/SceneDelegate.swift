//
//  SceneDelegate.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-22.
//

import UIKit
import SwiftUI

// MARK: - System
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var hasAppearedOnce: Bool = false

    /// 入口
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        initializeWindowAndRootVC(windowScene)
    }

    /// 运行时从URL打开
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        guard let urlContext = URLContexts.first else {
//            return
//        }
//        let url = urlContext.url
        
//        wheneverLaunchAppNeedToDo()
    }
    
    /// 即将进入前台
    func sceneWillEnterForeground(_ scene: UIScene) {
        defer {
            hasAppearedOnce = true
        }
        
        wheneverLaunchAppNeedToDo()
        
    }

    /// 已经进入前台
    func sceneDidBecomeActive(_ scene: UIScene) {

    }
    
    /// 进入后台的瞬间
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    /// 杀死应用
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }


}

// MARK: - Initialize
extension SceneDelegate {
    /// 初始化Window & RootVC
    private func initializeWindowAndRootVC(_ windowScene: UIWindowScene) {
        let rootView = ARComposerView()
        let hostingVC = UIHostingController(rootView: rootView)
        
        let tmpWindow = UIWindow(windowScene: windowScene)
        tmpWindow.rootViewController = hostingVC
        window = tmpWindow
        window?.makeKeyAndVisible()
    }
    
    /// 全局刷新统一调用
    private func wheneverLaunchAppNeedToDo() {
        
    }
    
}

