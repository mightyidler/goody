//
//  SceneDelegate.swift
//  goody
//
//  Created by mightyidler on 2020/09/29.
//

import UIKit
import CoreData
import KakaoSDKAuth
import KakaoSDKUser
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var kakaoUserID: Int64!
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    var ref: DatabaseReference = Database.database().reference()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        loadKakaoUserData()
        guard let _ = (scene as? UIWindowScene) else { return }
        if let shortcutItem = connectionOptions.shortcutItem {
            guard let tabBarController = window?.rootViewController as? UITabBarController else {
                return
            }
            switch shortcutItem.type {
            case "Search":
                tabBarController.selectedIndex = 1
            case "Bag":
                tabBarController.selectedIndex = 0
            default:
                tabBarController.selectedIndex = 0
            }
        }
    }
    
    func loadKakaoUserData() {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                if let user = user {
                    self.kakaoUserID = user.id
                }
            }
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let tabBarController = window?.rootViewController as? UITabBarController else {
            return
        }
        switch shortcutItem.type {
        case "Search":
            tabBarController.selectedIndex = 1
        case "Bag":
            tabBarController.selectedIndex = 0
        default:
            tabBarController.selectedIndex = 0
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        
        if UserDefaults.standard.value(forKey: "listChanged") as! Bool == true {
            if let id = self.kakaoUserID {
                list = { return self.fetch() }()
                appendFireBase()
            }
        } 
    }
    
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SavedItem")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    func loadKakaoID() {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                if let user = user {
                    self.kakaoUserID = user.id
                }
            }
        }
    }
    
    func appendFireBase() {
        if let id = self.kakaoUserID {
            let item = self.ref.child(String(id)).child("wishList")
            item.removeValue()
            self.ref.child("\(id)").setValue("")
            if self.list.count != 0 {
                print(list)
                for index in 0...self.list.count - 1 {
                    guard let key = item.childByAutoId().key else { return }
                    let listItem = self.list[index]
                    let dict: NSDictionary = ["mallName": listItem.value(forKey: "mallName"),
                                              "title": listItem.value(forKey: "title"),
                                              "image" : listItem.value(forKey: "image"),
                                              "link" : listItem.value(forKey: "url"),
                                              "price" : listItem.value(forKey: "price")]
                    
                    //append
                    let update = [key: dict]
                    item.updateChildValues(update)
                }
            }
            UserDefaults.standard.setValue(false, forKey: "listChanged")
            UserDefaults.standard.synchronize()
        }
    }
}

