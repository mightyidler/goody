//
//  WishVC.swift
//  goody
//
//  Created by mightyidler on 2020/09/30.
//

import UIKit
import CoreData
import Alamofire
import Kingfisher
import CoreHaptics

class WishVC: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var gotoSearchPageButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var header: UIView!
    
    let notifiFeedBack: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var impactFeedBack: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator()
    var screenWidth: CGFloat!
    var isCellEditing: Bool = false
    private var nowVC: UIViewController!
    
    //Header bar seperator
    let border = CALayer()
    
    //recent search list from core data
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        list = { return self.fetch() }()
        self.isCellEditing = false
        self.editButton.isSelected = false
        self.collectionView.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
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
    
    
    //remove selected recent search item
    @objc func removeProduct(_ sender: UIButton) {
        let tag = self.list.count - sender.tag - 1
        //let tag = sender.tag
        let record = self.list[tag]
        if self.delete(object: record) {
            
            let indexPath = IndexPath(item: tag, section: 0)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at:[indexPath])
            }, completion:nil)
            
            self.list.remove(at: tag)
            list = { return self.fetch() }()
            self.notifiFeedBack.notificationOccurred(.success)
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
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            list = { return self.fetch() }()
            self.collectionView.reloadData()
            self.notifiFeedBack.notificationOccurred(.success)
        } catch {
            context.rollback()
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
        
        //        let item = list.remove(at: sourceIndexPath.row)
        //        list.insert(item, at: destinationIndexPath.row)
        
        DispatchQueue.main.async {
            self.appendAllProduct()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        gotoProductDatailVC(indexPath: indexPath.row)
    }
    
    func gotoProductDatailVC(indexPath: Int) {
        guard let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailVC else {
            return
        }
        let selectProduct = self.list[self.list.count - indexPath - 1]
        //let selectProduct = self.list[indexPath]
        //image price title url
        let title = selectProduct.value(forKey: "title") as! String
        let url = selectProduct.value(forKey: "url") as! String
        let price = selectProduct.value(forKey: "price") as! String
        let image = selectProduct.value(forKey: "image") as! String
        let mallName = selectProduct.value(forKey: "mallName") as! String
        
        let item = product.init(title: title, link: url, lprice: price, mallName: mallName, image: image)
        
        productDetailVC.product = item
        show(productDetailVC, sender: indexPath)
    }
    
    //cell highlight
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
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
        if list.count == 0 {
            DispatchQueue.main.async {
                self.emptyView.isHidden = false
            }
        } else {
            if !self.emptyView.isHidden {
                self.emptyView.isHidden = true
            }
        }
        return list.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let wishCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WishCell", for: indexPath) as! WishCell
        let cellWidth = wishCell.layer.frame.width
        let product = self.list[self.list.count - indexPath.row - 1]
        //let product = self.list[indexPath.row]
        
        if let imageView = wishCell.productImage {
            if let url = product.value(forKey: "image") {
                if let url = URL(string: url as! String) {
                    let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: cellWidth, height: cellWidth), mode: .aspectFill)
                    imageView.kf.indicatorType = .activity
                    imageView.kf.setImage(
                        with: url,
                        options: [
                            .processor(processor),
                            .transition(.fade(0.1)),
                            .scaleFactor(UIScreen.main.scale),
                            .cacheOriginalImage
                        ]
                    )
                }
            }
            
        }
        
        if let title = wishCell.productTitle, let text = product.value(forKey: "title") {
            title.text = text as? String
        }
        
        if let label = wishCell.mallNameLabel, let mallName = product.value(forKey: "mallName") {
            label.text = mallName as? String
        }
        
        if let price = wishCell.productPrice, let value = product.value(forKey: "price") {
            price.text = (value as! String).wonRepresentation
        }
        
        if let deleteButton = wishCell.deleteButton {
            if self.isCellEditing {
                wishCell.shakeCell()
                deleteButton.isHidden = false
                deleteButton.tag = indexPath.row
                deleteButton.addTarget(self, action: #selector(removeProduct(_:)), for: .touchUpInside)
            } else {
                deleteButton.isHidden = true
            }
            
        }
        
        return wishCell
    }
    
    
}

//extension WishVC: UITabBarControllerDelegate {
//
//        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//            let tabBarIndex = tabBarController.selectedIndex
//            print(tabBarIndex)
//            if tabBarIndex == 0{
//                self.collectionView.setContentOffset(CGPoint.zero, animated: true)
//            }
//            self.nowVC = viewController
//        }
//}

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