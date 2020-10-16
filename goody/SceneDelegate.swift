//
//  SceneDelegate.swift
//  goody
//
//  Created by mightyidler on 2020/09/29.
//

import UIKit
import CoreData
//import KakaoSDKAuth
//import KakaoSDKUser
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
//    private lazy var list: [NSManagedObject] = {
//        return self.fetch()
//    }()
    
    var uid: NSString!
    var db: Firestore!
    var ref: DocumentReference? = nil
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        checkIfUserIsSignedIn()
        
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
    
    private func checkIfUserIsSignedIn() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // user is signed in
                if let id = user?.uid {
                    self.uid = id as NSString
                }
                // go to feature controller
            } else {
                 // user is not signed in
                 // go to login controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.window?.rootViewController = loginVC
                self.window?.makeKeyAndVisible()
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
//        if let url = URLContexts.first?.url {
//            if (AuthApi.isKakaoTalkLoginUrl(url)) {
//                _ = AuthController.handleOpenUrl(url: url)
//            }
//        }
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
        
//        if UserDefaults.standard.value(forKey: "listChanged") as! Bool == true {
//            if let id = self.uid {
//                list = { return self.fetch() }()
//                appendFireBase()
//            }
//        }
    }
    
//    func fetch() -> [NSManagedObject] {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let context = appDelegate.persistentContainer.viewContext
//        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SavedItem")
//        let result = try! context.fetch(fetchRequest)
//        return result
//    }
    
//    func appendFireBase() {
//        if let id = self.uid {
//            print("saved")
//
//            //item.removeValue()
//            db.collection("users").document("\(id)").collection("wishList").getDocuments() { (querySnapshot, err) in
//                if let err = err {
//                    print("Error getting documents: \(err)")
//                } else {
//                    for document in querySnapshot!.documents {
//                        print("\(document.documentID) => \(document.data())")
//                        self.db.collection("users").document("\(id)").collection("wishList").document("\(document.documentID)").delete() { err in
//                            if let err = err {
//                                print("Error removing document: \(err)")
//                            } else {
//                                print("Document successfully removed!")
//                                return
//
//                            }
//                        }
//                    }
//                }
//
//
//                if self.list.count != 0 {
//                    print(self.list)
//                    for index in 0...self.list.count - 1 {
//                        let listItem = self.list[index]
//                        let dict: [String: Any] = ["mallName": listItem.value(forKey: "mallName"),
//                                                  "title": listItem.value(forKey: "title"),
//                                                  "image" : listItem.value(forKey: "image"),
//                                                  "link" : listItem.value(forKey: "url"),
//                                                  "price" : listItem.value(forKey: "price")]
//
//                        //append
//                        self.db.collection("users").document("\(id)").collection("wishList").addDocument(data: dict) { err in
//                            if let err = err {
//                                print("Error writing document: \(err)")
//                            } else {
//                                print("Document successfully written!")
//                            }
//                        }
//                    }
//                }
//
//
//            }
//
//
//
//            UserDefaults.standard.setValue(false, forKey: "listChanged")
//            UserDefaults.standard.synchronize()
//        }
//    }
}

