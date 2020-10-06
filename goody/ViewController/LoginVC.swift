//
//  LoginVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKUser

class LoginVC: UIViewController {

    @IBOutlet weak var kakaoLoginButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    


    @IBAction func skipLoginButtonAction(_ sender: UIButton) {
        gotoTabBarVC(skip: true)
    }
    
    @IBAction func kakaoLoginButtonAction(_ sender: UIButton) {
        kakaoAuthApi()
    }
    
    func gotoTabBarVC(skip: Bool) {
        guard !skip else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC")
            let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
            tabBarVC.view.addSubview(overlayView)
            self.view.window!.rootViewController = tabBarVC
            UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                overlayView.alpha = 0
            }, completion: { finished in
                overlayView.removeFromSuperview()
            })
        }
    }
    
    
    func kakaoAuthApi() {
        if (AuthApi.isKakaoTalkLoginAvailable()) {
            AuthApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                else {
                    print("loginWithKakaoTalk() success.")

                    //do something
                    _ = oauthToken
                    print(oauthToken)
                    self.gotoTabBarVC(skip: false)
                }
            }
        } else {
            AuthApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        print("loginWithKakaoAccount() success.")
                        print(oauthToken)
                        //do something
                         _ = oauthToken
                        self.gotoTabBarVC(skip: false)
                    }
                }
        }
    }
}
