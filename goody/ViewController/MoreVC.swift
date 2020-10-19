//
//  MoreVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/02.
//

import UIKit
import CoreData
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseStorage

class MoreVC: UIViewController, TabBarReselectHandling, UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var header: UIView!
    
    var me: Person!
    var isLogined: Bool!
    var name: String!
    var thumbnailURL: URL!
    let storage = Storage.storage()
    var uid: String!
    var profileImage: URL!
    
    var db: Firestore!
    let accountActionState: [String] = ["로그인", "로그아웃"]
    //    var tableActions: [String] = ["설정","자주 묻는 질문","공지사항"]
    var tableActions: [String] = []
    let tableActionImages: [String] = ["lock"]
    let feedbackHaptic: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var handle: AuthStateDidChangeListenerHandle?
    //Header bar seperator
    let border = CALayer()
    
    func handleReselect() {
        self.tableView.setContentOffset(.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        checkFirebaseLogin()
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor(named: "SeperatorColor")
        
        //search bar seperator
        if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.header.frame.size.height - 1, width: self.header.frame.size.width, height: 1)
        self.header.layer.addSublayer(border)
        
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.alpha = 0.6
        self.tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl?.beginRefreshing()
        
        //loadProfile()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let borderColor = UIColor(named: "SeperatorColor") { self.border.backgroundColor = borderColor.cgColor }
        }
    }
    
    @objc func pullToRefresh(_ sender: Any) {
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    func checkFirebaseLogin() {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // user is signed in
                if let id = user?.uid {
                    self.uid = id
                    self.loadImageUrl()
                    let doc = self.db.collection("users").document("\(id)")
                    doc.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                            print("Document data: \(dataDescription)")
                            if let nickname = document["nickname"] as? String {
                                self.me = Person(favortite: false, id: nil, nickname: nickname, imageUrl: nil, uuid: nil)
                                self.isLogined = true
                                self.tableActions.append(self.accountActionState[1])
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.tableView.refreshControl?.endRefreshing()
                                }
                            }
                            
                        } else {
                            let alert = UIAlertController(title: "로그인 정보를 불러오는데 실패했습니다.", message: nil, preferredStyle: UIAlertController.Style.alert)
                            self.present(alert, animated: true, completion: nil)
                            let when = DispatchTime.now() + 1
                            DispatchQueue.main.asyncAfter(deadline: when){
                                // your code with delay
                                alert.dismiss(animated: true, completion: nil)
                                self.firebaseSignOut()
                            }
                            
                        }
                    }
                }
            } else {
                // user is not signed in
                self.isLogined = false
                self.tableActions.append(self.accountActionState[0])
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
}

extension MoreVC: UITableViewDelegate {
    //highlight table row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
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
//            case 0:
//                // index 0 to setting
//                break
//            case 0:
                // index 1 to questions
//                setProfileImage()
//                break
            case 0:
                // index 3 to log out
                
                if isLogined {
                    let alert = UIAlertController(title: "카카오 계정을 로그아웃 하시겠습니까?", message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive , handler:{ (UIAlertAction)in
                        self.firebaseSignOut()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler:{ (UIAlertAction)in
                    }))
                    
                    self.present(alert, animated: true, completion: {
                    })
                } else {
                    gotoLoginVC()
                }
                
                
                break
            default:
                return
            }
        }
    }
    
    
    func firebaseSignOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.feedbackHaptic.prepare()
            self.feedbackHaptic.notificationOccurred(.success)
            gotoLoginVC()
            
        } catch let signOutError as NSError {
            let alert = UIAlertController(title: "로그아웃 실패", message: signOutError as? String, preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            let when = DispatchTime.now() + 3
            DispatchQueue.main.asyncAfter(deadline: when){
                // your code with delay
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func gotoLoginVC() {
        self.removeAll()
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            self.present(loginVC, animated:true, completion:nil)
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
            
            
            if let button = profileCell.ImageChangeButton {
                button.addTarget(self, action: #selector(changeProfileImage(_:)), for: .touchUpInside)
            }
            
            if let imageView = profileCell.profileImage {
                if let url = profileImage {
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
                    
                }
            }
        }
        
        if isLogined == false {
            profileCell.profileName.text = "로그인이 필요합니다."
        }
        return profileCell
    }
    
    func setProfileImage() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    @objc func changeProfileImage(_ sender: UIButton) {
        setProfileImage()
    }
    
    func loadImageUrl() {
        if let id = self.uid {
            let starsRef = storage.reference().child("profileImage/\(id).jpg")
            starsRef.downloadURL { url, error in
                if let error = error {
                    // Handle any errors
                } else {
                    // Get the download URL for 'images/stars.jpg'
                    self.profileImage = url
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let id = self.uid {
            guard let im: UIImage = info[.editedImage] as? UIImage else { return }
            guard let d: Data = im.jpegData(compressionQuality: 0.5) else { return }
            
            let md = StorageMetadata()
            md.contentType = "image/png"
            
            let ref = Storage.storage().reference().child("profileImage/\(id).jpg")
            
            ref.putData(d, metadata: md) { (metadata, error) in
                if error == nil {
                    ref.downloadURL(completion: { (url, error) in
                        print("Done, url is \(String(describing: url))")
                    })
                }else{
                    print("error \(String(describing: error))")
                }
            }
            dismiss(animated: true, completion: {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3), execute: {
                    print("reload")
                    self.tableView.reloadData()
                })
            })
        }
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

extension MoreVC {
    func removeAll() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
