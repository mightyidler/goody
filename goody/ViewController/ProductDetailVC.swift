//
//  ProductDetailVC.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit
import WebKit
import CoreData
import CoreHaptics
import SwiftSoup
import Kingfisher
import Lottie
import Firebase
import KakaoSDKAuth
import KakaoSDKUser
import FirebaseCore
import FirebaseFirestore

class ProductDetailVC: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var webViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tabBarView: UIToolbar!
    
    @IBOutlet weak var itemSaveView: UIView!
    @IBOutlet weak var itemMaskView: UIView!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemStatusLabel: UILabel!
    
    var product: product!
    var lastBagIndex: Int!
    
    var uid: NSString!
    var db: Firestore!
    
    var activityViewController : UIActivityViewController!
    //haptic feedback
    let feedBack: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var image: UIImage!
    
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.feedBack.prepare()
        webView.uiDelegate = self
        checkIfUserIsSignedIn()
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; ja-jp) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
        webView.configuration.preferences.javaScriptEnabled = true
        
        if let product = product {
            let url = product.link
            print(url)
            let requestUrl = URL(string: url)
            let request = URLRequest(url: requestUrl!)
            
            webView.load(request)
            
            self.checkBag(link: url)
            //fetchPricesData()
        }
        
        initItemMessageView()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            itemSaveView.layer.applySketchShadow(
                color: UIColor(named: "ShadowColor2")!,
                alpha: 1.0,
                x: 0,
                y: 0,
                blur: 10,
                spread: 0)
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
            }
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
//        if UserDefaults.standard.value(forKey: "listChanged") as! Bool == true {
//            self.loadKakaoUserData()
//        }
        
    }
    
    
    func initItemMessageView() {
        itemSaveView.layer.opacity = 0.0
        itemMaskView.layer.cornerRadius = 19
        itemSaveView.layer.applySketchShadow(
            color: UIColor(named: "ShadowColor2")!,
            alpha: 1.0,
            x: 0,
            y: 0,
            blur: 10,
            spread: 0)
        
        if let product = product {
            let imageUrl = product.image
            let title = product.title
            let price = product.lprice.wonRepresentation
            
            itemTitleLabel.text = title
            itemPriceLabel.text = price
            
            if let cellImage = itemImageView {
                let url = URL(string: imageUrl)
                let processor = DownsamplingImageProcessor(size: cellImage.bounds.size)
                    |> ResizingImageProcessor(referenceSize: CGSize(width: itemImageView.bounds.width, height: itemImageView.bounds.height), mode: .aspectFill)
                cellImage.kf.indicatorType = .activity
                cellImage.kf.setImage(
                    with: url,
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(0.1)),
                        .cacheMemoryOnly
                    ]
                )
            }
        }
        
    }
    
    //check this liked
    func checkBag(link: String) {
        for (index, product) in self.list.enumerated() {
            let url = product.value(forKey: "url") as? String
            if link == url {
                self.saveButton.isSelected = true
                self.lastBagIndex = index
                print(index)
            }
        }
        
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        if let product = product {
            if self.saveButton.isSelected {
                if self.removeFromBag() {
                    getItemFirebaseId()
                    self.saveButton.isSelected = false
                    self.feedBack.notificationOccurred(.success)
                }
            } else {
                if appendProduct(product: product) {
                    firebaseAppend()
                    self.saveButton.isSelected = true
                    self.feedBack.notificationOccurred(.success)
                    
                    UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseIn,.allowUserInteraction] ,animations: {
                        self.itemSaveView.layer.opacity = 1.0
                    }, completion: { finished in
                        UIView.animate(withDuration: 0.3, delay: 3.0, animations: {
                            self.itemSaveView.layer.opacity = 0.0
                        })
                    })
                    let animationView = AnimationView(name:"Confetti")
                    self.view.insertSubview(animationView, at: 1)
                    animationView.frame = CGRect(x: 0, y: 0, width: self.webView.frame.size.width, height: self.webView.frame.size.height)
                    animationView.isUserInteractionEnabled = false
                    animationView.center = self.view.center
                    animationView.contentMode = .scaleAspectFit
                    animationView.play { (finished) in
                        animationView.removeFromSuperview()
                    }
                }
                
            }
        }
    }
    
    func firebaseAppend() {
        let dict: [String: Any] = ["mallName": product.mallName,
                                   "title": product.title,
                                   "image" : product.image,
                                   "link" : product.link,
                                   "price" : product.lprice,
                                   "category1": product.category1,
                                   "category2": product.category2,
                                   "category3": product.category3]
        
        //append
        if let id = uid {
            db.collection("users").document("\(id)").collection("wishList").addDocument(data: dict) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    
    func getItemFirebaseId() {
        if let id = uid {
            db.collection("users").document("\(id)").collection("wishList").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        //print("\(document.documentID) => \(document.data())")
                        let dict = document.data()
                        if let link = dict["link"] as? String {
                            if link == self.product.link {
                                print(document.documentID)
                                self.firebaseRemove(id: id as String, itemId: document.documentID)
                            }
                        }
                    }
                }
            }
        }
    }
    func firebaseRemove(id: String, itemId: String) {
        db.collection("users").document("\(id)").collection("wishList").document("\(itemId)").delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    
    
    @IBAction func dismissButtonAction(_ sender: UIBarButtonItem) {
        //self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButtonAction(_ sender: UIBarButtonItem) {
        // Setting description
        let firstActivityItem = self.product.title
        
        // Setting url
        let secondActivityItem : NSURL = NSURL(string: self.product.link)!
        
        
        var activityItems: [Any] = [firstActivityItem, secondActivityItem]
        
        do {
            let url = URL(string: self.product.image)
            let data = try Data(contentsOf: url!)
            let image: UIImage = UIImage(data: data)!
            activityItems.append(image)
        } catch {
            
        }
        
        activityViewController = UIActivityViewController(
            activityItems: activityItems, applicationActivities: nil)
        // This lines is for the popover you need to show in iPad
        //activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        
        // This line remove the arrow of the popover to show in iPad
        //activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        //activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Pre-configuring activity items
        activityViewController.activityItemsConfiguration = [
            UIActivity.ActivityType.message
        ] as? UIActivityItemsConfigurationReading
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToFacebook
        ]
        
        activityViewController.isModalInPresentation = true
        
        self.present(activityViewController, animated: true, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func gotoSafariButtonAction(_ sender: UIBarButtonItem) {
        if let url = URL(string: self.product.link) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}


extension ProductDetailVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.webViewIndicator.startAnimating()
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.webViewIndicator.stopAnimating()
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.webViewIndicator.stopAnimating()
        }
    }
}


//function for Core Data
extension ProductDetailVC {
    //fetch list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SavedItem")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    //remove liked book
    func removeFromBag() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let object = self.list[self.lastBagIndex]
        context.delete(object)
        do {
            try context.save()
            list = { return self.fetch() }()
            checkBag(link: self.product.link)
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //append searched item to core data
    func appendProduct(product: product) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "SavedItem", into: context)
        
        // url price title image
        object.setValue(product.title, forKey: "title")
        object.setValue(product.link, forKey: "url")
        object.setValue(product.image, forKey: "image")
        object.setValue(product.lprice, forKey: "price")
        object.setValue(product.mallName, forKey: "mallName")
        object.setValue(product.category1, forKey: "category1")
        object.setValue(product.category2, forKey: "category2")
        object.setValue(product.category3, forKey: "category3")

        //append object core base
        do {
            try context.save()
            self.list.append(object)
            list = { return self.fetch() }()
            self.checkBag(link: self.product.link)
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
}

extension ProductDetailVC: WKUIDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) { _ in
            completionHandler()
        }
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


