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

struct Person {
    var favortite: Bool!
    var id: Int64!
    var nickname: String!
    var imageUrl: URL!
    var uuid: String!
}

class FriendsVC: UIViewController {

    @IBOutlet weak var friendsCollectionView: UICollectionView!
    @IBOutlet weak var wishlistCollectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!
    var screenWidth: CGFloat!
    //loading states indicator
    var isLoading: Bool = true
    let selectFeedBack: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    //Header bar seperator
    let border = CALayer()
    var selectFriendIndex: Int = 0
    var ref: DatabaseReference!
    var wishList: [product] = []
    var friendsArray: [Person] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        self.friendsCollectionView.delegate = self
        self.friendsCollectionView.dataSource = self
        
        self.wishlistCollectionView.delegate = self
        self.wishlistCollectionView.dataSource = self
        screenWidth = UIScreen.main.bounds.size.width
        
        self.wishlistCollectionView.refreshControl = UIRefreshControl()
        self.wishlistCollectionView.refreshControl?.alpha = 0.6
        self.wishlistCollectionView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.wishlistCollectionView.refreshControl?.beginRefreshing()
        

        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.friendsCollectionView.frame.height - 1 , width: self.view.frame.width, height: 1)
        self.friendsCollectionView.layer.addSublayer(border)
        
        loadFrendsList()
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
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadFriendWishList()
        }
    }
    
    
    func loadFriendWishList() {
        //remove firebase database
        self.isLoading = true
        if let friendID = self.friendsArray[self.selectFriendIndex].id {
            let item = self.ref.child(String(friendID)).child("wishList").queryOrderedByKey()
            item.observeSingleEvent(of: .value) { (snapshot) in
                if let index = snapshot.value as? NSDictionary {
                    self.wishList = []
                    for (key, value) in index {
                        let value = value as! NSDictionary
                        let link = value["link"] as! String
                        let image = value["image"] as! String
                        let mallName = value["mallName"] as! String
                        let price = value["price"] as! String
                        let title = (value["title"] as! String).stringByDecodingHTMLEntities
                        let item = product.init(title: title, link: link, lprice: price, mallName: mallName, image: image)
                        self.wishList.append(item)
                        print(item)
                    }
                    self.wishlistCollectionView.reloadData()
                    self.wishlistCollectionView.refreshControl?.endRefreshing()
                    self.isLoading = false
                    self.emptyLabel.isHidden = true
                } else {
                    self.wishlistCollectionView.reloadData()
                    self.wishlistCollectionView.refreshControl?.endRefreshing()
                    self.emptyLabel.text = "위시리스트가 비어있습니다."
                    self.emptyLabel.isHidden = false
                    self.isLoading = false
                }
            }
        }
    }
    
    
    func loadFrendsList() {
        self.friendsArray = []
        TalkApi.shared.friends {(friends, error) in
            if let error = error {
                print(error)
                //카카오 로그인 없음
                DispatchQueue.main.async {
                    self.emptyLabel.text = "카카오 로그인이 필요합니다."
                    self.emptyLabel.isHidden = false
                    self.wishlistCollectionView.refreshControl = nil
                }
            }
            else {
                //do something
                if let friends = friends {
                    if let elements = friends.elements {
                        if elements.count != 0 {
                            for index in 0...elements.count - 1 {
                                let person = elements[index]
                                let friend = Person(favortite: person.favorite, id: person.id, nickname: person.profileNickname, imageUrl: person.profileThumbnailImage, uuid: person.uuid)
                                self.friendsArray.append(friend)
                                
                                DispatchQueue.main.async {
                                    self.friendsCollectionView.reloadData()
                                    self.loadFriendWishList()
                                }
                            }
                            self.emptyLabel.isHidden = true
                        } else {
                            //친구없음
                            DispatchQueue.main.async {
                                self.emptyLabel.text = "친구 목록이 비었습니다."
                                self.emptyLabel.isHidden = false
                                self.wishlistCollectionView.refreshControl?.endRefreshing()
                            }
                        }
                        
                    }
                }
            }
        }
    }
}

extension FriendsVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === self.wishlistCollectionView {
            return self.wishList.count
        }
        return self.friendsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //WISH CELL
        if collectionView === wishlistCollectionView {
            let wishCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendWishCell", for: indexPath) as! FriendWishCell
            let cellWidth = wishCell.layer.frame.width
            let item = wishList[self.wishList.count - indexPath.row - 1]
            
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
                            .cacheOriginalImage
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
                price.text = item.lprice
            }
            return wishCell
        }
        else {
            //FRIEND CELL
            let frindCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendCell", for: indexPath) as! FriendCell
            
            if indexPath.row == self.selectFriendIndex {
                frindCell.contentView.layer.opacity = 1.0
                frindCell.profileMaskView.layer.opacity = 1.0
            } else {
                frindCell.contentView.layer.opacity = 0.33
                frindCell.profileMaskView.layer.opacity = 0.0
            }
            
            
            if let label = frindCell.profileLabel {
                label.text = self.friendsArray[indexPath.row].nickname
            }
            if let image = frindCell.profileImage {
                if let imageUrl = self.friendsArray[indexPath.row].imageUrl {
                    let processor = DownsamplingImageProcessor(size: image.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: image.frame.width, height: image.frame.height), mode: .aspectFill)
                    image.kf.indicatorType = .activity
                    image.kf.setImage(
                        with: imageUrl,
                        options: [
                            .processor(processor),
                            .transition(.fade(0.1)),
                            .scaleFactor(UIScreen.main.scale),
                            .cacheOriginalImage
                        ]
                    )
                    
                }
            }
            return frindCell
        }
    }
    
    
}
extension FriendsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.wishlistCollectionView {
            gotoProductDatailVC(indexPath: indexPath.row)
        } else {
            self.selectFeedBack.prepare()
            self.selectFeedBack.selectionChanged()
            self.selectFriendIndex = indexPath.row
            self.friendsCollectionView.reloadData()
            self.wishlistCollectionView.setContentOffset(CGPoint.zero, animated: false)
            self.loadFriendWishList()
        }
    }
    
    func gotoProductDatailVC(indexPath: Int) {
        guard let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailVC else {
            return
        }
        let selectProduct = self.wishList[self.wishList.count - indexPath - 1]
        let title = selectProduct.title
        let url = selectProduct.link
        let price = selectProduct.lprice
        let image = selectProduct.image
        let mallName = selectProduct.mallName
        
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



extension FriendsVC {
    //call every time when scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.wishlistCollectionView {
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
