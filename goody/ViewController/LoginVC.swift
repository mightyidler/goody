//
//  LoginVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKUser
import Firebase

class LoginVC: UIViewController {

    @IBOutlet weak var kakaoLoginButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
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
        
        //sync kakao id to firebase
        loadKakaoUserData()
        
        
        //go to tabbar view
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
    
    func loadKakaoUserData() {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                if let user = user {
                    self.appendFirebaseUser(id: user.id)
                }
            }
        }
    }
    
    func appendFirebaseUser(id: Int64) {
        //로컬데이터와 파이어베이스 데이터의 동기화 필요
        //self.ref.child("\(id)").setValue("")
    }
    
    
    func kakaoAuthApi() {
        if (AuthApi.isKakaoTalkLoginAvailable()) {
            AuthApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                else {
                    print("loginWithKakaoTalk() success.")
                    self.gotoTabBarVC(skip: false)
                }
            }
        } else {
            AuthApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        self.gotoTabBarVC(skip: false)
                    }
                }
        }
    }
    
    func loadFromFireBase() {
        
    }
    
}
