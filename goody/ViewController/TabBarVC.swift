//
//  TabBarVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKUser
import CoreHaptics

protocol TabBarReselectHandling {
    func handleReselect()
}
class TabBarVC: UITabBarController {
    var impactFeedBack: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue(false, forKey: "listChanged")
        UserDefaults.standard.synchronize()
        // is first time for launch
        self.delegate = self
        if !UserDefaults.exists(key: "FirstLaunch") {
            kakaoLoginCheck()
        }
        UserDefaults.standard.set(false, forKey: "FirstLaunch")
        UserDefaults.standard.synchronize()
        
        tabBar.isTranslucent = true
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage() // add this if you want remove tabBar separator
        tabBar.barTintColor = .systemBackground
        tabBar.backgroundColor = .systemBackground // here is your tabBar color
        tabBar.layer.backgroundColor = UIColor.systemBackground.cgColor
    }
    
    func kakaoLoginCheck() {
        UserApi.shared.accessTokenInfo {(accessTokenInfo, error) in
            if let error = error {
                print(error)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(loginVC, animated: true, completion: nil)
            }
            else {
                _ = accessTokenInfo
            }
        }
    }
}

extension TabBarVC: UITabBarControllerDelegate {
    // UITabBarDelegate
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        self.impactFeedBack.prepare()
//        self.impactFeedBack = UIImpactFeedbackGenerator(style: .light)
//        self.impactFeedBack.impactOccurred()
    }

    // UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected view controller")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let navigationController = viewController as? UINavigationController else { return true }
        guard navigationController.viewControllers.count <= 1, let handler = navigationController.viewControllers.first as? TabBarReselectHandling else { return true }
        if tabBarController.selectedViewController === viewController {
            handler.handleReselect()
        }
        
        return true
        }
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        guard
//            let tabViewControllers = tabBarController.viewControllers,
//            let targetIndex = tabViewControllers.firstIndex(of: viewController),
//            let targetView = tabViewControllers[targetIndex].view,
//            let currentViewController = selectedViewController,
//            let currentIndex = tabViewControllers.firstIndex(of: currentViewController)
//            else { return false }
//
//        if currentIndex != targetIndex {
//            animateToView(targetView, at: targetIndex, from: currentViewController.view, at: currentIndex)
//        }
//
//        return true
//    }

}

//private extension TabBarVC {
//
//    func animateToView(_ toView: UIView, at toIndex: Int, from fromView: UIView, at fromIndex: Int) {
//        // Position toView off screen (to the left/right of fromView)
//        let screenWidth = UIScreen.main.bounds.size.width
//        let offset = toIndex > fromIndex ? screenWidth : -screenWidth
//
//        toView.frame.origin = CGPoint(
//            x: toView.frame.origin.x + offset,
//            y: toView.frame.origin.y
//        )
//
//        fromView.superview?.addSubview(toView)
//
//        // Disable interaction during animation
//        view.isUserInteractionEnabled = false
//
//        UIView.animate(
//            withDuration: 0.33,
//            delay: 0.0,
//            usingSpringWithDamping: 0.88,
//            initialSpringVelocity: 0.9,
//            options: .curveEaseInOut,
//            animations: {
//                // Slide the views by -offset
//                fromView.center = CGPoint(x: fromView.center.x - offset, y: fromView.center.y)
//                toView.center = CGPoint(x: toView.center.x - offset, y: toView.center.y)
//            },
//            completion: { _ in
//                // Remove the old view from the tabbar view.
//                fromView.removeFromSuperview()
//                self.selectedIndex = toIndex
//                self.view.isUserInteractionEnabled = true
//            }
//        )
//    }
//
//}
