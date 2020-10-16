//
//  SelectCategoriesVC.swift
//  goody
//
//  Created by mightyidler on 2020/10/13.
//

import UIKit
import Firebase
import FirebaseAuth

class SelectCategoriesVC: UIViewController {

    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var screenWidth: CGFloat!
    var db: Firestore!
    var uid: NSString!
    
    var categories: [String] = ["패션의류" ,"패션잡화" ,"화장품미용" ,"디지털가전" ,"가구인테리어" ,"출산육아" ,"식품" ,"스포츠레저" ,"생활건강" ,"여가생활편의"]
    var cetegoriedPrimary: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        checkIfUserIsSignedIn()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        screenWidth = UIScreen.main.bounds.size.width
        completeButton.layer.cornerRadius = 19
        collectionView.allowsMultipleSelection = true
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
    
    func firebaseAppend() {
        var dict: [String: Any] = [:]
        for index in 0...9 {
            dict.updateValue(cetegoriedPrimary[index], forKey: categories[index])
        }
        
        //append
        if let id = uid {
            
            db.collection("users").document("\(id)").updateData(dict)    { err in
                if let err = err {
                    DispatchQueue.main.async {
                        self.completeButton.isEnabled = true
                        self.indicator.stopAnimating()
                    }
                    let errorMsg = err.localizedDescription
                    let alert = UIAlertController(title: "카테고리 업로드 실패", message: errorMsg, preferredStyle: UIAlertController.Style.alert)
                    self.present(alert, animated: true, completion: nil)
                    let when = DispatchTime.now() + 1
                    DispatchQueue.main.asyncAfter(deadline: when){
                      // your code with delay
                      alert.dismiss(animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.completeButton.isEnabled = true
                        self.indicator.stopAnimating()
                    }
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
        }
        
    }
    
    @IBAction func completeButtonAction(_ sender: UIButton) {
        let items = self.collectionView.indexPathsForSelectedItems
        print(items)
        if let items = items {
            for item in items {
                print(item[1])
                cetegoriedPrimary[item[1]] = 10
            }
        }
        DispatchQueue.main.async {
            self.completeButton.isEnabled = false
            self.indicator.startAnimating()
        }
        firebaseAppend()
        
    }
}

extension SelectCategoriesVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as? CategoryCell else {
            return UICollectionViewCell()
        }
        if let label = cell.categoryLabel {
            label.text = categories[indexPath.row]
        }
        if let imageView = cell.categoryImageView {
            imageView.image = UIImage(named: "c\(indexPath.row)")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.indexPathsForSelectedItems?.count ?? 0 > 0 {
            print("possible")
            self.completeButton.isEnabled = true
            self.completeButton.backgroundColor = UIColor.systemRed
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
            print("select")
            UIView.animate(withDuration: 0.1) {
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                cell.visualEffectView.layer.opacity = 1.0
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if !(collectionView.indexPathsForSelectedItems?.count ?? 0 > 0) {
            print("impossible")
            self.completeButton.backgroundColor = UIColor.tertiaryLabel
            self.completeButton.isEnabled = false
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
            print("deselect")
            UIView.animate(withDuration: 0.1) {
                cell.transform = .identity
                cell.visualEffectView.layer.opacity = 0.0
            }
        }
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

extension SelectCategoriesVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let devide: CGFloat = 2
        let minus: CGFloat = 28
        let cellSize: CGFloat = screenWidth / devide - minus
        let contentsHeight: CGFloat = 100
        return CGSize(width: cellSize, height: contentsHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
    
    
}
