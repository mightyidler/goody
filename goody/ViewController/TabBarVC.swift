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

        // is first time for launch
        self.delegate = self
        
        tabBar.isTranslucent = true
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage() // add this if you want remove tabBar separator
        tabBar.barTintColor = .systemBackground
        tabBar.backgroundColor = .systemBackground // here is your tabBar color
        tabBar.layer.backgroundColor = UIColor.systemBackground.cgColor
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
}

