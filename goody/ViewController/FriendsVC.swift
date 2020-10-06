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
import Kingfisher

struct Person {
    var favortite: Bool!
    var id: Int64!
    var nickname: String!
    var imageUrl: URL!
    var uuid: String!
}

class FriendsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var header: UIView!
    //Header bar seperator
    let border = CALayer()
    
    var friendsArray: [Person] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor(named: "SeperatorColor")

        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.header.frame.size.height - 1, width: self.header.frame.size.width, height: 1)
        self.header.layer.addSublayer(border)
        
        loadFrendsList()
    }
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        }
    }
    
    
    func loadFrendsList() {
        TalkApi.shared.friends {(friends, error) in
            if let error = error {
                print(error)
            }
            else {
                //do something
                _ = friends
                print(friends)
                if let friends = friends {
                    if let elements = friends.elements {
                        for index in 0...elements.count - 1 {
                            let person = elements[index]
                            let friend = Person(favortite: person.favorite, id: person.id, nickname: person.profileNickname, imageUrl: person.profileThumbnailImage, uuid: person.uuid)
                            self.friendsArray.append(friend)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension FriendsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friendsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friendCell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! FriendCell
        
        if let nameLabel = friendCell.friendName {
            if let nameText = self.friendsArray[indexPath.row].nickname {
                nameLabel.text = nameText
            }
        }
        
        if let imageView = friendCell.friendImage {
            if let imageUrl = self.friendsArray[indexPath.row].imageUrl {
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                    |> ResizingImageProcessor(referenceSize: CGSize(width: imageView.frame.width, height: imageView.frame.height), mode: .aspectFill)
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(
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
        
        return friendCell
    }
    
    
}

extension FriendsVC: UITableViewDelegate {
    
}

extension FriendsVC {
    //call every time when scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
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
