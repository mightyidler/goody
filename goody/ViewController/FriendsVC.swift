//
//  FriendsVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKTalk
import KakaoSDKUser
import Firebase
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseStorage

struct Person {
    var favortite: Bool!
    var id: Int64!
    var nickname: String!
    var imageUrl: URL!
    var uuid: String!
}

struct feedUser{
    var uid: String!
    var nickname: String!
    var feedList: [product] = []
    var imageUrl: URL!
}

class FriendsVC: UIViewController, TabBarReselectHandling {

    @IBOutlet weak var wishlistCollectionView: UICollectionView!
    @IBOutlet weak var headerView: UIView!
    //@IBOutlet weak var emptyLabel: UILabel!
    var screenWidth: CGFloat!
    //loading states indicator
    var isLoading: Bool = true
    let storage = Storage.storage()
    var lastDocumentSnapshot: DocumentSnapshot!
    let selectFeedBack: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    //Header bar seperator
    let border = CALayer()
    var selectFriendIndex: Int = 0
    var ref: DatabaseReference!
    var feedUsers: [feedUser] = []
    
    var db: Firestore!
    var uid: String!
    
    func handleReselect() {
        self.wishlistCollectionView.setContentOffset(.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        ref = Database.database().reference()
        checkIfUserIsSignedIn()
        self.wishlistCollectionView.delegate = self
        self.wishlistCollectionView.dataSource = self
        screenWidth = UIScreen.main.bounds.size.width
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.wishlistCollectionView.refreshControl = UIRefreshControl()
        self.wishlistCollectionView.refreshControl?.alpha = 0.6
        self.wishlistCollectionView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.wishlistCollectionView.refreshControl?.beginRefreshing()

        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.headerView.frame.height - 1 , width: self.view.frame.width, height: 1)
        self.headerView.layer.addSublayer(border)
        
        loadFeedList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            if self.isLoading {
                self.wishlistCollectionView.refreshControl?.beginRefreshing()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            if self.isLoading {
                self.wishlistCollectionView.refreshControl?.endRefreshing()
            }
        }
    }
    
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        }
    }
    @objc func pullToRefresh(_ sender: Any) {
        DispatchQueue.main.async {
            self.feedUsers = []
            self.lastDocumentSnapshot = nil
            self.loadFeedList()
        }
    }
    
    private func checkIfUserIsSignedIn() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // user is signed in
                if let id = user?.uid {
                    self.uid = id
                }
                // go to feature controller
            } else {
                 // user is not signed in
                 // go to login controller
            }
        }
    }
    
    func loadFeedList() {
        isLoading = true
        var query: Query!
        if self.feedUsers.isEmpty {
                query = db.collection("users").limit(to: 3)
            } else {
                query = db.collection("users").start(afterDocument: lastDocumentSnapshot).limit(to: 3)
            }
        
        query.getDocuments { (snapshot, err) in
                if let err = err {
                    print("\(err.localizedDescription)")
                } else if snapshot!.isEmpty {
                    self.isLoading = false
                    return
                } else {
                    for document in snapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        if document.documentID != self.uid {
                            let nickname = (document.data()["nickname"])
                            self.loadLists(uid: document.documentID, nickname: nickname as! String)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.wishlistCollectionView.reloadData()
                        self.isLoading = false
                    })

                    self.lastDocumentSnapshot = snapshot!.documents.last
                }
            }
    }
    
    func loadLists(uid: String, nickname: String) {
        db.collection("users").document(uid).collection("wishList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var items: [product] = []
                for document in querySnapshot!.documents {
                    let dict = document.data()
                    if let link = dict["link"] as? String,
                       let image = dict["image"] as? String,
                       let mallName = dict["mallName"] as? String,
                       let price = dict["price"] as? String,
                       let title = dict["title"] as? String,
                       let category1 = (dict["category1"] ?? "") as? String,
                       let category2 = (dict["category2"] ?? "") as? String,
                       let category3 = (dict["category2"] ?? "") as? String {
                            let item = product.init(title: title, link: link, lprice: price, mallName: mallName, image: image, category1: category1, category2: category2, category3: category3)
                        print("product item: \(item)")
                        //self.feedList.append(item)
                        items.append(item)
                    }
                }
                
                let starsRef = self.storage.reference().child("profileImage/\(uid).jpg")
                starsRef.downloadURL { url, error in
                    if let error = error {
                        // Handle any errors
                        let user = feedUser(uid: uid, nickname: nickname, feedList: items, imageUrl: nil)
                        self.feedUsers.append(user)
                    } else {
                        // Get the download URL for 'images/stars.jpg'
                        let user = feedUser(uid: uid, nickname: nickname, feedList: items, imageUrl: url)
                        self.feedUsers.append(user)
                    }
                    DispatchQueue.main.async {
                        print("load is over")
                        self.isLoading = false
                        self.wishlistCollectionView.reloadData()
                        self.wishlistCollectionView.refreshControl?.endRefreshing()
                    }
                }
                
                
                
            }
        }
        
        
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        if scrollView == self.wishlistCollectionView {
            searchBarCheck(contentOffset: scrollView.contentOffset.y)
        }
        if offsetY > contentHeight - scrollView.frame.height - 50 {
            if !isLoading {
                loadFeedList()
            }
        }
    }
    
}

extension FriendsVC: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.feedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.feedUsers[section].feedList.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "userHeaderView", for: indexPath) as? UserHeaderView {
                
                headerView.nicknameLabel.text = self.feedUsers[indexPath.section].nickname
                
                if let imageView = headerView.profileImage {
                    if let url = self.feedUsers[indexPath.section].imageUrl {
                        let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                            |> ResizingImageProcessor(referenceSize: CGSize(width: imageView.frame.width, height: imageView.frame.height), mode: .aspectFill)
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
                        
                    } else {
                        imageView.image = nil
                    }
                }
                
                return headerView
            }
            
        }
        return UICollectionReusableView()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //WISH CELL
        guard let wishCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendWishCell", for: indexPath) as? FriendWishCell else {
            return UICollectionViewCell()
        }
        if !self.feedUsers.isEmpty {
            if !(self.feedUsers[indexPath.section].feedList.isEmpty) {
                let cellWidth = wishCell.layer.frame.width
                let item = feedUsers[indexPath.section].feedList[indexPath.row]
                
                if let imageView = wishCell.itemImage {
                    let url = item.image
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
                
                if let title = wishCell.itemTitleLabel {
                    title.text = item.title
                }
                
                if let label = wishCell.itemMallNameLabel {
                    label.text = item.mallName
                }
                
                if let price = wishCell.itemPriceLabel {
                    price.text = item.lprice.wonRepresentation
                }
                return wishCell
            }
        }
        
        return wishCell
    }
    
    
}

extension FriendsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        gotoProductDatailVC(section: indexPath.section, row: indexPath.row)
    }
    
    func gotoProductDatailVC(section: Int, row: Int) {
        guard let productVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductVC") as? ProductVC else {
            return
        }
        let selectProduct = self.feedUsers[section].feedList[row]
        let title = selectProduct.title
        let url = selectProduct.link
        let price = selectProduct.lprice
        let image = selectProduct.image
        let mallName = selectProduct.mallName
        let category1 = selectProduct.category1
        let category2 = selectProduct.category2
        let category3 = selectProduct.category3
        
        let item = product.init(title: title, link: url, lprice: price, mallName: mallName, image: image, category1: category1, category2: category2, category3: category3)
        productVC.item = item
        show(productVC, sender: nil)
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



extension FriendsVC {
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


extension FriendsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === self.wishlistCollectionView {
            let devide: CGFloat = 2
            let minus: CGFloat = 28
            let cellSize: CGFloat = screenWidth / devide - minus
            let contentsHeight: CGFloat = 110
            return CGSize(width: cellSize, height: cellSize + contentsHeight)
        }
        return CGSize(width: 60, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView === self.wishlistCollectionView {
            return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        }
        return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(16)
    }
    
}
