//
//  WishVC.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit
import CoreData
import UserNotifications
import Alamofire
import Kingfisher
import CoreHaptics
import Firebase
import KakaoSDKAuth
import KakaoSDKUser
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class WishVC: UIViewController, TabBarReselectHandling{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var gotoSearchPageButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    let notifiFeedBack: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var impactFeedBack: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator()
    var screenWidth: CGFloat!
    var isCellEditing: Bool = false

    private var nowVC: UIViewController!
    
    var uid: NSString!
    var db: Firestore!
    var ref: DatabaseReference!

    //Header bar seperator
    let border = CALayer()
    var kakaoUserID: Int64!
    
    //recent search list from core data
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    func handleReselect() {
        self.collectionView.setContentOffset(.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        checkIfUserIsSignedIn()
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        self.notifiFeedBack.prepare()
        self.impactFeedBack.prepare()
        self.emptyView.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        screenWidth = UIScreen.main.bounds.size.width
        gotoSearchPageButton.layer.cornerRadius = 10
        
        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.header.frame.size.height - 1, width: self.header.frame.size.width, height: 1)
        self.header.layer.addSublayer(border)
        
        self.collectionView.refreshControl = UIRefreshControl()
        self.collectionView.refreshControl?.alpha = 0.6
        self.collectionView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.collectionView.refreshControl?.beginRefreshing()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        collectionView.addGestureRecognizer(gesture)
    }
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {_,_ in})
        UIApplication.shared.registerForRemoteNotifications()
        self.isCellEditing = false
        self.editButton.isSelected = false
        
        self.list = {return self.fetch() }()
        self.collectionView.reloadData()
        setTotalAmount(animate: false)
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
    
    
    func setTotalAmount(animate: Bool) {
        if animate {
            self.headerLabel.pushTransition(0.4)
        }
        if self.list.count != 0 {
            var totalAmount: Int = 0
            for item in list {
                if ((item.value(forKey: "price") as? String) != nil) {
                    guard let value = Int(item.value(forKey: "price") as! String) else { return }
                    totalAmount += value
                }
            }
            self.headerLabel.text = "\(totalAmount)".wonRepresentation
        } else {
            self.headerLabel.text = "위시리스트"
        }
    }
    
    @objc func pullToRefresh(_ sender: Any) {
        self.list = {return self.fetch() }()
    }
    
    @IBAction func editButtonAction(_ sender: UIButton) {
        if isCellEditing {
            isCellEditing = false
            self.editButton.isSelected = false
        } else {
            self.impactFeedBack = UIImpactFeedbackGenerator(style: .medium)
            self.impactFeedBack.impactOccurred()
            isCellEditing = true
            self.editButton.isSelected = true
        }
        self.collectionView.reloadData()
        setTotalAmount(animate: false)
    }
    
    @IBAction func gotoSearchPageButtonAction(_ sender: UIButton) { 
        self.tabBarController?.selectedIndex = 1
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let collectionView = collectionView else {
            return
        }
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            if self.isCellEditing == false {
                self.impactFeedBack = UIImpactFeedbackGenerator(style: .medium)
                self.impactFeedBack.impactOccurred()
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "전체 삭제", style: .destructive , handler:{ (UIAlertAction)in
                    DispatchQueue.main.async {
                        self.removeAll()
                    }
                }))
                alert.addAction(UIAlertAction(title: "위시리스트 편집", style: .default , handler:{ (UIAlertAction)in
                    DispatchQueue.main.async {
                        self.editButton.isSelected = true
                        self.isCellEditing = true
                        self.collectionView.reloadData()
                        self.setTotalAmount(animate: false)
                    }
                }))
                alert.addAction(UIAlertAction(title: "상품 페이지", style: .default , handler:{ (UIAlertAction)in
                    self.gotoProductDatailVC(indexPath: targetIndexPath.row)
                }))
                alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler:{ (UIAlertAction)in
                }))
                
                self.present(alert, animated: true, completion: {
                })
            }
            
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

//function for Core Data
extension WishVC {
    //fetch list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SavedItem")
        let result = try! context.fetch(fetchRequest)
        self.collectionView.refreshControl?.endRefreshing()
        return result
    }
    
    //delete selected object from core data
    func delete(object: NSManagedObject) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        context.delete(object)
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    
    func appendAllProduct() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            do {
                for index in 0...list.count - 1 {
                    let object = NSEntityDescription.insertNewObject(forEntityName: "SavedItem", into: context)
                    object.setValue(list[index].value(forKey: "title"), forKey: "title")
                    object.setValue(list[index].value(forKey: "image"), forKey: "image")
                    object.setValue(list[index].value(forKey: "url"), forKey: "url")
                    object.setValue(list[index].value(forKey: "price"), forKey: "price")
                    object.setValue(list[index].value(forKey: "mallName"), forKey: "mallName")
                    object.setValue(list[index].value(forKey: "category1"), forKey: "category1")
                    object.setValue(list[index].value(forKey: "category2"), forKey: "category2")
                    object.setValue(list[index].value(forKey: "category3"), forKey: "category3")
                    try context.save()
                }
                try context.save()
                return true
            } catch {
                return false
            }
        } catch {
            context.rollback()
            return false
        }
        
    }
        
    //remove selected item
    @objc func removeProduct(_ sender: UIButton) {
        self.notifiFeedBack.notificationOccurred(.success)
        let tag = self.list.count - sender.tag - 1
        if let url = self.list[tag].value(forKey: "url") as? String {
            getItemFirebaseId(url: url)
        }
        
        if self.list.count >= tag  && tag >= 0 {
            let record = self.list[tag]
            if self.delete(object: record) {
                let indexPath = IndexPath(item: sender.tag, section: 0)
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItems(at:[indexPath])
                    self.list.remove(at: tag)
                }, completion: {_ in
                    self.collectionView.reloadData()
                    self.setTotalAmount(animate: true)
                })
            }
        } else {
            self.collectionView.reloadData()
        }
    }
    
    //remove all
    @objc func removeAllProduct(_ sender: UIButton) {
        removeAll()
    }
    
    func removeAll() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        firebaseRemoveAll()
        do {
            try context.execute(deleteRequest)
            try context.save()
            list = { return self.fetch() }()
            self.collectionView.reloadData()
            setTotalAmount(animate: true)
            self.notifiFeedBack.notificationOccurred(.success)
        } catch {
            context.rollback()
        }
    }
    
    
    //firebase remove and remove all
    
    func getItemFirebaseId(url: String) {
        if let id = uid {
            db.collection("users").document("\(id)").collection("wishList").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        //print("\(document.documentID) => \(document.data())")
                        let dict = document.data()
                        if let link = dict["link"] as? String {
                            if link == url {
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
    func firebaseRemoveAll() {
        if let id = uid {
            db.collection("users").document("\(id)").collection("wishList").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        self.db.collection("users").document("\(id)").collection("wishList").document("\(document.documentID)").delete() { err in
                            if let err = err {
                                print("Error removing document: \(err)")
                            } else {
                                print("Document successfully removed!")
                                return
                                
                            }
                        }
                    }
                }
            }
            
        }
    }
    
}

//collectionview delegate
extension WishVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return self.isCellEditing
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("source \(sourceIndexPath.row) destination \(destinationIndexPath.row)")
        let item = list.remove(at: list.count - sourceIndexPath.row - 1)
        list.insert(item, at: list.count - destinationIndexPath.row)
        
        DispatchQueue.main.async {
            self.appendAllProduct()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        gotoProductDatailVC(indexPath: indexPath.row)
    }
    
    func gotoProductDatailVC(indexPath: Int) {
        guard let productVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductVC") as? ProductVC else {
            return
        }
        let selectProduct = self.list[self.list.count - indexPath - 1]
        let title = selectProduct.value(forKey: "title") as! String
        let url = selectProduct.value(forKey: "url") as! String
        let price = selectProduct.value(forKey: "price") as! String
        let image = selectProduct.value(forKey: "image") as! String
        let mallName = selectProduct.value(forKey: "mallName") as! String
        let category1 = selectProduct.value(forKey: "category1") ?? ""
        let category2 = selectProduct.value(forKey: "category2") ?? ""
        let category3 = selectProduct.value(forKey: "category3") ?? ""
        
        let item = product.init(title: title, link: url, lprice: price, mallName: mallName, image: image, category1: category1 as! String, category2: category2 as! String, category3: category3 as! String)
        
        productVC.item = item
        show(productVC, sender: indexPath)
    }
    
    //cell highlight
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }
    }
    
    //cell unhighlight
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
}

extension WishVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //didn't login in kakao
        //guard self.kakaoUserID != nil else {
        if self.list.count == 0 {
            DispatchQueue.main.async {
                self.emptyView.isHidden = false
            }
        } else {
            if !self.emptyView.isHidden {
                self.emptyView.isHidden = true
            }
        }
        return self.list.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let wishCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WishCell", for: indexPath) as! WishCell
        let cellWidth = wishCell.layer.frame.width
        
        var itemTitle: String!
        var itemImage: String!
        var itemMallName: String!
        var itemPrice: String!
        
        let product = self.list[self.list.count - indexPath.row - 1]
        itemTitle = (product.value(forKey: "title") as? String)?.stringByDecodingHTMLEntities
        itemImage = product.value(forKey: "image") as? String
        itemMallName = product.value(forKey: "mallName") as? String
        itemPrice = product.value(forKey: "price") as? String
        
        if let imageView = wishCell.productImage {
            if let url = itemImage {
                if let url = URL(string: url) {
                    let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: cellWidth, height: cellWidth), mode: .aspectFill)
                    imageView.kf.indicatorType = .activity
                    imageView.kf.setImage(
                        with: url,
                        options: [
                            .processor(processor),
                            .transition(.fade(0.1)),
                            .scaleFactor(UIScreen.main.scale),
                            .cacheMemoryOnly
                        ]
                    )
                }
            }
            
        }
        
        if let title = wishCell.productTitle, let text = itemTitle {
            title.text = text as? String
        }
        
        if let label = wishCell.mallNameLabel, let mallName = itemMallName {
            label.text = mallName as? String
        }
        
        if let price = wishCell.productPrice, let value = itemPrice {
            price.text = (value as! String).wonRepresentation
        }
        
        if let deleteButton = wishCell.deleteButton {
            deleteButton.tag = indexPath.row
            if self.isCellEditing {
                wishCell.shakeCell()
                deleteButton.isHidden = false
                deleteButton.addTarget(self, action: #selector(removeProduct(_:)), for: .touchUpInside)
            } else {
                deleteButton.isHidden = true
            }
            
        }
        
        return wishCell
    }
    
    
}


extension WishVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let devide: CGFloat = 2
        let minus: CGFloat = 28
        let cellSize: CGFloat = screenWidth / devide - minus
        let contentsHeight: CGFloat = 110
        return CGSize(width: cellSize, height: cellSize + contentsHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
    
    
}

extension WishVC {
    //call every time when scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView {
            searchBarCheck(contentOffset: scrollView.contentOffset.y)
        }
        
    }
    //check is bar at the top
    func searchBarCheck(contentOffset: CGFloat) {
        if contentOffset < 10.0 {
            //is top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 0.0
            })
        } else {
            //is not top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 1.0
            })
        }
    }
}
