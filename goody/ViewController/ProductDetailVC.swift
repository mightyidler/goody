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

class ProductDetailVC: UIViewController, WKUIDelegate {
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
    var activityViewController : UIActivityViewController!
    //haptic feedback
    let feedBack: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var image: UIImage!
    
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.feedBack.prepare()
        webView.uiDelegate = self

//        tabBarView.layer.borderWidth = 1;
//        tabBarView.layer.borderColor = UIColor(named: "SeperatorColor")?.cgColor
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; ja-jp) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
        
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
                color: UIColor(named: "ShadowColor")!,
                alpha: 1.0,
                x: 0,
                y: 0,
                blur: 10,
                spread: 0)
        }
    }
    
    func initItemMessageView() {
        itemSaveView.layer.opacity = 0.0
        itemMaskView.layer.cornerRadius = 19
        itemSaveView.layer.applySketchShadow(
            color: UIColor(named: "ShadowColor")!,
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
                    self.saveButton.isSelected = false
                    self.feedBack.notificationOccurred(.success)
                }
            } else {
                if appendProduct(product: product) {
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
    
    @IBAction func dismissButtonAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func setActivityViewController() {
        
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
    
    func fetchPricesData() {
        if let product = product {
            let urlAddress = product.link
            
            guard let url = URL(string: "https://search.shopping.naver.com/detail/detail.nhn?cat_id=50002334&nv_mid=21192710714") else {
                return
            }
            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                
                let doc : Document = try SwiftSoup.parse(html)
                let priceChart: Elements = try doc.select("price_chart")
                
                print(try priceChart.html())
            } catch {
                
            }
            
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
        
        //append object
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

