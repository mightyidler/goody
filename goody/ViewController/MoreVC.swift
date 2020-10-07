//
//  MoreVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import KakaoSDKAuth
import KakaoSDKTalk
import KakaoSDKUser
import Kingfisher


class MoreVC: UIViewController, TabBarReselectHandling{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var header: UIView!
    
    var me: Person!
    var isLogined: Bool!
    var name: String!
    var thumbnailURL: URL!
    let accountActionState: [String] = ["로그인", "로그아웃"]
    var tableActions: [String] = ["설정","자주 묻는 질문","공지사항"]
    let tableActionImages: [String] = ["gearshape", "person.fill.questionmark", "megaphone", "lock"]
    let feedbackHaptic: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    //Header bar seperator
    let border = CALayer()
    
    func handleReselect() {
        self.tableView.setContentOffset(.zero, animated: true)
    }
    
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
        
        loadProfile()
    }
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        }
    }
    
    
    func loadProfile() {
        TalkApi.shared.profile {(profile, error) in
            if let error = error {
                print(error)
                self.isLogined = false
                self.tableActions.append(self.accountActionState[0])
            }
            else {
                print("profile() success.")
                print(profile)
                self.isLogined = true
                self.tableActions.append(self.accountActionState[1])
                self.me = Person(favortite: false, id: nil, nickname: profile?.nickname, imageUrl: profile?.thumbnailUrl, uuid: nil)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
}

extension MoreVC: UITableViewDelegate {
    //highlight table row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    
    //unhighlight table row
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if  indexPath.section == 1 {
            print(indexPath.row)
            switch indexPath.row {
            case 0:
                // index 0 to setting
                break
            case 1:
                // index 1 to questions
                break
            case 2:
                // index 2 to megaphone
                break
            case 3:
                // index 3 to log out
                if isLogined {
                    let alert = UIAlertController(title: "카카오 계정을 로그아웃 하시겠습니까?", message: nil, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive , handler:{ (UIAlertAction)in
                            self.kakaoLogOut()
                        }))

                        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler:{ (UIAlertAction)in
                        }))

                        self.present(alert, animated: true, completion: {
                        })
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                    self.present(loginVC, animated: true, completion: nil)
                }
                
                
                break
            default:
                return
            }
        }
    }
    
    func kakaoLogOut() {
        UserApi.shared.logout {(error) in
            if let error = error {
                print(error)
            }
            else {
                self.feedbackHaptic.prepare()
                self.feedbackHaptic.notificationOccurred(.success)
                UserDefaults.standard.removeObject(forKey: "FirstLaunch")
                UserDefaults.standard.synchronize()
                self.gotoTabBarVC()
            }
        }
    }
    
    func gotoTabBarVC() {
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
}

extension MoreVC: UITableViewDataSource {
    //set section header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 10
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 16))
        headerView.backgroundColor = UIColor(named: "SectionSeperatorColor")
        return headerView
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return self.tableActions.count
        default:
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            let actionCell = tableView.dequeueReusableCell(withIdentifier: "actionCell", for: indexPath) as! ActionCell
            if let label = actionCell.actionLabel {
                label.text = self.tableActions[indexPath.row]
            }
            if let imageView = actionCell.actionImage {
                let imageName = tableActionImages[indexPath.row]
                imageView.image = UIImage(systemName: imageName)
                imageView.tintColor = UIColor(named: "SecondLabelColor")
            }
            
            return actionCell
        }
        
        
        let profileCell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! ProfileCell
        if let me = self.me {
            if let name = me.nickname {
                profileCell.profileName.text = name
            }
            
            if let imageView = profileCell.profileImage {
                if let url = me.imageUrl {
                    let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: imageView.frame.width, height: imageView.frame.height), mode: .aspectFill)
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
        if isLogined == false {
            profileCell.profileName.text = "로그인이 필요합니다."
        }
        return profileCell
    }
    
}

extension MoreVC {
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
